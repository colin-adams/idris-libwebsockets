||| Functions that manipulate the libwebsockets context
module Context

import WS.Wsi
import WS.Extension
import WS.Protocol
import CFFI

%access export

%include C "lws.h"

private
string_to_c : String -> IO Ptr
string_to_c str = foreign FFI_C "string_to_c" (String -> IO Ptr) str

private
string_from_c : Ptr -> IO String
string_from_c str = foreign FFI_C "make_string" (Ptr -> IO String) str

||| Format of the server's connection information
|||
||| Fields are:
||| Port - to listen on... you can use CONTEXT_PORT_NO_LISTEN to suppress listening on any port, that's what you want if you are not running a websocket server at all but just using it as a client
||| interface - String - to bind (null to bind the listen socket to all interfaces, or the interface name, eg, "eth2"
||| protocols -  Array of structures listing supported protocols and a protocol- specific callback for each one.  The list is ended with an entry that has a NULL callback pointer.
||| extensions - Null or array of lws_extension structs listing the extensions this context supports.  If you configured with --without-extensions, you should give Null here.
||| token-limits - Null or struct lws_token_limits pointer which is initialized with a token length limit for each possible WSI_TOKEN_***
||| ssl_private_key_password - String - can pass Null
||| ssl_cert_filepath - String - If libwebsockets was compiled to use ssl, and you want	to listen using SSL, set to the filepath to fetch the server cert from, otherwise Null for unencrypted
||| ssl_private_key_filepath - String - filepath to private key if wanting SSL mode; if this is set to Null but sll_cert_filepath is set, the OPENSSL_CONTEXT_REQUIRES_PRIVATE_KEY callback is called to allow setting of the private key directly via openSSL library calls
||| ssl_ca_filepath - String - CA certificate filepath or Nulll
||| ssl_cipher_list - String - List of valid ciphers to use (eg, "RC4-MD5:RC4-SHA:AES128-SHA:AES256-SHA:HIGH:!DSS:!aNULL" or you can leave it as Null to get "DEFAULT"
||| http_proxy_address - String - If non-Null, attempts to proxy via the given address. If proxy auth is required, use format "username:password@server:port"
||| http_proxy_port - If http_proxy_address was non-Null, uses this port at the address
||| gid - group id to change to after setting listen socket, or -1.
||| uid - user id to change to after setting listen socket, or -1.
||| options - 0, or LWS_SERVER_OPTION_... bitfields
||| user - optional user pointer that can be recovered via the context pointer using lws_context_user
||| ka_time - 0 for no keepalive, otherwise apply this keepalive timeout to all libwebsocket sockets, client or server
||| ka_probes - if ka_time was nonzero, after the timeout expires how many times to try to get a response from the peer before giving up and killing the connection
||| ka_interval if ka_time was nonzero, how long to wait before each ka_probes attempt
||| provided_client_ssl_ctx - If non-null, swap out libwebsockets ssl implementation for the one provided by provided_ssl_ctx. Libwebsockets no longer is responsible for freeing the context if this option is selected.
||| max_http_header_data - The max amount of header payload that can be handled in an http request (unrecognized header payload is dropped)
||| max_http_header_pool - The max number of connections with http headers that can be processed simultaneously (the corresponding memory is allocated for the lifetime of the context).  If the pool is busy new incoming connections must wait for accept until one becomes free.
||| count_threads - how many contexts to create in an array, 0 = 1
||| fd_limit_per_thread - nonzero means restrict each service thread to this any fds, 0 means the default which is divide the process fd limit by the number of threads.
||| timeout_secs - various processes involving network roundtrips in the library are protected from hanging forever by timeouts.  If nonzero, this member lets you set the timeout used in seconds. Otherwise a default timeout is used.
||| ecdh_curve - if null, defaults to initializing server with "prime256v1"
||| vhost_name - name of vhost, must match external DNS name used to access the site, like "warmcat.com" as it's used to match Host: header and / or SNI name for SSL.
||| plugin_dirs - null, or null-terminated array of directories to scan for lws protocol plugins at context creation time
||| pvo - pointer to optional linked list of per-vhost options made accessible to protocols
||| keepalive_timeout - (default = 0 = 60s) seconds to allow remote client to hold on to an idle HTTP/1.1 connection
||| log_filepath - filepath to append logs to... this is opened before any dropping of initial privileges
||| mounts - optional linked list of mounts for this vhost
||| server_string - tring used in HTTP headers to identify server software, if null, "libwebsockets".
private
connection_information_struct : Composite
connection_information_struct = STRUCT [I32, PTR, PTR, PTR, PTR, PTR, PTR, PTR, PTR, PTR, PTR, I32, I32, I32, I32, PTR, I32, I32, I32, PTR, I16, I16, I32, I32, I32, PTR, PTR, PTR, PTR, I32, PTR, PTR, PTR]

||| Information need for create_context
data Context_info = Make_context_info Ptr

||| Access to the server's connection information
connection_information : IO Context_info
connection_information = do
  ptr <- foreign FFI_C "&connection_information" (IO Ptr)
  pure $ Make_context_info ptr

-- Field indices into connection_information_struct

private
port_field : Ptr -> CPtr
port_field info = (connection_information_struct#0) info

private
interface_field : Ptr -> CPtr
interface_field info = (connection_information_struct#1) info

private
protocols_field : Ptr -> CPtr
protocols_field info = (connection_information_struct#2) info

private
extensions_field : Ptr -> CPtr
extensions_field info = (connection_information_struct#3) info

private
ssl_cert_field : Ptr -> CPtr
ssl_cert_field info = (connection_information_struct#6) info

private
ssl_key_field : Ptr -> CPtr
ssl_key_field info = (connection_information_struct#7) info

private
ssl_ca_field : Ptr -> CPtr
ssl_ca_field info = (connection_information_struct#8) info

private
ssl_cipher_list_field : Ptr -> CPtr
ssl_cipher_list_field info = (connection_information_struct#9) info

private
gid_field : Ptr -> CPtr
gid_field info = (connection_information_struct#12) info

private
uid_field : Ptr -> CPtr
uid_field info = (connection_information_struct#13) info

private
options_field : Ptr -> CPtr
options_field info = (connection_information_struct#14) info

private
max_http_header_pool_field : Ptr -> CPtr
max_http_header_pool_field info = (connection_information_struct#21) info

private
timeout_secs_field : Ptr -> CPtr
timeout_secs_field info = (connection_information_struct#24) info

private
plugin_dirs_field : Ptr -> CPtr
plugin_dirs_field info = (connection_information_struct#27) info

private
pvo_field : Ptr -> CPtr
pvo_field info = (connection_information_struct#28) info

private
mounts_field : Ptr -> CPtr
mounts_field info = (connection_information_struct#31) info

||| Zero the connection information
|||
||| Call prior to create_context, or any calls to connection_information
clear_connection_information : IO ()
clear_connection_information = foreign FFI_C "clear_connection_information" (IO ())

||| Set the maximum size of the HTTP header pool
|||
||| @info - Result of call to connection_information
||| @size - size to be set
set_max_http_header_pool : (info : Context_info) -> (size : Bits16) -> IO ()
set_max_http_header_pool (Make_context_info info) size = do
  poke I16 (max_http_header_pool_field info) size

||| Set the timeouts in seconds
|||
||| @info - Result of call to connection_information
||| @secs - Number of seconds to timeout
set_timeouts : (info : Context_info) -> (secs : Bits32) -> IO ()
set_timeouts (Make_context_info info) secs = do
  poke I32 (timeout_secs_field info) secs
  
||| Set the port on which to listen
|||
||| @info - Result of call to connection_information
||| @port - The port to listen on.
set_port : (info : Context_info) -> (port : Bits32) -> IO ()
set_port (Make_context_info info) port = do
  poke I32 (port_field info) port

||| Set the group id under which to run
|||
||| @info - Result of call to connection_information
||| @gid - The gid to listen on.
set_gid : (info : Context_info) -> (gid : Bits32) -> IO ()
set_gid (Make_context_info info) gid = do
  poke I32 (gid_field info) gid

||| Set the user id under which to run
|||
||| @info - Result of call to connection_information
||| @uid - The uid to listen on.
set_uid : (info : Context_info) -> (uid : Bits32) -> IO ()
set_uid (Make_context_info info) uid = do
  poke I32 (uid_field info) uid
 
||| Set the SSL certificate file-path
|||
||| @info - Result of call to connection_information
||| @cert - file-path to the certicate
set_ssl_certificate_path : (info : Context_info) -> (cert : String) -> IO ()
set_ssl_certificate_path (Make_context_info info) cert = do
  str <- string_to_c cert
  poke PTR (ssl_cert_field info) str
 
||| Set the SSL private-key file-path
|||
||| @info - Result of call to connection_information
||| @key - file path to the key
set_ssl_key_path : (info : Context_info) -> (key : String) -> IO ()
set_ssl_key_path (Make_context_info info) key = do
  str <- string_to_c key
  poke PTR (ssl_key_field info) str

||| Set the SSL CA certificate file-path
|||
||| @info - Result of call to connection_information
||| @ca - file path to the CA certificate
set_ssl_ca_filepath : (info : Context_info) -> (ca : String) -> IO ()
set_ssl_ca_filepath (Make_context_info info) ca = do
  str <- string_to_c ca
  poke PTR (ssl_ca_field info) str

||| Set the SSL cipher list
|||
||| @info    - Result of call to connection_information
||| @ciphers - cipher list
set_ssl_cipher_list : (info : Context_info) -> (ciphers : String) -> IO ()
set_ssl_cipher_list (Make_context_info info) ciphers = do
  str <- string_to_c ciphers
  poke PTR (ssl_cipher_list_field info) str

||| Set the only interface on which to listen
|||
||| @info - Result of call to connection_information
||| @iface - The sole interface to listen on.
set_interface : (info : Context_info) -> (iface : String) -> IO ()
set_interface (Make_context_info info) iface = do
  str <- string_to_c iface
  poke PTR (interface_field info) str

||| Set extensions in use
|||
||| @info - Result of call to connection_information
||| @exts - The extensions to use
set_extensions : (info : Context_info) -> (exts : Extensions_array) -> IO ()
set_extensions (Make_context_info info) exts = do
  poke PTR (extensions_field info) (unwrap_extensions_array exts)

||| Set protocols in use
|||
||| @info - Result of call to connection_information
||| @prots - The protocols to use
set_protocols : (info : Context_info) -> (prots : Protocols_array) -> IO ()
set_protocols (Make_context_info info) prots = do
  poke PTR (protocols_field info) (unwrap_protocols_array prots)

||| Set plugins directory lisy
|||
||| @info - Result of call to connection_information
||| @dirs - The directories to scan
set_plugin_dirs : (info : Context_info) -> (dirs : Ptr) -> IO ()
set_plugin_dirs (Make_context_info info) dirs = do
  poke PTR (plugin_dirs_field info) dirs
  
||| Set vhosts options
|||
||| @info - Result of call to connection_information
||| @pvo  - The list of per-vhost options
set_pvo : (info : Context_info) -> (pvo : Ptr) -> IO ()
set_pvo (Make_context_info info) pvo = do
  poke PTR (pvo_field info) pvo
  
||| Set mounts for vhost
|||
||| @info   - Result of call to connection_information
||| @mounts - The mounts to use
set_mounts : (info : Context_info) -> (mounts : Ptr) -> IO ()
set_mounts (Make_context_info info) mounts = do
  poke PTR (mounts_field info) mounts
-- server options

LWS_SERVER_OPTION_REQUIRE_VALID_OPENSSL_CLIENT_CERT : Bits32
LWS_SERVER_OPTION_REQUIRE_VALID_OPENSSL_CLIENT_CERT = 4098

LWS_SERVER_OPTION_SKIP_SERVER_CANONICAL_NAME : Bits32
LWS_SERVER_OPTION_SKIP_SERVER_CANONICAL_NAME = 4

LWS_SERVER_OPTION_ALLOW_NON_SSL_ON_SSL_PORT : Bits32
LWS_SERVER_OPTION_ALLOW_NON_SSL_ON_SSL_PORT = 4104

LWS_SERVER_OPTION_LIBEV : Bits32
LWS_SERVER_OPTION_LIBEV = 16

LWS_SERVER_OPTION_DISABLE_IPV6 : Bits32
LWS_SERVER_OPTION_DISABLE_IPV6 = 32

LWS_SERVER_OPTION_DISABLE_OS_CA_CERTS : Bits32
LWS_SERVER_OPTION_DISABLE_OS_CA_CERTS = 64

LWS_SERVER_OPTION_PEER_CERT_NOT_REQUIRED : Bits32
LWS_SERVER_OPTION_PEER_CERT_NOT_REQUIRED = 128

LWS_SERVER_OPTION_VALIDATE_UTF8 : Bits32
LWS_SERVER_OPTION_VALIDATE_UTF8 = 256

LWS_SERVER_OPTION_SSL_ECDH : Bits32
LWS_SERVER_OPTION_SSL_ECDH = 4608

LWS_SERVER_OPTION_LIBUV: Bits32
LWS_SERVER_OPTION_LIBUV = 1024

LWS_SERVER_OPTION_REDIRECT_HTTP_TO_HTTPS : Bits32
LWS_SERVER_OPTION_REDIRECT_HTTP_TO_HTTPS = 6152

LWS_SERVER_OPTION_DO_SSL_GLOBAL_INIT : Bits32
LWS_SERVER_OPTION_DO_SSL_GLOBAL_INIT = 4096

LWS_SERVER_OPTION_EXPLICIT_VHOST : Bits32
LWS_SERVER_OPTION_EXPLICIT_VHOST = 8192

LWS_SERVER_OPTION_UNIX_SOC : Bits32
LWS_SERVER_OPTION_UNIX_SOC = 16384

LWS_SERVER_OPTION_STS : Bits32
LWS_SERVER_OPTION_STS = 32768

--LWS_SERVER_OPTION_SKIP_SERVER_CANONICAL_NAME
||| Set the connection options
|||
||| @info    - Result of call to connection_information
||| @options - Options to be set
set_options : (info : Context_info) -> (options : Bits32) -> IO ()
set_options (Make_context_info info) options = do
  poke I32 (options_field info) options

data Context = Make_context Ptr

unwrap_context : Context -> Ptr
unwrap_context (Make_context p) = p

wrap_context : Ptr -> Context
wrap_context p = Make_context p

||| Create the websocket handler's execution context
||| This function creates the listening socket (if serving) and takes care of all initialization in one step.
||| After initialization, it returns a struct lws_context * that represents this server. After calling, user code needs to take care of calling lws_service with the context pointer to get the server's sockets serviced. This must be done in the same process context as the initialization call.
||| The protocol callback functions are called for a handful of events including http requests coming in, websocket connections becoming established, and data arriving; it's also called periodically to allow async transmission.
||| HTTP requests are sent always to the FIRST protocol in protocol, since at that time websocket protocol has not been negotiated. Other protocols after the first one never see any HTTP callack activity.
||| The server created is a simple http server by default; part of the websocket standard is upgrading this http connection to a websocket one.
||| This allows the same server to provide files like scripts and favicon / images or whatever over http and dynamic data over websockets all in one place; they're all handled in the user callback.
|||
||| @context_creation_info - parameters needed to create the context
create_context : (context_creation_info : Context_info) -> IO Context
create_context (Make_context_info info) = do
  ptr <- foreign FFI_C "lws_create_context" (Ptr -> IO Ptr) info
  pure $ Make_context ptr

lws_context_destroy : (context : Context) -> IO ()
lws_context_destroy (Make_context context) = foreign FFI_C "lws_context_destroy" (Ptr -> IO ()) context

lws_get_context : (wsi : Wsi) -> IO Context
lws_get_context wsi = do
  ctx <-  foreign FFI_C "lws_get_context" (Ptr -> IO Ptr) (unwrap_wsi wsi)
  pure $ Make_context ctx

lws_canonical_hostname : Context -> IO String
lws_canonical_hostname ctx = do 
  str <- foreign FFI_C "lws_canonical_hostname" (Ptr -> IO Ptr) (unwrap_context ctx)
  string_from_c str

lws_rx_flow_allow_all_protocol : (ctx : Context) -> (protocols : Protocols_array) -> IO ()
lws_rx_flow_allow_all_protocol ctx prots =
  foreign FFI_C "lws_rx_flow_allow_all_protocol" (Ptr -> Ptr -> IO ()) (unwrap_context ctx) (unwrap_protocols_array prots)

lws_rx_flow_control :  (wsi : Wsi) -> (enable : Int) -> IO Int
lws_rx_flow_control wsi enable =
  foreign FFI_C "lws_rx_flow_control" (Ptr -> Int -> IO Int) (unwrap_wsi wsi) enable

lws_callback_on_writable_all_protocol : (ctx : Context) -> (array : Protocols_array) -> IO Int
lws_callback_on_writable_all_protocol ctx array =
  foreign FFI_C "lws_callback_on_writable_all_protocol" (Ptr -> Ptr -> IO Int) (unwrap_context ctx) (unwrap_protocols_array array) 
