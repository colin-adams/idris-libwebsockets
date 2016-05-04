||| Logging facility
module Logging

%access export

||| Set logging levels and log to syslog
|||
||| @level   - levels (bitmask) of messages to emit 
set_log_level_syslog : (level : Int) -> IO ()
set_log_level_syslog level = foreign FFI_C "set_log_level_syslog" (Int -> IO ()) level

||| Issue a notice-level message
|||
||| @message - message to issue
lwsl_notice : (message : String) -> IO ()
lwsl_notice message = foreign FFI_C "lwsl_notice" (String -> IO ()) message

||| Issue a warning message
|||
||| @message - message to issue
lwsl_warn : (message : String) -> IO ()
lwsl_warn message = foreign FFI_C "lwsl_warn" (String -> IO ()) message

||| Issue an error message
|||
||| @message - message to issue
lwsl_err : (message : String) -> IO ()
lwsl_err message = foreign FFI_C "lwsl_err" (String -> IO ()) message

||| Issue an information message
|||
||| @message - message to issue
lwsl_info : (message : String) -> IO ()
lwsl_info message = foreign FFI_C "lwsl_info" (String -> IO ()) message

||| Issue a debug message
|||
||| @message - message to issue
lwsl_debug : (message : String) -> IO ()
lwsl_debug message = foreign FFI_C "lwsl_debug" (String -> IO ()) message

||| Issue a parser message
|||
||| @message - message to issue
lwsl_parser : (message : String) -> IO ()
lwsl_parser message = foreign FFI_C "lwsl_parser" (String -> IO ()) message

||| Issue an extension message
|||
||| @message - message to issue
lwsl_ext : (message : String) -> IO ()
lwsl_ext message = foreign FFI_C "lwsl_ext" (String -> IO ()) message

||| Issue a client message
|||
||| @message - message to issue
lwsl_client : (message : String) -> IO ()
lwsl_client message = foreign FFI_C "lwsl_client" (String -> IO ()) message

||| Issue a latency message
|||
||| @message - message to issue
lwsl_latency : (message : String) -> IO ()
lwsl_latency message = foreign FFI_C "lwsl_latency" (String -> IO ()) message


