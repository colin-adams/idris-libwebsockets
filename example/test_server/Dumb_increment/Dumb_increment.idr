||| Implementation of the dumb increment protocol
module Dumb_increment

import WS.Wsi
import WS.Handler
import WS.Logging
import WS.Write
import WS.Plugin
import WS.Protocol
import WS.Vhost
import WS.Uv
import WS.Context
import WS.Plugin

import Data.Fin
import CFFI

%include C "../test_server.h"
%flag C "-fpic"

string_from_c : Ptr -> IO String
string_from_c str = foreign FFI_C "make_string" (Ptr -> IO String) str

string_to_c : String -> IO Ptr
string_to_c str = foreign FFI_C "string_to_c" (String -> IO Ptr) str

protocol_name : String
protocol_name = "dumb-increment-protocol"

data_size : Bits64
data_size = 4

rx_buffer_size : Bits64
rx_buffer_size = 10

uv_timer_t_size : IO Bits64
uv_timer_t_size = foreign FFI_C "uv_timer_t_size" (IO Bits64)

uv_timer_t : Int -> Composite
uv_timer_t sz = ARRAY sz I8

per_vhost_data__dumb_increment : Composite
per_vhost_data__dumb_increment = STRUCT [uv_timer_t 152, PTR, PTR, PTR] -- TODO use a type provider rather than hard-code 152? https://github.com/idris-lang/Idris-dev/wiki/Tutorial:-Type-Providers-and-Foreign-Functions

