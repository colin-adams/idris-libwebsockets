||| Implementation of the lws_mirror protocol
module Mirror

import WS.Handler
import WS.Logging
import WS.Plugin
import WS.Protocol
import WS.Vhost
import WS.Write
import WS.Context

import Data.Fin
import CFFI

%include C "../test_server.h"
%flag C "-fpic"

transmission_buffer_start : Ptr -> IO Ptr
transmission_buffer_start buffer = foreign FFI_C "transmission_buffer_start" (Ptr -> IO Ptr) buffer

LWS_PRE : Bits64
LWS_PRE = unsafePerformIO $ foreign FFI_C "LWS_PREfix" (IO Bits64)

memcpy : Ptr -> Ptr -> Bits64 -> IO ()
memcpy dest src len = foreign FFI_C "memcpy" (Ptr -> Ptr -> Bits64 -> IO ()) dest src len
  
protocol_name : String
protocol_name = "lws-mirror-protocol"

data_size : Bits64
data_size = 16

rx_buffer_size : Bits64
rx_buffer_size = 128

per_session_data__lws_mirror : Composite
per_session_data__lws_mirror = STRUCT [PTR, I32]

wsi_field: Ptr -> CPtr
wsi_field user = (per_session_data__lws_mirror#0) user

ringbuffer_tail_field: Ptr -> CPtr
ringbuffer_tail_field user = (per_session_data__lws_mirror#1) user

message : Composite
message = STRUCT [PTR, I64]

payload_field: Ptr -> CPtr
payload_field msg = (message#0) msg

len_field: Ptr -> CPtr
len_field msg = (message#1) msg

MAX_MESSAGE_QUEUE : Int
MAX_MESSAGE_QUEUE = 512

message_buffer : Composite
message_buffer = ARRAY MAX_MESSAGE_QUEUE message

per_vhost_data__lws_mirror : Composite
per_vhost_data__lws_mirror = STRUCT [message_buffer, I32]

vhost_data_size : Int
vhost_data_size = MAX_MESSAGE_QUEUE * (prim__truncB64_Int  data_size) + 4

ringbuffer_field: Ptr -> CPtr
ringbuffer_field v = (per_vhost_data__lws_mirror#0) v

ringbuffer_head_field: Ptr -> CPtr
ringbuffer_head_field v = (per_vhost_data__lws_mirror#1) v

last_cell : Int
last_cell = MAX_MESSAGE_QUEUE - 1

last_but_one : Int
last_but_one = MAX_MESSAGE_QUEUE - 2

last_but_fourteen : Int
last_but_fourteen = MAX_MESSAGE_QUEUE - 15

write_response : (wsi : Ptr) -> (user : Ptr) -> (vhost : Ptr) -> IO Int
write_response wsi user vhost = do
  loop
 where
   loop : IO Int
   loop = do
     hd <- peek I32 (ringbuffer_head_field vhost)
     tl <- peek I32 (ringbuffer_tail_field user)
     if hd == tl then  pure OK
     else do
       let msg = ((message_buffer#(cast $ prim__truncB32_Int tl)) vhost)
       m   <- peek I64 (len_field msg)
       p   <- peek PTR (payload_field msg)
       pay <- transmission_buffer_start p
       n   <- lws_write wsi pay m LWS_WRITE_TEXT
       if n < 0 then do
         lwsl_err $ "ERROR " ++ (show n) ++ " writing to mirror socket\n"
         pure FAIL
       else do
         if n < (prim__truncB64_Int m) then do
           lwsl_err $ "mirror partial write " ++ (show n) ++ " vs " ++ (show m) ++ "\n"
           pure OK
         else pure OK
         if (prim__truncB32_Int tl) == last_cell then
           poke I32 (ringbuffer_tail_field user) 0
         else
           poke I32 (ringbuffer_tail_field user) (tl + 1)
         tl <- peek I32 (ringbuffer_tail_field user)
         if (prim__andInt ((prim__truncB32_Int hd) - (prim__truncB32_Int tl)) last_cell) == last_but_fourteen then do
           ctx   <- lws_get_context wsi
           prots <- lws_get_protocol wsi 
           lws_rx_flow_allow_all_protocol ctx prots
           pure OK
         else pure OK
         choked <- lws_send_pipe_choked wsi
         if choked /= 0 then do
           _ <- lws_callback_on_writable wsi
           pure OK
         else loop
 
receive_done :  (wsi : Ptr) -> IO Int
receive_done wsi = do
  ctx <- lws_get_context wsi
  prots <- lws_get_protocol wsi
  lws_callback_on_writable_all_protocol ctx prots
    
choke :  (wsi : Ptr) -> IO Int
choke wsi = do
  lwsl_debug $ "LWS_CALLBACK_RECEIVE: throttling \n" -- ++ show wsi
  lws_rx_flow_control wsi 0
  receive_done wsi
  
reallocate_head : (vhost : Ptr) -> (hd : Nat) ->  (inp : Ptr) -> (len : Bits64) -> IO ()
reallocate_head vhost hd inp len = do
  let msg = ((message_buffer#hd) vhost) 
  payload <- peek PTR msg
  if payload == null then do
    pure ()
  else do
    mfree payload
    pure ()
  new_payload <- calloc 1 ((prim__truncB64_Int LWS_PRE) + (prim__truncB64_Int len))
  if new_payload == null then
    lwsl_err "Out of memory\n"
  else
    pure ()
  poke PTR msg new_payload
  memcpy !(transmission_buffer_start new_payload) inp len
  poke I64 (len_field msg) len
  
receive_request : (wsi : Ptr) -> (user : Ptr) -> (vhost : Ptr) -> (inp : Ptr) -> (len : Bits64) -> IO Int
receive_request wsi user vhost inp len = do
  hd <- peek I32 (ringbuffer_head_field vhost)
  tl <- peek I32 (ringbuffer_tail_field user)
  if (prim__andInt ((prim__truncB32_Int hd) - (prim__truncB32_Int tl)) last_cell) == last_cell then do
    lwsl_err "dropping!\n"
    choke wsi
  else do
    reallocate_head vhost (cast $ prim__truncB32_Int hd) inp len
    if (prim__truncB32_Int hd) == last_cell then
      poke I32(ringbuffer_head_field vhost) 0
    else
      poke I32(ringbuffer_head_field vhost) (hd + 1)
    hd <- peek I32 (ringbuffer_head_field vhost)        
    if (prim__andInt ((prim__truncB32_Int hd) - (prim__truncB32_Int tl)) last_cell) /= last_but_one then
      receive_done wsi
    else do
      lwsl_debug $ "LWS_CALLBACK_RECEIVE: throttling \n" -- ++ (show wsi) ++ "\n"
      choke wsi
    
lws_mirror_handler : Callback_handler
lws_mirror_handler wsi reason user inp len = unsafePerformIO $ do
  vh    <- lws_vhost_get wsi
  prots <- lws_get_protocol wsi
  if reason == LWS_CALLBACK_PROTOCOL_INIT then do
    buf <- lws_protocol_vh_priv_zalloc vh prots vhost_data_size
    pure OK
  else do
    if reason == LWS_CALLBACK_ESTABLISHED then do
      lwsl_info "lws_mirror_handler: LWS_CALLBACK_PROTOCOL_ESTABLISHED\n"
      v <- lws_protocol_vh_priv_get vh prots
      hd <- peek I32 (ringbuffer_head_field v)
      poke I32 (ringbuffer_tail_field user) hd
      poke PTR (wsi_field user) wsi
      pure OK
    else do
      if reason == LWS_CALLBACK_PROTOCOL_DESTROY then do
        v <- lws_protocol_vh_priv_get vh prots
        if v == null then 
          pure OK
        else do
          lwsl_info $ "lws_mirror_handler: mirror protocol cleaning up \n" -- ++ ++ "\n" (show $ ptrToBits64 v)
          buf <- peek PTR (ringbuffer_field v)
          free_message buf 0
          pure OK
      else do
        if reason == LWS_CALLBACK_SERVER_WRITEABLE then do
          v <- lws_protocol_vh_priv_get vh prots
          write_response wsi user v
        else do
          if reason == LWS_CALLBACK_RECEIVE then do
            v <- lws_protocol_vh_priv_get vh prots
            receive_request wsi user v inp len
          else pure OK
 where free_message : Ptr -> Int -> IO ()
       free_message buf n = case n < MAX_MESSAGE_QUEUE of
         False => pure ()
         True  => do
           msg <- peek PTR ((message_buffer#(cast n)) buf)
           if msg == null then
             pure ()
           else do
             payload <- peek PTR (payload_field msg)
             if payload == null then
               free_message buf (n + 1)
             else do
               mfree payload
               poke PTR (payload_field msg) null
               free_message buf (n + 1)
         
         
lws_mirror_wrapper : IO Ptr
lws_mirror_wrapper = foreign FFI_C "%wrapper" (CFnPtr (Callback_handler) -> IO Ptr) (MkCFnPtr lws_mirror_handler)

init_lws_mirror_protocol: (context : Ptr) -> (capabilities : Ptr) -> Int
init_lws_mirror_protocol context caps = unsafePerformIO $ do
  magic <- api_magic caps
  if magic /= LWS_PLUGIN_API_MAGIC then do
    lwsl_err $ "Plugin API " ++ show (LWS_PLUGIN_API_MAGIC) ++ ", library API " ++ (show magic)
    return 1
  else do
    array <- allocate_protocols_array 1
    add_protocol_handler array 1 0 protocol_name lws_mirror_wrapper data_size 
      rx_buffer_size 0 null
    set_capabilities_protocols caps array 1
    set_capabilities_extensions caps null 0
    return OK
   
destroy_protocol_lws_mirror : (context : Ptr) -> Int
destroy_protocol_lws_mirror context = OK

exports: FFI_Export FFI_C "exports.h" []
exports = Fun init_lws_mirror_protocol "init_protocol_lws_mirror_exported" $ Fun destroy_protocol_lws_mirror "destroy_protocol_lws_mirror_exported" $ End
