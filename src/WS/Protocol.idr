||| Protocols and handlers supported by the server
||| This is not needed when using the libwebsockets 2.0 plugins, as the test_server example now does.
module Protocol

import WS.Handler
import CFFI

%include C "lws.h"

string_from_c : Ptr -> IO String
string_from_c str = foreign FFI_C "make_string" (Ptr -> IO String) str

string_to_c : String -> IO Ptr
string_to_c str = foreign FFI_C "string_to_c" (String -> IO Ptr) str

||| This structure represents one protocol supported by the server. An array of these structures is passed to lws_create_server allows as many protocols as you like to be handled by one server.
||| The first protocol given has its callback used for user callbacks when there is no agreed protocol name, that's true during HTTP part of the connection and true if the client did not send a Protocol header.
|||
||| Fields:
||| name - String - Protocol name that must match the one given in the client Javascript new WebSocket(url, 'protocol') name.
||| callback - The service callback used for this protocol. It allows the service action for an entire protocol to be encapsulated in the protocol-specific callback
||| per_session_data_size - Each new connection using this protocol gets this much memory allocated on connection establishment and freed on connection takedown. A pointer to this per-connection allocation is passed into the callback in the 'user' parameter
||| rx_buffer_size - if you want atomic frames delivered to the callback, you should set this to the size of the biggest legal frame that you support. If the frame size is exceeded, there is no error, but the buffer will spill to the user callback when full, which you can detect by using lws_remaining_packet_payload. Notice that you just talk about frame size here, the LWS_PRE and post-padding are automatically also allocated on top.
||| id - ignored by lws, but useful to contain user information bound to the selected protocol. For example if this protocol was called "myprotocol-v2", you might set id to 2, and the user code that acts differently according to the version can do so by switch (wsi->protocol->id), user code might use some bits as capability flags based on selected protocol version, etc.
||| user - User provided context data at the protocol level. Accessible via lws_get_protocol(wsi)->user This should not be confused with wsi->user, it is not the same. The library completely ignores any value in here.
protocols_structure : Composite
protocols_structure = STRUCT [PTR, PTR, I64, I64, I32, PTR]

-- Field indices into protocols_structure

name_field : Ptr -> CPtr
name_field prots = (protocols_structure#0) prots

callback_field : Ptr -> CPtr
callback_field prots = (protocols_structure#1) prots

per_session_data_size_field : Ptr -> CPtr
per_session_data_size_field prots = (protocols_structure#2) prots

rx_buffer_size_field : Ptr -> CPtr
rx_buffer_size_field prots = (protocols_structure#3) prots

id_field : Ptr -> CPtr
id_field prots = (protocols_structure#4) prots

user_field : Ptr -> CPtr
user_field prots = (protocols_structure#5) prots

||| Protocol name
|||
||| @protocol - pointer to a protocols_structure
export
protocol_name : (protocol : Ptr) -> IO String
protocol_name protocol = do
  str <- peek PTR (name_field protocol)
  string_from_c str
  
||| Protocol's service callback
|||
||| @protocol - pointer to a protocols_structure
export
protocol_callback : (protocol : Ptr) -> IO Ptr
protocol_callback protocol =
  peek PTR (callback_field protocol)
  
||| Protocol's per_session_data_size
|||
||| @protocol - pointer to a protocols_structure
export
protocol_per_session_data_size : (protocol : Ptr) -> IO Bits64
protocol_per_session_data_size protocol =
  peek I64 (per_session_data_size_field protocol)

||| Protocol's rx_buffer_size
|||
||| @protocol - pointer to a protocols_structure
export
protocol_rx_buffer_size : (protocol : Ptr) -> IO Bits64
protocol_rx_buffer_size protocol =
  peek I64 (rx_buffer_size_field protocol)

||| Protocol's id
|||
||| @protocol - pointer to a protocols_structure
export
protocol_id : (protocol : Ptr) -> IO Bits32
protocol_id protocol =
  peek I32 (id_field protocol)

||| Protocol's user data
|||
||| @protocol - pointer to a protocols_structure
export
protocol_user_data : (protocol : Ptr) -> IO Ptr
protocol_user_data protocol =
  peek PTR (user_field protocol)

||| Set protocol's name
|||
||| @name     - name to set
||| @protocol - pointer to a protocols_structure
export
set_protocol_name : (name: String) -> (protocol : Ptr) -> IO ()
set_protocol_name name protocol = do
  str <- string_to_c name
  poke PTR (name_field protocol) str

||| Set protocol's service callback
|||
||| @callback - C wrapper for an Idris service callback
||| @protocol - pointer to a protocols_structure
export
set_protocol_callback : (callback : Ptr) -> (protocol : Ptr) -> IO ()
set_protocol_callback callback protocol =
  poke PTR (callback_field protocol) callback
  
||| Set protocol's per_session_data_size
|||
||| @size     - size to set
||| @protocol - pointer to a protocols_structure
export
set_protocol_per_session_data_size : (size : Bits64) -> (protocol : Ptr) -> IO ()
set_protocol_per_session_data_size size protocol =
  poke I64 (per_session_data_size_field protocol) size

||| Set protocol's rx_buffer_size
|||
||| @size     - size to set
||| @protocol - pointer to a protocols_structure
export
set_protocol_rx_buffer_size : (size : Bits64) -> (protocol : Ptr) -> IO ()
set_protocol_rx_buffer_size size protocol =
  poke I64 (rx_buffer_size_field protocol) size

||| Set protocol's id
|||
||| @id       - id to set
||| @protocol - pointer to a protocols_structure
export
set_protocol_id : (id : Bits32) -> (protocol : Ptr) -> IO ()
set_protocol_id id protocol =
  poke I32 (id_field protocol) id

||| Set protocol's user data
|||
||| @user     - pointer to user data to be set
||| @protocol - pointer to a protocols_structure
export
set_protocol_user_data : (user : Ptr) -> (protocol : Ptr) -> IO ()
set_protocol_user_data user protocol =
  poke PTR (user_field protocol) user

||| Allocate the protocols array for @count + 1 structures
||| (the additional 1 is the null terminator)
|||
||| @count - how many protocols we shall support (including http)
export
allocate_protocols_array : (count : Int) -> IO Ptr
allocate_protocols_array count = do
  cpt <- alloc (ARRAY (count + 1) protocols_structure)
  pure $ toPtr cpt

||| Fill in pre-allocated protocols array with a protocol
|||
||| @array       - protocols array to be filled
||| @slot        - Protocol number to fill - this had better be in range
||| @name        - name of protocol to be handled
||| @handler     - Wrapper around a Callback_handler to handle protocol
||| @data_size   - per-session data size
||| @buffer_size - rx buffer size
||| @id          - protocol-specific identifier
||| @user        - user-provided content data
export
add_protocol_handler : (array : Ptr) -> (slot : Nat) -> (name : String) -> (handler : IO Ptr) ->
  (data_size : Bits64) ->  (buffer_size : Bits64) -> (id : Bits32) -> (user : Ptr) -> IO ()
add_protocol_handler array slot name handler data_size buffer_size id user = do
  struct <- pure $ (protocols_structure#slot) array
  str <- string_to_c name
  poke PTR (name_field struct) str
  poke PTR (callback_field struct) !handler
  poke I64 (per_session_data_size_field struct) data_size
  poke I64 (rx_buffer_size_field struct) buffer_size
  poke I32 (id_field struct) id
  poke PTR (user_field struct) user
