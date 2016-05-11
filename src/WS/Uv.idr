||| libwebsockets use of libuv async I/O
module Uv

import WS.Context
import CFFI

%include C "lws.h"

||| Type of UV signal handlers
|||
||| watcher uv_signal_t *
||| sig_num - the signal being handled
public export
Uv_signal_callback : Type
Uv_signal_callback = (watcher : Ptr) -> (sig_num : Int) -> ()

||| Stop libuv loop processing
|||
||| @context - result of WS.Context.create_context
export
lws_libuv_stop : (context : Context) -> IO ()
lws_libuv_stop context = foreign FFI_C "lws_libuv_stop" (Ptr -> IO ()) (unwrap_context context)

||| Configure uv signal handling
|||
||| @context - result of WS.Context.create_context
||| @use_uv_sigint - ? Int-valued boolean I think
||| @callback - handler for libuv signals (?) - a wrapper on Uv_signal_callback
lws_uv_sigint_cfg_internal : (context : Context) -> (use_uv_sigint : Int) -> (callback : Ptr) -> IO Int
lws_uv_sigint_cfg_internal context use_uv_sigint callback = foreign FFI_C "lws_uv_sigint_cfg" (Ptr -> Int -> Ptr -> IO Int) (unwrap_context context) use_uv_sigint callback

||| Configure uv signal handling
|||
||| @context - result of WS.Context.create_context
||| @use_uv_sigint - ? Int-valued boolean I think
||| @callback - handler for libuv signals (?) - a Uv_signal_callback
export
lws_uv_sigint_cfg : (context : Context) -> (use_uv_sigint : Int) -> (callback : IO Ptr) -> IO Int
lws_uv_sigint_cfg context use_uv_sigint callback = do
  wr <- callback
  lws_uv_sigint_cfg_internal context use_uv_sigint wr
  
||| Initialize libuv loop processing
|||
||| @context - result of WS.Context.create_context
||| @loop    - pointer to a uv_loop_t (a structure)
||| @tsi     - don't know
export 
lws_uv_initloop : (context : Context) -> (loop : Ptr) -> (tsi : Int) -> IO Int
lws_uv_initloop context loop tsi = foreign FFI_C "lws_uv_initloop" (Ptr -> Ptr -> Int -> IO Int) (unwrap_context context) loop tsi

export
lws_libuv_run : (context : Context) -> (tsi : Int) -> IO ()
lws_libuv_run context tsi = foreign FFI_C "lws_libuv_run" (Ptr -> Int -> IO ()) (unwrap_context context) tsi

||| Access context from a uv signal handler
export
uv_user_data : Ptr -> IO Context
uv_user_data watcher = do
  ptr <- foreign FFI_C  "uv_user_data" (Ptr -> IO Ptr) watcher
  pure $ wrap_context ptr
