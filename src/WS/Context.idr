||| Functions that manipulate the libwebsockets context
module Context

import CFFI

%include C "lws.h"

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
||| 8 unused pointers follow
connection_information_struct : Composite
connection_information_struct = STRUCT [I32, PTR, PTR, PTR, PTR, PTR, PTR, PTR, PTR, PTR, PTR, I32, I32, I32, I32, PTR, I32, I32, I32, PTR, I16, I16, I32, I32, I32, PTR, PTR, PTR, PTR, PTR, PTR, PTR, PTR]

||| Access to the server's connection information
export
connection_information : IO Ptr
connection_information = foreign FFI_C "&connection_information" (IO Ptr)

-- Field indices into connection_information_struct
export
port_field : Nat
port_field = 0

||| Zero the connection information
|||
||| Call prior to create_context, or any calls to connection_information
export
clear_connection_information : IO ()
clear_connection_information = foreign FFI_C "clear_connection_information" (IO ())

||| Set the port on which to listen
|||
||| @info - Result of call to connection_information
||| @port - The port to listen on.
export
set_port : (info : Ptr) -> (port : Bits32) -> IO ()
set_port info port = do
  port_fld <- pure $ (connection_information_struct#port_field) info
  poke I32 info port

||| Create the websocket handler
||| This function creates the listening socket (if serving) and takes care of all initialization in one step.
||| After initialization, it returns a struct lws_context * that represents this server. After calling, user code needs to take care of calling lws_service with the context pointer to get the server's sockets serviced. This must be done in the same process context as the initialization call.
||| The protocol callback functions are called for a handful of events including http requests coming in, websocket connections becoming established, and data arriving; it's also called periodically to allow async transmission.
||| HTTP requests are sent always to the FIRST protocol in protocol, since at that time websocket protocol has not been negotiated. Other protocols after the first one never see any HTTP callack activity.
||| The server created is a simple http server by default; part of the websocket standard is upgrading this http connection to a websocket one.
||| This allows the same server to provide files like scripts and favicon / images or whatever over http and dynamic data over websockets all in one place; they're all handled in the user callback.
|||
||| @context_creation_info - parameters needed to create the context
export
create_context : (context_creation_info : Ptr) -> IO Ptr
create_context info = foreign FFI_C "lws_create_context" (Ptr -> IO Ptr) info
