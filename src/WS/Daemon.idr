||| Running as a daemon
module Daemon

import CFFI

%include C "lws.h"

||| Try to run as a daemon
|||
||| @lock_path - path to the lock file
||| Returns 0 if successfull
export
lws_daemonize_int : (lock_path : String) -> IO Int
lws_daemonize_int lock_path = foreign FFI_C "lws_daemonize" (String -> IO Int) lock_path

||| Try to run as a daemon
|||
||| @lock_path - path to the lock file
||| Returns True if successfull
export
lws_daemonize : (lock_path : String) -> IO Bool
lws_daemonize lock_path = do
  rc <- lws_daemonize_int lock_path
  if rc == 0 then
      pure True
    else
      pure False
