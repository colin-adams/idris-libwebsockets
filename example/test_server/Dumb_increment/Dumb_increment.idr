||| Implementation of the dumb increment protocol
module Dumb_increment

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

print_pointer : String -> Ptr -> IO ()
print_pointer name pointer =
  foreign FFI_C "print_pointer" (String -> Ptr -> IO ()) name pointer
  
export
dumb_increment_protocol_name : String
dumb_increment_protocol_name = "dumb-increment-protocol"

export
dumb_increment_data_size : Bits64
dumb_increment_data_size = 4

export
dumb_increment_rx_buffer_size : Bits64
dumb_increment_rx_buffer_size = 10

uv_timer_t_size : IO Bits64
uv_timer_t_size = foreign FFI_C "uv_timer_t_size" (IO Bits64)

uv_timer_t : Int -> Composite
uv_timer_t sz = ARRAY sz I8

per_vhost_data__dumb_increment : Composite
per_vhost_data__dumb_increment = STRUCT [uv_timer_t 152, PTR, PTR, PTR]

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

is_close_testing : IO Int
is_close_testing = foreign FFI_C "is_close_testing" (IO Int)

open_testing : IO ()
open_testing = foreign FFI_C "open_testing" (IO ())

write_response : (wsi : Ptr) -> (user : Ptr) -> IO Int
write_response wsi user = do
  putStrLn "Write response entered ..."
  current_count <- peek I32 ((per_session_data_structure#0) user)
  poke I32 ((per_session_data_structure#0) user) (current_count + 1)
  buffer <- transmission_buffer 512
  let new_count = prim__truncB32_Int $ current_count + 1
  let buffer_text = show new_count
  let len = fromInteger $ toIntegerNat $ length buffer_text
  putStrLn $ "WWWWWWWWWWWWWWWWWWWWWWWWWWriting response: " ++ buffer_text
  write_position <- transmission_buffer_start buffer
  m <- lws_write wsi write_position len LWS_WRITE_TEXT
  putStrLn $ "Wrote: " ++ (show m) ++ " bytes"
  free buffer
  if m < (prim__truncB64_Int len) then do
    lwsl_err $ "ERROR " ++ (show len) ++ " writing to di socket`n" 
    putStrLn $ "ERROR " ++ (show len) ++ " writing to di socket`n" 
    pure FAIL
  else do
    problem <- is_close_testing
    if problem == 1 && current_count == 49 then do
      putStrLn  "close testing limit, closing\n"
      lwsl_info "close testing limit, closing\n"
      pure FAIL
    else do
      putStrLn "Successfull write"
      pure OK

receive_request : (wsi : Ptr) -> (user : Ptr) -> (inp : Ptr) -> (len : Bits64) -> IO Int
receive_request wsi user inp len = do
  putStrLn "Receive request entered ..."
  if len < 6 then
    pure OK
  else do
    in_str <- string_from_c inp
    if in_str == "reset\n" then do
      putStrLn "Reseting as requested"
      poke I32 ((per_session_data_structure#0) user) 0
      pure OK
    else
      pure OK
    if in_str == "closeme\n" then do
      putStrLn "Closing as requested"
      lwsl_notice "dumb_inc: closing as requested\n"
      str <- string_to_c "seeya"
      lws_close_reason wsi LWS_CLOSE_STATUS_GOINGAWAY str 5
      pure FAIL
    else pure OK

lws_get_context : (wsi : Ptr) -> IO Ptr
lws_get_context wsi = foreign FFI_C "lws_get_context" (Ptr -> IO Ptr) wsi

lws_callback_on_writable_all_protocol_vhost : Ptr -> Ptr -> IO Int
lws_callback_on_writable_all_protocol_vhost vhost protocols =
  foreign FFI_C "lws_callback_on_writable_all_protocol_vhost" (Ptr -> Ptr -> IO Int) vhost protocols

per_vhost_data__dumb_increment_from_timeout_watcher : Ptr -> IO Ptr
per_vhost_data__dumb_increment_from_timeout_watcher tw =
  foreign FFI_C "per_vhost_data__dumb_increment_from_timeout_watcher" (Ptr -> IO Ptr) tw
  
uv_timeout_cb_dumb_increment : (timeout_watcher : Ptr) -> ()
uv_timeout_cb_dumb_increment tw = unsafePerformIO $ do
  putStrLn "UV timeout callback entered ..."
  if tw == null then
      putStrLn "Null watcher"
  else
    print_pointer "Watcher"  tw
  vhd <- per_vhost_data__dumb_increment_from_timeout_watcher tw
  if vhd == null then
      putStrLn "Null vhd"
  else
    print_pointer "VHD"  vhd    
  vhost <- peek PTR (vhost_field vhd)
  prots <- peek PTR (protocols_field vhd)
  __ <- lws_callback_on_writable_all_protocol_vhost vhost prots
  putStrLn "UV timeout callback exited."
  pure ()
  
uv_timeout_cb_wrapper : IO Ptr
uv_timeout_cb_wrapper = foreign FFI_C "%wrapper" (CFnPtr (Ptr -> ()) -> IO Ptr)
  (MkCFnPtr (uv_timeout_cb_dumb_increment))

init_protocol : (wsi : Ptr) -> IO Int
init_protocol wsi = do
  putStrLn "Init_protocol entered ..."
  vh   <- lws_vhost_get wsi
  if (unwrap_vhost vh) == null then
      putStrLn "Null vhost"
  else
    print_pointer "Vhost"  (unwrap_vhost vh)
  prot <- lws_protocol_get wsi
  if (unwrap_protocols_array prot) == null then
      putStrLn "Null protocols"
  else
    print_pointer "Protocols"  (unwrap_protocols_array prot)
  vhd  <- lws_protocol_vh_priv_zalloc vh prot 176 -- = hand calculation of STRUCT - 152 + 3 x 64-bit pointers
  if vhd == null then
      putStrLn "Null vhd"
  else
    print_pointer "VHD"  vhd
  ctx  <- lws_get_context wsi
  if ctx == null then
      putStrLn "Null context"
  else
    pure ()
  sz   <- uv_timer_t_size
  let size = prim__truncB64_Int sz
  putStrLn $ "Size is " ++ (show size)
  poke PTR (context_field vhd) ctx
  poke PTR (protocols_field vhd) (unwrap_protocols_array prot)
  poke PTR (vhost_field vhd) (unwrap_vhost vh)
  loop <- lws_uv_getloop ctx 0
  uv_timer_init loop vhd
  uv_timer_start vhd !(uv_timeout_cb_wrapper) 50 50
  putStrLn "Init_protocol exited."
  pure OK
  
destroy_protocol : (wsi : Ptr) -> IO Int
destroy_protocol wsi = do
  putStrLn "Destroy_protocol entered ..."
  vh   <- lws_vhost_get wsi
  prot <- lws_protocol_get wsi
  vhd  <- lws_protocol_vh_priv_get vh prot
  if vhd == null then do
    putStrLn "Destroy_protocol exited with null vhd."
    pure OK
  else do
    putStrLn "Destroy_protocol exiting with non-null vhd..."
    uv_timer_stop vhd
    putStrLn "Destroy_protocol exited with non-null vhd."
    pure OK

dumb_increment_handler : Callback_handler
dumb_increment_handler wsi reason user inp len = unsafePerformIO $ do
  putStrLn "Handler entered ..."
  if reason == LWS_CALLBACK_PROTOCOL_INIT then do
    init_protocol wsi
  else do
    if reason == LWS_CALLBACK_PROTOCOL_DESTROY then do
      destroy_protocol wsi
    else do
      if reason == LWS_CALLBACK_ESTABLISHED then do
        putStrLn "Callback established entered ..."
        poke I32 ((per_session_data_structure#0) user) 0
        open_testing
        putStrLn "Callback established exited."        
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
  putStrLn "Init entered ..."
  magic <- api_magic caps
  if magic /= LWS_PLUGIN_API_MAGIC then do
    lwsl_err $ "Plugin API " ++ show (LWS_PLUGIN_API_MAGIC) ++ ", library API " ++ (show magic)
    return FAIL
  else do
    array <- allocate_protocols_array 1
    add_protocol_handler array 1 0 dumb_increment_protocol_name dumb_increment_wrapper dumb_increment_data_size 
      dumb_increment_rx_buffer_size 0 null
    set_capabilities_protocols caps array 1
    set_capabilities_extensions caps null 0
    putStrLn "Init left"
    return OK

init_function: FFI_Export FFI_C "init.h" []
init_function = Fun init_dumb_increment_protocol "init_protocol_dumb_increment_exported" End

destroy_protocol_dumb_increment : (context : Ptr) -> Int
destroy_protocol_dumb_increment context = OK

destroy_function: FFI_Export FFI_C "destroy.h" []
destroy_function = Fun destroy_protocol_dumb_increment "destroy_protocol_dumb_increment_exported" End


