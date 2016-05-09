||| Port of libwebsockets-test-server - libwebsockets test implementation
module Main

import WS.Context
import WS.Logging
import WS.Daemon
import WS.Extension
import WS.Service
import WS.Mount
import WS.Vhost_options
import WS.Uv
import WS.Protocol
import System.Posix.Syslog
import System.Posix.Signal
import ArgParse
import Data.String
import CFFI
import System

import Dumb_increment

%default total

%include C "test_server.h"
%link C "/usr/local/lib/libwebsockets.so"

abort : IO ()
abort = foreign FFI_C "abort" (IO ())

close_testing : IO ()
close_testing = foreign FFI_C "close_testing" (IO ())

record Options where
  constructor Make_options
  help              : Bool
  debug             : Maybe Int
  port              : Maybe Int
  ssl               : Bool 
  allow_non_ssl     : Bool
  interfaace        : Maybe String
  closetest         : Bool
  ssl_cert          : Maybe String
  ssl_key           : Maybe String
  ssl_ca            : Maybe String 
  libev             : Bool
  daemonize         : Bool
  resource_path     : Maybe String   
  uid               : Maybe Int
  gid               : Maybe Int
  ssl_verify_client : Bool
  
Show Options where
  show (Make_options h d p s a i c C K A e D r u g v) =
    unwords ["Make_options", show h, show d, show p, show s, show a, show i, show c, show C,
      show K, show A, show e, show D, show r, show u, show g, show v]
      
Eq Options where
  (==) (Make_options h d p s a i c C K A e D r u g v) (Make_options h' d' p' s' a' i' c' C' K' A' e' D' r' u' g' v') =
    h == h' && d == d' && p == p' && s == s' && a == a' && i == i' && c == c' && C == C' && K == K' && A == A' &&
      e == e' && D == D' && r == r' && u == u' && g == g' && v == v'

default_options : Options
default_options = Make_options False Nothing Nothing False False Nothing False Nothing Nothing Nothing False False Nothing Nothing Nothing False

usage : String
usage = "Usage: test_server [--port=<p>] [--ssl] [-d <log bitfield>] [--resource-path <path>]"

convert_options : Arg -> Options -> Maybe Options
convert_options (Files xs)     o = Nothing
convert_options (Flag x)       o =
  case x of
    "help"              => Just  $ record {help = True} o
    "h"                 => Just  $ record {help = True} o    
    "ssl"               => Just  $ record {ssl = True} o
    "s"                 => Just  $ record {ssl = True} o    
    "allow-non-ssl"     => Just  $ record {allow_non_ssl = True} o    
    "a"                 => Just  $ record {allow_non_ssl = True} o        
    "closetest"         => Just  $ record {closetest = True} o    
    "c"                 => Just  $ record {closetest = True} o    
    "libev"             => Just  $ record {libev = True} o        
    "e"                 => Just  $ record {libev = True} o            
    "daemonize"         => Just  $ record {daemonize = True} o            
    "D"                 => Just  $ record {daemonize = True} o     
    "ssl-verify-client" => Just  $ record {ssl_verify_client = True} o     
    "v"                 => Just  $ record {ssl_verify_client = True} o     
    otherwise           => Nothing           