timeout_watcher_field : Ptr -> CPtr
timeout_watcher_field p = (per_vhost_data__dumb_increment#0) p

context_field : Ptr -> CPtr
context_field p = (per_vhost_data__dumb_increment#1) p

vhost_field : Ptr -> CPtr
vhost_field p = (per_vhost_data__dumb_increment#2) p

protocols_field : Ptr -> CPtr
protocols_field p = (per_vhost_data__dumb_increment#3) p

per_session_data_structure : Composite
per_session_data_structure = STRUCT [I32]

transmission_buffer : Int -> IO Ptr
transmission_buffer size = foreign FFI_C "transmission_buffer" (Int -> IO Ptr) size

transmission_buffer_start : Ptr -> IO Ptr
transmission_buffer_start buffer = foreign FFI_C "transmission_buffer_start" (Ptr -> IO Ptr) buffer

fill_buffer : Ptr -> Ptr -> IO ()
fill_buffer buffer str = foreign FFI_C "fill_buffer" (Ptr -> Ptr -> IO ()) buffer str

is_close_testing : IO Int
is_close_testing = foreign FFI_C "is_close_testing" (IO Int)

open_testing : IO ()
open_testing = foreign FFI_C "open_testing" (IO ())

write_response : (wsi : Wsi) -> (user : Ptr) -> IO Int
write_response wsi user = do
  current_count <- peek I32 ((per_session_data_structure#0) user)
  poke I32 ((per_session_data_structure#0) user) (current_count + 1)
  buffer <- transmission_buffer 512
  let new_count = prim__truncB32_Int $ current_count + 1
  let buffer_text = show new_count
  let len = fromInteger $ toIntegerNat $ length buffer_text
  write_position <- transmission_buffer_start buffer
  fill_buffer write_position !(string_to_c buffer_text)
  m <- lws_write wsi write_position len LWS_WRITE_TEXT
  free buffer
  if m < (prim__truncB64_Int len) then do
    lwsl_err $ "ERROR " ++ (show len) ++ " writing to di socket`n" 
    pure FAIL
  else do
    problem <- is_close_testing
    if problem == 1 && current_count == 49 then do
      lwsl_info "close testing limit, closing\n"
      pure FAIL
    else do
      pure OK

receive_request : (wsi : Wsi) -> (user : Ptr) -> (inp : Ptr) -> (len : Bits64) -> IO Int
receive_request wsi user inp len = do
  if len < 6 then
    pure OK
  else do
    in_str <- string_from_c inp
    if in_str == "reset\n" then do
      poke I32 ((per_session_data_structure#0) user) 0
      pure OK
    else
      pure OK
    if in_str == "closeme\n" then do
      lwsl_notice "dumb_inc: closing as requested\n"
      str <- string_to_c "seeya"
      lws_close_reason wsi LWS_CLOSE_STATUS_GOINGAWAY str 5
      pure FAIL
    else pure OK

per_vhost_data__dumb_increment_from_timeout_watcher : Ptr -> IO Ptr
per_vhost_data__dumb_increment_from_timeout_watcher tw =
  foreign FFI_C "per_vhost_data__dumb_increment_from_timeout_watcher" (Ptr -> IO Ptr) tw
  
uv_timeout_cb_dumb_increment : (timeout_watcher : Ptr) -> ()
uv_timeout_cb_dumb_increment tw = unsafePerformIO $ do
  vhd <- per_vhost_data__dumb_increment_from_timeout_watcher tw
  vhost <- peek PTR (vhost_field vhd)
  prots <- peek PTR (protocols_field vhd)
  __ <- lws_callback_on_writable_all_protocol_vhost vhost prots
  pure ()
  
uv_timeout_cb_wrapper : IO Ptr
uv_timeout_cb_wrapper = foreign FFI_C "%wrapper" (CFnPtr (Ptr -> ()) -> IO Ptr)
  (MkCFnPtr (uv_timeout_cb_dumb_increment))

init_protocol : (wsi : Wsi) -> IO Int
init_protocol wsi = do
  vh   <- lws_get_vhost wsi
  prot <- lws_get_protocol wsi
  vhd  <- lws_protocol_vh_priv_zalloc vh prot 176 -- = hand calculation of STRUCT - 152 + 3 x 64-bit pointers
  ctx  <- lws_get_context wsi
  sz   <- uv_timer_t_size
  let size = prim__truncB64_Int sz
  poke PTR (context_field vhd) (unwrap_context ctx)
  poke PTR (protocols_field vhd) (unwrap_protocols_array prot)
  poke PTR (vhost_field vhd) (unwrap_vhost vh)
  loop <- lws_uv_getloop ctx 0
  uv_timer_init loop vhd
  uv_timer_start vhd !(uv_timeout_cb_wrapper) 50 50
  pure OK
  
destroy_protocol : (wsi : Wsi) -> IO Int
destroy_protocol wsi = do
  vh   <- lws_get_vhost wsi
  prot <- lws_get_protocol wsi
  vhd  <- lws_protocol_vh_priv_get vh prot
  if vhd == null then do
    pure OK
  else do
    uv_timer_stop vhd
    pure OK

dumb_increment_handler : Callback_handler
dumb_increment_handler wsip reason user inp len = unsafePerformIO $ do
  let wsi = wrap_wsi wsip
  if reason == LWS_CALLBACK_PROTOCOL_INIT then do
    init_protocol wsi
  else do
    if reason == LWS_CALLBACK_PROTOCOL_DESTROY then do
      destroy_protocol wsi
    else do
      if reason == LWS_CALLBACK_ESTABLISHED then do
        poke I32 ((per_session_data_structure#0) user) 0
        open_testing
        pure OK
      else do
        if reason == LWS_CALLBACK_SERVER_WRITEABLE then
          write_response wsi user
        else do
          if reason ==  LWS_CALLBACK_RECEIVE then
            receive_request wsi user inp len
          else pure OK
  
dumb_increment_wrapper : IO Ptr
dumb_increment_wrapper = foreign FFI_C "%wrapper" (CFnPtr (Callback_handler) -> IO Ptr) (MkCFnPtr dumb_increment_handler)

init_dumb_increment_protocol: (context : Ptr) -> (capabilities : Ptr) -> Int
init_dumb_increment_protocol context caps = unsafePerformIO $ do
  magic <- api_magic caps
  if magic /= LWS_PLUGIN_API_MAGIC then do
    lwsl_err $ "Plugin API " ++ show (LWS_PLUGIN_API_MAGIC) ++ ", library API " ++ (show magic)
    return 1
  else do
    array <- allocate_protocols_array 1
    add_protocol_handler array 1 0 protocol_name dumb_increment_wrapper data_size 
      rx_buffer_size 0 null
    set_capabilities_protocols caps array 1
    set_capabilities_extensions caps null 0
    return OK

destroy_protocol_dumb_increment : (context : Ptr) -> Int
destroy_protocol_dumb_increment context = OK

exports: FFI_Export FFI_C "exports.h" []
exports = Fun init_dumb_increment_protocol "init_protocol_dumb_increment_exported" $ Fun destroy_protocol_dumb_increment "destroy_protocol_dumb_increment_exported" $ End

