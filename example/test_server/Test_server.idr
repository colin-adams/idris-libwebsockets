||| Port of libwebsockets-test-server - libwebsockets test implementation
module Main

import WS.Context
import WS.Logging
import WS.Daemon
import System.Posix.Syslog
import ArgParse
import Data.String
import CFFI
import System

%default total

%link C "/usr/local/lib/libwebsockets.so"

record Options where
  constructor Make_options
  help          : Bool
  debug         : Maybe Int
  port          : Maybe Int
  ssl           : Bool 
  allow_non_ssl : Bool
  interfaace    : Maybe String
  closetest     : Bool
  ssl_cert      : Maybe String
  ssl_key       : Maybe String
  ssl_ca        : Maybe String 
  libev         : Bool
  daemonize     : Bool
  resource_path : Maybe String   
  uid           : Maybe Int
  gid           : Maybe Int
  
Show Options where
  show (Make_options h d p s a i c C K A e D r u g) =
    unwords ["Make_options", show h, show d, show p, show s, show a, show i, show c, show C,
      show K, show A, show e, show D, show r, show u, show g]
      
Eq Options where
  (==) (Make_options h d p s a i c C K A e D r u g) (Make_options h' d' p' s' a' i' c' C' K' A' e' D' r' u' g') =
    h == h' && d == d' && p == p' && s == s' && a == a' && i == i' && c == c' && C == C' && K == K' && A == A' &&
      e == e' && D == D' && r == r' && u == u' && g == g'

default_options : Options
default_options = Make_options False Nothing Nothing False False Nothing False Nothing Nothing Nothing False False (Just "./") Nothing Nothing

usage : String
usage = "Usage: test_server [--port=<p>] [--ssl] [-d <log bitfield>] [--resource-path <path>]" -- TODO

convert_options : Arg -> Options -> Maybe Options
convert_options (Files xs)     o = Nothing
convert_options (Flag x)       o =
  case x of
    "help"             => Just  $ record {help = True} o
    "h"                => Just  $ record {help = True} o    
    "ssl"              => Just  $ record {ssl = True} o
    "s"                => Just  $ record {ssl = True} o    
    "allow-non-ssl"    => Just  $ record {allow_non_ssl = True} o    
    "a"                => Just  $ record {allow_non_ssl = True} o        
    "closetest"        => Just  $ record {closetest = True} o    
    "c"                => Just  $ record {closetest = True} o    
    "libev"            => Just  $ record {libev = True} o        
    "e"                => Just  $ record {libev = True} o            
    "daemonize"        => Just  $ record {daemonize = True} o            
    "D"                => Just  $ record {daemonize = True} o     
    otherwise          => Nothing           
convert_options (KeyValue k v) o = 
  case k of
    "debug"            => parse_debug v
    "d"                => parse_debug v
    "port"             => parse_port v
    "p"                => parse_port v
    "interface"        => parse_interface v
    "i"                => parse_interface v
    "ssl-cert"         => parse_ssl_cert v
    "C"                => parse_ssl_cert v
    "ssl-key"          => parse_ssl_key v
    "K"                => parse_ssl_key v    
    "ssl-ca"           => parse_ssl_ca v
    "A"                => parse_ssl_ca v 
    "resource-path"    => parse_resource_path v
    "r"                => parse_resource_path v       
    "u"                => parse_uid v       
    "g"                => parse_gid v       
    otherwise          => Nothing
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

-- TODO signal handler
-- TODO extensions
-- TODO mounts
-- TODO plugin protocols
-- TODO signal cb
-- TODO plugin directories

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
  
||| Set-up and run the server
|||
||| @options - parsed command-line options
partial
setup_server : (options : Options) -> IO ()
setup_server opts = do
  clear_connection_information
  conn_info <- connection_information
  set_port conn_info $ prim__zextInt_B32 $ fromMaybe 7681 (port opts)
  maybe_daemonize opts
  open_log "lwsts" (logging_options opts) LOG_DAEMON
  set_log_level_syslog (fromMaybe 7 (debug opts))
  lwsl_notice "libwebsockets test server ported to Idris - license LGPL2.1+SLE\n"
  lwsl_notice "Original C code (C) Copyright 2010-2016 Andy Green <andy@warmcat.com>\n"
  close_log
 -- TODO poll
 
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
    Left (InvalidOption arg)     => do
      putStrLn $ "Invalid option: " ++ (show arg)
      exit 1
    Right opts => case help opts of
      True  => do
        putStrLn usage
        exit 1
      False => setup_server opts

