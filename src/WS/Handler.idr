||| Protocol handlers (callbacks)
module Handler

%include C "lws.h"

||| Type of callback handlers
||| This callback is the way the user controls what is served. All the protocol detail is hidden and handled by the library.
||| For each connection / session there is user data allocated that is pointed to by "user". You set the size of this user data area when the library is initialized with lws_create_server.
||| You get an opportunity to initialize user data when called back with LWS_CALLBACK_ESTABLISHED reason.


|||
||| wsi    - opaque websocket instance pointer
||| reason - reason for the call
||| user   - Pointer to per-session user data allocated by library
||| inp     - Pointer used for some callback reasons
||| len    - Length set for some callback reasons
public export
Callback_handler : Type
Callback_handler = (wsi : Ptr) -> (reason : Int) -> (user : Ptr) -> (inp : Ptr) -> (len : Bits64) -> Int

-- return codes:

||| Normal return code from a Callback_handler
export
OK : Int
OK = 0

||| Failure return code from a Callback_handler
export
FAIL : Int
FAIL = 1

-- reason codes:

||| after the server completes a handshake with an incoming client. If you built the library with ssl support, inp is a pointer to the ssl struct associated with the connection or null.
export
LWS_CALLBACK_ESTABLISHED : Int
LWS_CALLBACK_ESTABLISHED = 0

||| the request client connection has been unable to complete a handshake with the remote server. If in is non-null, you can find an error string of length len where it points to.
export
LWS_CALLBACK_CLIENT_CONNECTION_ERROR : Int
LWS_CALLBACK_CLIENT_CONNECTION_ERROR = 1

||| this is the last chance for the client user code to examine the http headers and decide to reject the connection. If the content in the headers is interesting to the client (url, etc) it needs to copy it out at this point since it will be destroyed before the CLIENT_ESTABLISHED call
export
LWS_CALLBACK_CLIENT_FILTER_PRE_ESTABLISH : Int
LWS_CALLBACK_CLIENT_FILTER_PRE_ESTABLISH = 2

||| after your client connection completed a handshake with the remote server
export
LWS_CALLBACK_CLIENT_ESTABLISHED : Int
LWS_CALLBACK_CLIENT_ESTABLISHED = 3

||| when the websocket session ends
export
LWS_CALLBACK_CLOSED : Int
LWS_CALLBACK_CLOSED = 4

||| when a HTTP (non-websocket) session ends
export
LWS_CALLBACK_CLOSED_HTTP : Int
LWS_CALLBACK_CLOSED_HTTP = 5

||| data has appeared for this server endpoint from a remote client, it can be found at *inp and is len bytes long
export
LWS_CALLBACK_RECEIVE : Int
LWS_CALLBACK_RECEIVE = 6

||| if you elected to see PONG packets, they appear with this callback reason. PONG packets only exist in 04+ protocol
export
LWS_CALLBACK_RECEIVE_PONG : Int
LWS_CALLBACK_RECEIVE_PONG = 7

||| data has appeared from the server for the client connection, it can be found at *inp and is len bytes long
export
LWS_CALLBACK_CLIENT_RECEIVE : Int
LWS_CALLBACK_CLIENT_RECEIVE = 8

||| if you elected to see PONG packets, they appear with this callback reason. PONG packets only exist in 04+ protocol
export
LWS_CALLBACK_CLIENT_RECEIVE_PONG : Int
LWS_CALLBACK_CLIENT_RECEIVE_PONG = 9

||| If you call lws_callback_on_writable on a connection, you will get one of these callbacks coming when the connection socket is able to accept another write packet without blocking. If it already was able to take another packet without blocking, you'll get this callback at the next call to the service loop function. Notice that CLIENTs get LWS_CALLBACK_CLIENT_WRITEABLE and servers get LWS_CALLBACK_SERVER_WRITEABLE.
export
LWS_CALLBACK_CLIENT_WRITEABLE : Int
LWS_CALLBACK_CLIENT_WRITEABLE = 10