convert_options (KeyValue k v) o = 
  case k of
    "debug"             => parse_debug v
    "d"                 => parse_debug v
    "port"              => parse_port v
    "p"                 => parse_port v
    "interface"         => parse_interface v
    "i"                 => parse_interface v
    "ssl-cert"          => parse_ssl_cert v
    "C"                 => parse_ssl_cert v
    "ssl-key"           => parse_ssl_key v
    "K"                 => parse_ssl_key v    
    "ssl-ca"            => parse_ssl_ca v
    "A"                 => parse_ssl_ca v 
    "resource-path"     => parse_resource_path v
    "r"                 => parse_resource_path v       
    "u"                 => parse_uid v       
    "g"                 => parse_gid v       
    otherwise           => Nothing
 where
   parse_debug : String -> Maybe Options
   parse_debug v = case parsePositive {a=Int} v of
                        Just n  => Just $ record {debug = Just n} o
                        Nothing => Nothing
   parse_port : String -> Maybe Options
   parse_port v =  case parsePositive {a=Int} v of
                        Just n  => Just $ record {port = Just n} o
                        Nothing => Nothing         
   parse_interface : String -> Maybe Options
   parse_interface v = Just $ record {interfaace = Just v} o
   parse_ssl_cert : String -> Maybe Options
   parse_ssl_cert v = Just $ record {ssl_cert = Just v} o  
   parse_ssl_key : String -> Maybe Options
   parse_ssl_key v = Just $ record {ssl_key = Just v} o  
   parse_ssl_ca : String -> Maybe Options
   parse_ssl_ca v = Just $ record {ssl_ca = Just v} o  
   parse_resource_path : String -> Maybe Options
   parse_resource_path v = Just $ record {resource_path = Just v} o  
   parse_uid : String -> Maybe Options
   parse_uid v = case parsePositive {a=Int} v of
                      Just n  => Just $ record {uid = Just n} o
                      Nothing => Nothing
   parse_gid : String -> Maybe Options
   parse_gid v = case parsePositive {a=Int} v of
                      Just n  => Just $ record {gid = Just n} o
                      Nothing => Nothing

||| Directory where installed data files are found (hard-coded for now)
local_resource_path : String
local_resource_path = "/usr/local/share/libwebsockets-test-server"

||| Path to find static / default resources
|||
||| @options - the command-line arguments
chosen_resource_path : (options : Options) -> String
chosen_resource_path opts = case resource_path opts of
  Nothing => local_resource_path
  Just r  => r

||| Path to SSL certificate
|||
||| @options - the command-line arguments
certificate_path : (options : Options) -> String
certificate_path opts = case ssl_cert opts of
  Nothing => local_resource_path ++ "/libwebsockets-test-server.pem"
  Just c  => c

||| Path to SSL key
|||
||| @options - the command-line arguments
key_path : (options : Options) -> String
key_path opts = case ssl_key opts of
  Nothing => local_resource_path ++ "/libwebsockets-test-server.key.pem"
  Just c  => c

logging_options : Options -> Int
logging_options opts = 
  if daemonize opts 
    then LOG_PID
    else (LOG_PID + LOG_PERROR)
  
||| If requested, daemonize
maybe_daemonize : (options : Options) -> IO ()
maybe_daemonize opts = do
  if daemonize opts then do
    ok <- lws_daemonize "/tmp/.lwsts-lock"
    if ok then 
      pure ()
    else do
      putStrLn "Unable to daemonize - check for existence of /tmp/.lwsts-lock"
      exit 1
  else
    pure ()
  
||| Server options culled mostly from the command line
options_from_arguments : (options : Options) -> IO Bits32
options_from_arguments opts = let base  = LWS_SERVER_OPTION_VALIDATE_UTF8 + LWS_SERVER_OPTION_LIBUV
                                  ev    = if libev opts then 
                                             LWS_SERVER_OPTION_LIBEV 
                                             else 0
                                  allow = if allow_non_ssl opts then 
                                             LWS_SERVER_OPTION_ALLOW_NON_SSL_ON_SSL_PORT 
                                             else 0
                                  ss    = if ssl opts || ssl_verify_client opts then 
                                             LWS_SERVER_OPTION_REDIRECT_HTTP_TO_HTTPS
                                             else 0
                                  vc    = if ssl_verify_client opts then
                                             LWS_SERVER_OPTION_REQUIRE_VALID_OPENSSL_CLIENT_CERT
                                          else 0
                              in pure $ base + ev + allow + ss
  
