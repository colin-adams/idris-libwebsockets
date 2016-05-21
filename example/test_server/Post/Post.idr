||| Implementation of libwebsockets post-demo plugin
module Post

import WS.Handler
import WS.Logging
import WS.Plugin
import WS.Protocol
import WS.Vhost
import WS.Write
import WS.Context
import WS.Http

import Data.Fin
import CFFI

%include C "../test_server.h"
%flag C "-fpic"  

string_to_c : String -> IO Ptr
string_to_c str = foreign FFI_C "string_to_c" (String -> IO Ptr) str

string_from_c : Ptr -> IO String
string_from_c str = foreign FFI_C "make_string" (Ptr -> IO String) str

strncpy : (dest : Ptr) -> (src : Ptr) -> (len : Bits64) -> IO Ptr
strncpy dest src len = foreign FFI_C "strncpy" (Ptr -> Ptr -> Bits64 -> IO Ptr) dest src len

strcpy : (dest : Ptr) -> (src : Ptr) -> IO Ptr
strcpy dest src = foreign FFI_C "strcpy" (Ptr -> Ptr -> IO Ptr) dest src

transmission_buffer_start : Ptr -> IO Ptr
transmission_buffer_start buffer = foreign FFI_C "transmission_buffer_start" (Ptr -> IO Ptr) buffer

bytes_on_from : Bits64 -> Ptr -> Ptr
bytes_on_from count start = unsafePerformIO $ do
  foreign FFI_C "bytes_on_from" (Bits64 -> Ptr -> IO Ptr) count start

pointer_difference : Ptr -> Ptr -> Bits64
pointer_difference p1 p2 = unsafePerformIO $ do
  foreign FFI_C "pointer_difference" (Ptr -> Ptr -> IO Bits64) p1 p2
  
LWS_PRE : Bits64
LWS_PRE = unsafePerformIO $ foreign FFI_C "LWS_PREfix" (IO Bits64)

protocol_name : String
protocol_name = "protocol-post-demo"

data_size : Bits64
data_size = 256 + 500 + LWS_PRE + 4

rx_buffer_size : Bits64
rx_buffer_size = 1024

post_string : Composite
post_string = ARRAY 256 I8

result_string : Composite
result_string = ARRAY (500 + (prim__truncB64_Int LWS_PRE)) I8

per_session_data__post_demo : Composite
per_session_data__post_demo = STRUCT [post_string, result_string, I32]

post_field : Ptr -> CPtr
post_field user = (per_session_data__post_demo#0) user

last_post_byte : Ptr -> CPtr
last_post_byte user = (post_string#255) user

result_field : Ptr -> CPtr
result_field user = (per_session_data__post_demo#1) user

len_field : Ptr -> CPtr
len_field user = (per_session_data__post_demo#2) user
 
try_to_reuse : (wsi : Ptr) -> IO Int
try_to_reuse wsi = do
  comp <- lws_http_transaction_completed wsi
  if comp /= 0 then
    pure FAIL
  else pure OK
  
post_demo_handler : Callback_handler
post_demo_handler wsi reason user inp len = unsafePerformIO $ do
  if reason == LWS_CALLBACK_HTTP_BODY then do
    lwsl_debug $ "LWS_CALLBACK_HTTP_BODY: len " ++ (show len) ++ "\n"
    _ <- strncpy (post_field user) inp 255
    poke I8 (last_post_byte user) 0 -- terminating NULL
    if len < 255 then do
      poke I8 ((post_string#(cast $ prim__truncB64_Int len)) user) 0 -- true terminating null
      pure OK
    else pure OK
  else do
    if reason == LWS_CALLBACK_HTTP_WRITEABLE then do
      l <- peek I32 (len_field user)
      s <- (transmission_buffer_start (result_field user))
      lwsl_debug $ "LWS_CALLBACK_HTTP_WRITEABLE: sending " ++ (show l) ++ "\n"
      n <- lws_write wsi !(transmission_buffer_start (result_field user)) (prim__zextB32_B64 l) LWS_WRITE_HTTP
      if n < 1 then
        pure 1
      else try_to_reuse wsi
    else do
      if reason == LWS_CALLBACK_HTTP_BODY_COMPLETION then do
        lwsl_debug "LWS_CALLBACK_HTTP_BODY_COMPLETION\n"
        {-
          * the whole of the sent body arrived,
          * respond to the client with a redirect to show the
          * results
        -}
        str <- string_from_c user
        let res_str = "<html><body><h1>Form results</h1>'" ++ str ++ "'<br>" ++ "</body></html>"
        res <- string_to_c res_str
        _ <- strcpy !(transmission_buffer_start (result_field user)) res
        poke I32 (len_field user) (prim__truncInt_B32 $ toIntNat $ length res_str)
        buffer <- alloc (ARRAY ((prim__truncB64_Int LWS_PRE) + 512) I8)
        p <- alloc PTR
        poke PTR p !(transmission_buffer_start buffer)
        start <- peek PTR p
        let end = bytes_on_from 512 start
        h <- lws_add_http_header_status wsi HTTP_STATUS_OK p end
        if h /= 0 then do
          free buffer
          free p
          pure 1
        else
          pure OK
        ty <- string_to_c "text/html"
        h <- lws_add_http_header_by_token wsi WSI_TOKEN_HTTP_CONTENT_TYPE ty 9 p end
        if h /= 0 then
          pure 1
        else
          pure OK      
        l <- peek I32 (len_field user)
        h <- lws_add_http_header_content_length wsi (prim__zextB32_B64 l) p end
        if h /= 0 then do
          free buffer
          free p
          pure 1
        else do
          h <- lws_finalize_http_header wsi p end
          if h /= 0 then do
            free buffer
            free p
            pure 1
          else do
            pc <- peek PTR p
            let diff = pointer_difference pc start
            n <- lws_write wsi start diff LWS_WRITE_HTTP_HEADERS
            if n < 0 then do
              free buffer
              free p          
              pure 1
            else do
              free buffer
              free p
              lws_callback_on_writable wsi
              pure OK
      else pure OK
  
post_demo_wrapper : IO Ptr
post_demo_wrapper = foreign FFI_C "%wrapper" (CFnPtr (Callback_handler) -> IO Ptr) (MkCFnPtr post_demo_handler)

init_post_demo_protocol: (context : Ptr) -> (capabilities : Ptr) -> Int
init_post_demo_protocol context caps = unsafePerformIO $ do
  magic <- api_magic caps
  if magic /= LWS_PLUGIN_API_MAGIC then do
    lwsl_err $ "Plugin API " ++ show (LWS_PLUGIN_API_MAGIC) ++ ", library API " ++ (show magic)
    return 1
  else do
    array <- allocate_protocols_array 1
    add_protocol_handler array 1 0 protocol_name post_demo_wrapper data_size 
      rx_buffer_size 0 null
    set_capabilities_protocols caps array 1
    set_capabilities_extensions caps null 0
    return OK
    
destroy_protocol_post_demo : (context : Ptr) -> Int
destroy_protocol_post_demo context = OK

exports: FFI_Export FFI_C "exports.h" []
exports = Fun init_post_demo_protocol "init_protocol_post_demo_exported" $ Fun destroy_protocol_post_demo "destroy_protocol_post_demo_exported" $ End