||| If you call lws_callback_on_writable on a connection, you will get one of these callbacks coming when the connection socket is able to accept another write packet without blocking. If it already was able to take another packet without blocking, you'll get this callback at the next call to the service loop function. Notice that CLIENTs get LWS_CALLBACK_CLIENT_WRITEABLE and servers get LWS_CALLBACK_SERVER_WRITEABLE.
export
LWS_CALLBACK_SERVER_WRITEABLE : Int
LWS_CALLBACK_SERVER_WRITEABLE = 11

||| an http request has come from a client that is not asking to upgrade the connection to a websocket one.
||| This is a chance to serve http content, for example, to send a script to the client which will then open the websockets connection. inp points to the URI path requested and lws_serve_http_file makes it very simple to send back a file to the client. Normally after sending the file you are done with the http connection, since the rest of the activity will come by websockets from the script that was delivered by http, so you will want to return 1; to close and free up the connection. That's important because it uses a slot in the total number of client connections allowed set by MAX_CLIENTS.
export
LWS_CALLBACK_HTTP : Int
LWS_CALLBACK_HTTP = 12

||| the next len bytes data from the http request body HTTP connection is now available in inp.
export
LWS_CALLBACK_HTTP_BODY : Int
LWS_CALLBACK_HTTP_BODY = 13

||| the expected amount of http request body has been delivered
export
LWS_CALLBACK_HTTP_BODY_COMPLETION : Int
LWS_CALLBACK_HTTP_BODY_COMPLETION = 14

||| a file requested to be send down http link has completed.
export
LWS_CALLBACK_HTTP_FILE_COMPLETION : Int
LWS_CALLBACK_HTTP_FILE_COMPLETION = 15

||| you can write more down the http protocol link now.
export
LWS_CALLBACK_HTTP_WRITEABLE : Int
LWS_CALLBACK_HTTP_WRITEABLE = 16

||| called when a client connects to the server at network level
||| the connection is accepted but then passed to this callback to decide whether to hang up immediately or not, based on the client IP. in contains the connection socket's descriptor. Since the client connection information is not available yet, wsi still pointing to the main server socket. Return non-zero to terminate the connection before sending or receiving anything. Because this happens immediately after the network connection from the client, there's no websocket protocol selected yet so this callback is issued only to protocol 0.
export
LWS_CALLBACK_FILTER_NETWORK_CONNECTION : Int
LWS_CALLBACK_FILTER_NETWORK_CONNECTION = 17

||| called when the request has been received and parsed from the client, but the response is not sent yet.
||| Return non-zero to disallow the connection. user is a pointer to the connection user space allocation, inp is the URI, eg, "/" In your handler you can use the public APIs lws_hdr_total_length / lws_hdr_copy to access all of the headers using the header enums lws_token_indexes from libwebsockets.h to check for and read the supported header presence and content before deciding to allow the http connection to proceed or to kill the connection.
export
LWS_CALLBACK_FILTER_HTTP_CONNECTION : Int
LWS_CALLBACK_FILTER_HTTP_CONNECTION = 18

||| A new client just had been connected, accepted, and instantiated into the pool. 
||| This callback allows setting any relevant property to it. Because this happens immediately after the instantiation of a new client, there's no websocket protocol selected yet so this callback is issued only to protocol 0. Only wsi is defined, pointing to the new client, and the return value is ignored.
LWS_CALLBACK_SERVER_NEW_CLIENT_INSTANTIATED : Int
LWS_CALLBACK_SERVER_NEW_CLIENT_INSTANTIATED = 19

||| called when the handshake has been received and parsed from the client, but the response is not sent yet. 
||| Return non-zero to disallow the connection. user is a pointer to the connection user space allocation, inp is the requested protocol name In your handler you can use the public APIs lws_hdr_total_length / lws_hdr_copy to access all of the headers using the header enums lws_token_indexes from libwebsockets.h to check for and read the supported header presence and content before deciding to allow the handshake to proceed or to kill the connection.
export
LWS_CALLBACK_FILTER_PROTOCOL_CONNECTION : Int
LWS_CALLBACK_FILTER_PROTOCOL_CONNECTION = 20

||| if configured for including OpenSSL support, this callback allows your user code to perform extra SSL_CTX_load_verify_locations or similar calls to direct OpenSSL where to find certificates the client can use to confirm the remote server identity. user is the OpenSSL SSL_CTX*
export
LWS_CALLBACK_OPENSSL_LOAD_EXTRA_CLIENT_VERIFY_CERTS : Int
LWS_CALLBACK_OPENSSL_LOAD_EXTRA_CLIENT_VERIFY_CERTS = 21

