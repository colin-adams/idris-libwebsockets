||| Http protocol for pre-v2.0 (no plugins)
module Http_only

import WS.Http
import WS.Handler
import WS.Logging

import CFFI

%include C "test_server.h"
%link C "test_server.o"

string_from_c : Ptr -> IO String
string_from_c str = foreign FFI_C "make_string" (Ptr -> IO String) str

string_to_c : String -> IO Ptr
string_to_c str = foreign FFI_C "string_to_c" (String -> IO Ptr) str

transmission_buffer : Int -> IO Ptr
transmission_buffer size = foreign FFI_C "transmission_buffer" (Int -> IO Ptr) size

transmission_buffer_start : Ptr -> IO Ptr
transmission_buffer_start buffer = foreign FFI_C "transmission_buffer_start" (Ptr -> IO Ptr) buffer

export
http_protocol_name : String
http_protocol_name = "http_only"

export
http_data_size : Bits64
http_data_size = 265

export
http_rx_buffer_size : Bits64
http_rx_buffer_size = 0

per_session_data_structure : Composite
per_session_data_structure = STRUCT [PTR, ARRAY 256 I8, I8]

try_to_reuse : (wsi : Ptr) ->  IO Int
try_to_reuse wsi = do
  completed <- lws_transaction_completed wsi
  if completed then
    pure FAIL
  else
    pure OK
    
log_addresses : (wsi : Ptr) -> IO ()
log_addresses wsi = do
  fd <- lws_get_socket_fd wsi
  name <- alloc name_buffer
  rip <- alloc rip_buffer
  lws_get_peer_addresses wsi fd name 100 rip 50
  lwsl_notice $ "HTTP connect from " ++ !(string_from_c name) ++ "(" ++ 
    !(string_from_c rip) ++ ")"++ "\n"
  free name
  free rip
 where
   name_buffer : Composite
   name_buffer = ARRAY 101 I8
   rip_buffer : Composite
   rip_buffer = ARRAY 51 I8
   
process_proxy_test : (wsi : Ptr) -> (user : Ptr) -> (path : String) -> IO Int
process_proxy_test wsi user path = do
  child <- lws_get_child wsi
  if null == child then
    set_client_finished user False
  else pure OK

process_http : (wsi : Ptr) -> (user : Ptr) -> (inp : Ptr) -> (len : Bits64) -> IO Int
process_http wsi user inp len = do
  path <- string_from_c inp
  lwsl_notice $ "lws_http_serve: " ++ path ++ "\n"
  log_addresses wsi
  if len < 1 then do
    _ <- lws_return_http_status wsi HTTP_STATUS_BAD_REQUEST ""
    try_to_reuse wsi
  else do
    if isPrefixOf "/proxytest" path then
      process_proxy_test wsi user path
    else do
      pure OK
  
http_handler : Callback_handler
http_handler wsi reason user inp len = unsafePerformIO $ do
  if reason == LWS_CALLBACK_HTTP then
    process_http wsi user inp len
  else
    pure OK  
  
export
http_wrapper : IO Ptr
http_wrapper = foreign FFI_C "%wrapper" (CFnPtr (Callback_handler) -> IO Ptr) (MkCFnPtr http_handler)
