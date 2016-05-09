||| Implementation of the dumb increment protocol
module Dumb_increment

import WS.Handler
import WS.Logging
import WS.Write

import CFFI

%include C "test_server.h"
%link C "test_server.o"

string_from_c : Ptr -> IO String
string_from_c str = foreign FFI_C "make_string" (Ptr -> IO String) str

string_to_c : String -> IO Ptr
string_to_c str = foreign FFI_C "string_to_c" (String -> IO Ptr) str

export
dumb_increment_protocol_name : String
dumb_increment_protocol_name = "dumb-increment-protocol"

export
dumb_increment_data_size : Bits64
dumb_increment_data_size = 4

export
dumb_increment_rx_buffer_size : Bits64
dumb_increment_rx_buffer_size = 10

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

dump_handshake_info : (wsi : Ptr) -> IO Int
dump_handshake_info wsi = do
  pure OK

dumb_increment_handler : Callback_handler
dumb_increment_handler wsi reason user inp len = unsafePerformIO $ do
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
      else do
        if reason == LWS_CALLBACK_FILTER_PROTOCOL_CONNECTION then
          dump_handshake_info wsi
        else do
          if reason == LWS_CALLBACK_WS_PEER_INITIATED_CLOSE then do
            lwsl_notice $ "LWS_CALLBACK_WS_PEER_INITIATED_CLOSE: len " ++ (show len) ++ "\n"
            -- TODO
            pure OK
          else pure OK
  
      
export
dumb_increment_wrapper : IO Ptr
dumb_increment_wrapper = foreign FFI_C "%wrapper" (CFnPtr (Callback_handler) -> IO Ptr) (MkCFnPtr dumb_increment_handler)