||| if configured for including OpenSSL support, this callback allows your user code to load extra certifcates into the server which allow it to verify the validity of certificates returned by clients. user is the server's OpenSSL SSL_CTX*
export
LWS_CALLBACK_OPENSSL_LOAD_EXTRA_SERVER_VERIFY_CERTS : Int
LWS_CALLBACK_OPENSSL_LOAD_EXTRA_SERVER_VERIFY_CERTS = 22

||| if the libwebsockets context was created with the option LWS_SERVER_OPTION_REQUIRE_VALID_OPENSSL_CLIENT_CERT, then this callback is generated during OpenSSL verification of the cert sent from the client.
||| It is sent to protocol[0] callback as no protocol has been negotiated on the connection yet. Notice that the libwebsockets context and wsi are both null during this callback. 
||| See http://www.openssl.org/docs/ssl/SSL_CTX_set_verify.html to understand more detail about the OpenSSL callback that generates this libwebsockets callback and the meanings of the arguments passed. In this callback, user is the x509_ctx, inp is the ssl pointer and len is preverify_ok Notice that this callback maintains libwebsocket return conventions, return 0 to mean the cert is OK or 1 to fail it. This also means that if you don't handle this callback then the default callback action of returning 0 allows the client certificates.
export
LWS_CALLBACK_OPENSSL_PERFORM_CLIENT_CERT_VERIFICATION : Int
LWS_CALLBACK_OPENSSL_PERFORM_CLIENT_CERT_VERIFICATION = 23

||| this callback happens when a client handshake is being compiled. 
||| user is NULL, inp is a char **, it's pointing to a char * which holds the next location in the header buffer where you can add headers, and len is the remaining space in the header buffer, which is typically some hundreds of bytes.
|||
||| So, to add a canned cookie, your handler code might look similar to:
||| char **p = (char **)in;
||| if (len < 100) return 1;
||| *p += sprintf(*p, "Cookie: a=b\x0d\x0a");
||| return 0;
|||
||| Notice if you add anything, you just have to take care about the CRLF on the line you added. Obviously this callback is optional, if you don't handle it everything is fine.
||| Notice the callback is coming to protocols[0] all the time, because there is no specific protocol handshook yet.
export
LWS_CALLBACK_CLIENT_APPEND_HANDSHAKE_HEADER : Int
LWS_CALLBACK_CLIENT_APPEND_HANDSHAKE_HEADER = 24

||| When the server handshake code sees that it does support a requested extension, before accepting the extension by additing to the list sent back to the client it gives this callback just to check that it's okay to use that extension. 
||| It calls back to the requested protocol and with inp being the extension name, len is 0 and user is valid. Note though at this time the ESTABLISHED callback hasn't happened yet so if you initialize user content there, user content during this callback might not be useful for anything. Notice this callback comes to protocols[0].
export
LWS_CALLBACK_CONFIRM_EXTENSION_OKAY : Int
LWS_CALLBACK_CONFIRM_EXTENSION_OKAY = 25

||| When a client connection is being prepared to start a handshake to a server, each supported extension is checked with protocols[0] callback with this reason, giving the user code a chance to suppress the claim to support that extension by returning non-zero. If unhandled, by default 0 will be returned and the extension support included in the header to the server. Notice this callback comes to protocols[0].
export
LWS_CALLBACK_CLIENT_CONFIRM_EXTENSION_SUPPORTED : Int
LWS_CALLBACK_CLIENT_CONFIRM_EXTENSION_SUPPORTED = 26

||| One-time call per protocol so it can do initial setup / allocations etc
export
LWS_CALLBACK_PROTOCOL_INIT : Int
LWS_CALLBACK_PROTOCOL_INIT = 27

||| One-time call per protocol indicating this protocol won't get used at all after this callback, the context is getting destroyed. Take the opportunity to deallocate everything that was allocated by the protocol.
LWS_CALLBACK_PROTOCOL_DESTROY : Int
LWS_CALLBACK_PROTOCOL_DESTROY = 28

