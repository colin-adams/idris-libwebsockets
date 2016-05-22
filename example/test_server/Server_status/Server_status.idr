||| Implementation of the lws_status protocol
module Server_status

import WS.Wsi
import WS.Handler
import WS.Logging
import WS.Plugin
import WS.Protocol
import WS.Library
import WS.Context
import WS.Http
import WS.Write

import Data.Fin
import CFFI

%include C "lws_status.h"
%include C "../test_server.h"
%flag C "-fpic"

string_to_c : String -> IO Ptr
string_to_c str = foreign FFI_C "string_to_c" (String -> IO Ptr) str

transmission_buffer_start : Ptr -> IO Ptr
transmission_buffer_start buffer = foreign FFI_C "transmission_buffer_start" (Ptr -> IO Ptr) buffer

set_server_info : String -> String -> IO ()
set_server_info ver nm =
  foreign FFI_C "set_server_info" (Ptr -> Ptr -> IO ()) !(string_to_c ver) !(string_to_c nm)

set_last : Ptr -> Int -> IO ()
set_last pss val =
  foreign FFI_C "set_last" (Ptr -> Int -> IO ()) pss val
  
list : IO Ptr
list = foreign FFI_C "get_list" (IO Ptr)

cache : IO Ptr
cache = foreign FFI_C "get_cache" (IO Ptr)

cache_length : IO Bits64
cache_length = foreign FFI_C "cache_length" (IO Bits64)

server_info_length : IO Int
server_info_length = foreign FFI_C "server_info_length" (IO Int)

set_list : Ptr -> IO ()
set_list pss  =
  foreign FFI_C "set_list" (Ptr -> IO ()) pss

set_user_agent : Ptr -> String -> IO ()
set_user_agent pss user_agent = do
  str <- string_to_c user_agent
  foreign FFI_C "set_user_agent" (Ptr -> Ptr -> IO ()) pss str

user_agent : Ptr -> IO Ptr
user_agent pss =
  foreign FFI_C "user_agent" (Ptr -> IO Ptr) pss
  
increment_live_wsi : IO ()
increment_live_wsi = foreign FFI_C "increment_live_wsi" (IO ())

set_ip : (user : Ptr) -> (name : Ptr) -> (rip : Ptr) -> IO ()
set_ip user name rip =
  foreign FFI_C "set_ip" (Ptr -> Ptr -> Ptr -> IO ()) user name rip

protocol_name : String
protocol_name = "lws-status"

data_size : Bits64
data_size = 832

rx_buffer_size : Bits64
rx_buffer_size = 128

init_protocol : (wsi : Wsi) -> IO Int
init_protocol wsi = do
  ver <- lws_get_library_version
  ctx <- lws_get_context wsi
  nm  <- lws_canonical_hostname ctx
  set_server_info ver nm
  pure OK

update_status : (wsi : Wsi) -> (pss : Ptr) -> IO ()
update_status wsi pss = 
  foreign FFI_C "update_status" (Ptr -> Ptr -> IO ()) (unwrap_wsi wsi) pss

establish_session : Wsi -> Ptr -> IO Int
establish_session wsi user = do
  set_last user 0
  set_list user
  increment_live_wsi
  fd <- lws_get_socket_fd wsi
  name <- alloc (ARRAY 128 I8)
  rip <- alloc (ARRAY 128 I8)
  lws_get_peer_addresses wsi fd name 128 rip 128
  set_ip user name rip
  free name
  free rip
  set_user_agent user "unknown"
  dest <- user_agent user
  _ <- lws_hdr_copy wsi dest 512 WSI_TOKEN_HTTP_USER_AGENT
  update_status wsi user
  pure OK
  
write_response : (wsi : Wsi) -> (pss : Ptr) -> IO Int
write_response wsi pss = do
  c <- cache
  buf <- transmission_buffer_start c
  m <- lws_write wsi buf !cache_length LWS_WRITE_TEXT
  len <- server_info_length
  if m < len then do
    lwsl_err $ "ERROR: only " ++ (show m) ++ " bytes were written to di socket\n"
    pure FAIL
  else pure OK

decrement_live_wsi : (pss : Ptr) -> IO ()
decrement_live_wsi pss =
  foreign FFI_C "decrement_live_wsi" (Ptr -> IO ()) pss
  
lws_status_handler : Callback_handler
lws_status_handler wsip reason user inp len = unsafePerformIO $ do
  let wsi = (wrap_wsi wsip)
  if reason == LWS_CALLBACK_PROTOCOL_INIT then do
    init_protocol wsi
  else do
    if reason == LWS_CALLBACK_ESTABLISHED then
      establish_session wsi user
    else do
      if reason == LWS_CALLBACK_SERVER_WRITEABLE then
        write_response wsi user
      else do
        if reason ==  LWS_CALLBACK_CLOSED then do
          decrement_live_wsi user
          update_status wsi user
          pure OK
        else pure OK
          
lws_status_wrapper : IO Ptr
lws_status_wrapper = foreign FFI_C "%wrapper" (CFnPtr (Callback_handler) -> IO Ptr) (MkCFnPtr lws_status_handler)

init_lws_status_protocol: (context : Ptr) -> (capabilities : Ptr) -> Int
init_lws_status_protocol context caps = unsafePerformIO $ do
  magic <- api_magic caps
  if magic /= LWS_PLUGIN_API_MAGIC then do
    lwsl_err $ "Plugin API " ++ show (LWS_PLUGIN_API_MAGIC) ++ ", library API " ++ (show magic)
    return 1
  else do
    array <- allocate_protocols_array 1
    add_protocol_handler array 1 0 protocol_name lws_status_wrapper data_size 
      rx_buffer_size 0 null
    set_capabilities_protocols caps array 1
    set_capabilities_extensions caps null 0
    return OK
   
destroy_protocol_lws_status : (context : Ptr) -> Int
destroy_protocol_lws_status context = OK

exports: FFI_Export FFI_C "exports.h" []
exports = Fun init_lws_status_protocol "init_protocol_lws_status_exported" $ Fun destroy_protocol_lws_status "destroy_protocol_lws_status_exported" $ End