||| If @options includes an interface name, then set it on @conn_info
|||
||| @conn_info - server's connection information
||| @options - parsed command-line options
partial
conditionally_set_interface : (conn_info : Ptr) -> (options : Options) -> IO ()
conditionally_set_interface conn_info opts = do
  case interfaace opts of
    Nothing    => pure ()
    Just iface => set_interface conn_info iface

||| Set-up the SSL environment
|||
||| @conn_info - server's connection information
||| @options - parsed command-line options
partial
check_ssl : (conn_info : Ptr) -> (options : Options) -> IO ()
check_ssl info opts = do
  let ch_r_p = chosen_resource_path opts
  let kp = key_path opts
  let kp_len = 1024
  let cp = certificate_path opts
  let cp_len = 1024
  if (toIntegerNat $ length (ch_r_p)) > (cp_len - 32) || (toIntegerNat $ length (ch_r_p)) > (kp_len - 32) then do
    lwsl_err "resource path too long"
    exit (-1)
  else do
    let cp2 = if cp_len == 0 then ch_r_p ++ cp else cp
    let kp2 = if kp_len == 0 then ch_r_p ++ kp else kp    
    set_ssl_certificate_path info cp2
    set_ssl_key_path info kp2
    case ssl_ca opts of
      Nothing => pure ()
      Just ca => set_ssl_ca_filepath info ca
||| Allocate and add the extension services
partial
add_extensions : (conn_info : Ptr) -> IO Ptr
add_extensions conn_info = do
  exts <- allocate_extensions_array 2
  add_extension exts 3 0 "permessage-deflate" lws_extension_callback_deflate_pm "permessage-deflate"
  add_extension exts 3 1 "deflate-frame" lws_extension_callback_deflate_pm "deflate_frame"
  pure exts

||| Mount-points in the URI space
partial
mount_points : IO Ptr
mount_points = do 
  post_mount <- allocate_callback_mount null "/formtest" "protocol-post-demo"
  allocate_filesystem_mount post_mount "/" local_resource_path "test.html"

{-
||| Allocate and install the protocols, since we can't use plugins
partial
install_protocols : (info : Ptr) -> IO ()
install_protocols info = do
  array <- allocate_protocols_array 1
  add_protocol_handler array 2 0 dumb_increment_protocol_name dumb_increment_wrapper dumb_increment_data_size dumb_increment_rx_buffer_size 0 null
  set_protocols info array
-}
||| Cancel servicing of pending websocket activity when Ctrl-C is pressed
interrupt_handler : Ptr -> Signal_handler
interrupt_handler context sig_num = unsafePerformIO $ do
  lws_cancel_service context

interrupt_handler_wrapper : Ptr -> IO Ptr
interrupt_handler_wrapper context = foreign FFI_C "%wrapper" (CFnPtr (Signal_handler) -> IO Ptr)
 (MkCFnPtr (interrupt_handler context))

signal_cb : Uv_signal_callback
signal_cb watcher sig_num = unsafePerformIO $ do
 lwsl_err $ "Signal " ++ (show sig_num) ++ " caught, exiting...\n"
 if sig_num == SIGTERM || sig_num == SIGINT then do
   context <- uv_user_data watcher
   lws_libuv_stop context
 else do
   abort

signal_cb_wrapper : IO Ptr
signal_cb_wrapper = foreign FFI_C "%wrapper" (CFnPtr (Uv_signal_callback) -> IO Ptr) (MkCFnPtr signal_cb)