||| outermost (earliest) wsi create notification
||| Always on protocol [0]
export
LWS_CALLBACK_WSI_CREATE : Int
LWS_CALLBACK_WSI_CREATE = 29

||| outermost (latest) wsi destroy notification
||| Always on protocol [0]
export
LWS_CALLBACK_WSI_DESTROY : Int
LWS_CALLBACK_WSI_DESTROY = 30

||| Undocumented
export
LWS_CALLBACK_GET_THREAD_ID : Int
LWS_CALLBACK_GET_THREAD_ID = 31

-- The next five reasons are optional and only need taking care of if you will be integrating libwebsockets sockets into an external polling array.
-- For these calls, inp points to a struct lws_pollargs that contains fd, events and prev_events members

||| libwebsocket deals with its poll loop internally, but in the case you are integrating with another server you will need to have libwebsocket sockets share a polling array with the other server. 
||| This and the other POLL_FD related callbacks let you put your specialized poll array interface code in the callback for protocol 0, the first protocol you support, usually the HTTP protocol in the serving case. This callback happens when a socket needs to be added to the polling loop
|||
||| inp points to a struct lws_pollargs; the fd member of the struct is the file descriptor, and events contains the active events.
||| If you are using the internal polling loop (the "service" callback), you can just ignore these callbacks.
export
LWS_CALLBACK_ADD_POLL_FD : Int
LWS_CALLBACK_ADD_POLL_FD = 32

||| This callback happens when a socket descriptor needs to be removed from an external polling array. 
|||
||| inp is again the struct lws_pollargs containing the fd member to be removed. If you are using the internal polling loop, you can just ignore it.
export
LWS_CALLBACK_DEL_POLL_FD : Int
LWS_CALLBACK_DEL_POLL_FD = 33

||| This callback happens when libwebsockets wants to modify the events for a connectiion.
|||
||| inp is the struct lws_pollargs with the fd to change. The new event mask is in events member and the old mask is in the prev_events member. If you are using the internal polling loop, you can just ignore it.
export
LWS_CALLBACK_CHANGE_MODE_POLL_FD : Int
LWS_CALLBACK_CHANGE_MODE_POLL_FD = 34

||| See next
export
LWS_CALLBACK_LOCK_POLL : Int
LWS_CALLBACK_LOCK_POLL = 35

||| These allow the external poll changes driven by libwebsockets to participate in an external thread locking scheme around the changes, so the whole thing is threadsafe. 
||| These are called around three activities in the library,
||| - inserting a new wsi in the wsi / fd table (len=1)
||| - deleting a wsi from the wsi / fd table (len=1) 
||| - changing a wsi's POLLIN/OUT state (len=0) 
||| Locking and unlocking external synchronization objects when len == 1 allows external threads to be synchronized against wsi lifecycle changes if it acquires the same lock for the duration of wsi dereference from the other thread context.
export
LWS_CALLBACK_UNLOCK_POLL : Int
LWS_CALLBACK_UNLOCK_POLL = 36

||| if configured for including OpenSSL support but no private key file has been specified (ssl_private_key_filepath is null), this is called to allow the user to set the private key directly via libopenssl and perform further operations if required
||| this might be useful in situations where the private key is not directly accessible by the OS, for example if it is stored on a smartcard user is the server's OpenSSL SSL_CTX*
export
LWS_CALLBACK_OPENSSL_CONTEXT_REQUIRES_PRIVATE_KEY : Int
LWS_CALLBACK_OPENSSL_CONTEXT_REQUIRES_PRIVATE_KEY = 37

||| The peer has sent an unsolicited Close WS packet.
|||
||| inp and len are the optional close code (first 2 bytes, network order) and the optional additional information which is not defined in the standard, and may be a string or non-human- readble data.
||| If you return 0 lws will echo the close and then close the connection. If you return nonzero lws will just close the connection.
export
LWS_CALLBACK_WS_PEER_INITIATED_CLOSE : Int
LWS_CALLBACK_WS_PEER_INITIATED_CLOSE = 38

||| Undocumented
export
LWS_CALLBACK_WS_EXT_DEFAULTS : Int
LWS_CALLBACK_WS_EXT_DEFAULTS = 39

||| User code can use this
export
LWS_CALLBACK_USER : Int
LWS_CALLBACK_USER = 1000