--{- we probably can't compile Idirs to a .so, so we'll have to forgo the plugins for now - uncomment to use the C plugins - will also need to uncomment below
partial
plugins_directory_list : IO Ptr
plugins_directory_list = do
  let array = ARRAY 2 PTR
  let dir = local_resource_path ++ "/plugins/"
  arr <- alloc array
  str <- string_to_c dir
  first_fld <- pure $ (array#0)
  poke PTR (first_fld arr) str
  pure arr
---}

partial
pvo : IO Ptr
pvo = do
  pvo_opt <- allocate_pvo null null "default" "1"
  pvo_3 <- allocate_pvo null null "protocol-post-demo" ""
  pvo_2 <- allocate_pvo pvo_3 null "lws-status" ""
  pvo_1 <- allocate_pvo pvo_2 null "lws-mirror-protocol" ""
  allocate_pvo pvo_1 pvo_opt "dumb-increment-protocol" ""  
  
ssl_cipher_list : String
ssl_cipher_list = """
ECDHE-ECDSA-AES256-GCM-SHA384:
ECDHE-RSA-AES256-GCM-SHA384:
DHE-RSA-AES256-GCM-SHA384:
ECDHE-RSA-AES256-SHA384:
HIGH:!aNULL:!eNULL:!EXPORT:
!DES:!MD5:!PSK:!RC4:!HMAC_SHA1:
!SHA1:!DHE-RSA-AES128-GCM-SHA256:
!DHE-RSA-AES128-SHA256:
!AES128-GCM-SHA256:
!AES128-SHA256:
!DHE-RSA-AES256-SHA256:
!AES256-GCM-SHA384:!AES256-SHA256"""

||| Set-up and run the server
|||
||| @options - parsed command-line options
partial
setup_server : (options : Options) -> IO ()
setup_server opts = do
  case closetest opts of
    True  => close_testing
    False => pure ()
  clear_connection_information
  conn_info <- connection_information
  set_port conn_info $ fromInteger $ cast $ fromMaybe 7681 (port opts)
  maybe_daemonize opts 
  set_options conn_info $ ! (options_from_arguments opts)
  conditionally_set_interface conn_info opts
  set_gid conn_info $ fromInteger $ cast $ fromMaybe (-1) (gid opts)
  set_uid conn_info $ fromInteger $ cast $ fromMaybe (-1) (uid opts)
  set_log_mask LOG_DEBUG True
  open_log "lwsts" (logging_options opts) LOG_DAEMON
  set_log_level_syslog (fromMaybe 7 (debug opts))
  lwsl_notice "libwebsockets test server ported to Idris - license LGPL2.1+SLE\n"
  lwsl_notice "Original C code (C) Copyright 2010-2016 Andy Green <andy@warmcat.com>\n"
  lwsl_notice $ "Using resource path " ++ (chosen_resource_path opts)
  case ssl opts of
    False => pure ()
    True  => check_ssl conn_info opts
  set_timeouts conn_info $ the Bits32 5
  set_ssl_cipher_list conn_info ssl_cipher_list
  set_plugin_dirs conn_info !plugins_directory_list
  --install_protocols conn_info
  set_mounts conn_info !mount_points
  set_pvo conn_info !pvo
  set_max_http_header_pool conn_info 16
  exts <-add_extensions conn_info
  set_extensions conn_info exts
  context <- create_context conn_info
  if context == null then do
    lwsl_err "libwebsocket init failed\n"
    exit (-1)
  else do
    install_signal_handler SIGINT (interrupt_handler_wrapper context)
    lws_uv_sigint_cfg context 1 signal_cb_wrapper
    uv_loop_ok <- lws_uv_initloop context null 0
    if uv_loop_ok == 0 then
      lws_libuv_run context 0
    else
      lwsl_err "lws_uv_initloop failed\n"
    lws_context_destroy context
    lwsl_notice "libwebsockets-test-server exited cleanly\n"
    free exts
    close_log
    exit 0

partial
main : IO ()
main = do
  args <- getArgs
  let res = parseArgs default_options convert_options args 
  case res of
    Left (ParseError err)     => do
      putStrLn "Parse error"
      putStrLn err
      exit 1
    Left (InvalidOption arg)  => do
      putStrLn $ "Invalid option: " ++ (show arg)
      exit 1
    Right opts => case help opts of
      True  => do
        putStrLn usage
        exit 1
      False => setup_server opts

