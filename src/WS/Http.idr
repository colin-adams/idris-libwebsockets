||| C routines used for http handlers
module Http

import WS.Wsi
import CFFI

%access export

%include C "lws.h"

private
string_to_c : String -> IO Ptr
string_to_c str = foreign FFI_C "string_to_c" (String -> IO Ptr) str

||| Returns True if the HTTP connection must close now, or
||| Returns False and resets connection to wait for new HTTP header / transaction if possible
lws_transaction_completed : (wsi : Wsi) -> IO Bool
lws_transaction_completed wsi = do
  compl <- foreign FFI_C "lws_transaction_completed" (Ptr -> IO Int) (unwrap_wsi wsi)
  if compl == 0 then
    pure False
  else
    pure True

||| Socket file descriptor
lws_get_socket_fd : (wsi : Wsi) -> IO Int
lws_get_socket_fd wsi = foreign FFI_C "lws_get_socket_fd" (Ptr -> IO Int) (unwrap_wsi wsi)

||| Get client address information
|||
||| @name_buffer - Buffer to take client address name
||| @rip         - Buffer to take client address IP dotted quad
lws_get_peer_addresses : (wsi : Wsi) -> (fd : Int) -> (name_buffer : Ptr) -> (name_len : Int) -> 
  (rip : Ptr) -> (rip_len : Int) -> IO ()
lws_get_peer_addresses wsi fd name n_len rip rip_len = foreign FFI_C "lws_get_peer_addresses"
  (Ptr -> Int -> Ptr -> Int -> Ptr -> Int -> IO ()) (unwrap_wsi wsi) fd name n_len rip rip_len

HTTP_STATUS_OK : Int
HTTP_STATUS_OK = 200

HTTP_STATUS_BAD_REQUEST : Int
HTTP_STATUS_BAD_REQUEST = 400

lws_return_http_status : (wsi : Wsi) -> (status_code : Int) -> (body : String) -> IO Int
lws_return_http_status wsi status_code body = do
  case length body of
    Z => foreign FFI_C "lws_return_http_status" (Ptr -> Int -> Ptr -> IO Int) (unwrap_wsi wsi) status_code null
    _ => foreign FFI_C "lws_return_http_status" (Ptr -> Int -> Ptr -> IO Int) (unwrap_wsi wsi) status_code !(string_to_c body)

lws_get_child : (wsi : Wsi) -> IO Ptr
lws_get_child wsi = foreign FFI_C "lws_get_child" (Ptr -> IO Ptr) (unwrap_wsi wsi)

||| Copy the whole, aggregated @hdr to @dest
|||
||| @hdr - header to copy
lws_hdr_copy :  (wsi : Wsi) -> (dest : Ptr) -> (len : Int) -> (hdr : Int) -> IO Int
lws_hdr_copy wsi dest len hdr =
  foreign FFI_C "lws_hdr_copy" (Ptr -> Ptr -> Int -> Int -> IO Int) (unwrap_wsi wsi) dest len hdr

WSI_TOKEN_GET_URI : Int
WSI_TOKEN_GET_URI =  0
  
WSI_TOKEN_POST_URI : Int
WSI_TOKEN_POST_URI =  1  

WSI_TOKEN_OPTIONS_URI : Int
WSI_TOKEN_OPTIONS_URI = 2
  
WSI_TOKEN_HOST : Int
WSI_TOKEN_HOST =  3 
   
WSI_TOKEN_CONNECTION : Int
WSI_TOKEN_CONNECTION =  4
    
WSI_TOKEN_UPGRADE : Int
WSI_TOKEN_UPGRADE =  5

WSI_TOKEN_HTTP_CONTENT_TYPE : Int
WSI_TOKEN_HTTP_CONTENT_TYPE = 28

WSI_TOKEN_HTTP_USER_AGENT : Int
WSI_TOKEN_HTTP_USER_AGENT = 69  

  {- TODO
  		WSI_TOKEN_ORIGIN					=  6
	WSI_TOKEN_DRAFT						=  7
	WSI_TOKEN_CHALLENGE					=  8
	WSI_TOKEN_EXTENSIONS					=  9
	WSI_TOKEN_KEY1						= 10
	WSI_TOKEN_KEY2						= 11
	WSI_TOKEN_PROTOCOL					= 12
	WSI_TOKEN_ACCEPT					= 13
	WSI_TOKEN_NONCE						= 14
	WSI_TOKEN_HTTP						= 15
	WSI_TOKEN_HTTP2_SETTINGS				= 16
	WSI_TOKEN_HTTP_ACCEPT					= 17
	WSI_TOKEN_HTTP_AC_REQUEST_HEADERS			= 18
	WSI_TOKEN_HTTP_IF_MODIFIED_SINCE			= 19
	WSI_TOKEN_HTTP_IF_NONE_MATCH				= 20
	WSI_TOKEN_HTTP_ACCEPT_ENCODING				= 21
	WSI_TOKEN_HTTP_ACCEPT_LANGUAGE				= 22
	WSI_TOKEN_HTTP_PRAGMA					= 23
	WSI_TOKEN_HTTP_CACHE_CONTROL				= 24
	WSI_TOKEN_HTTP_AUTHORIZATION				= 25
	WSI_TOKEN_HTTP_COOKIE					= 26
	WSI_TOKEN_HTTP_CONTENT_LENGTH				= 27
	
	WSI_TOKEN_HTTP_DATE					= 29
	WSI_TOKEN_HTTP_RANGE					= 30
	WSI_TOKEN_HTTP_REFERER					= 31
	WSI_TOKEN_KEY						= 32
	WSI_TOKEN_VERSION					= 33
	WSI_TOKEN_SWORIGIN					= 34
	WSI_TOKEN_HTTP_COLON_AUTHORITY				= 35
	WSI_TOKEN_HTTP_COLON_METHOD				= 36
	WSI_TOKEN_HTTP_COLON_PATH				= 37
	WSI_TOKEN_HTTP_COLON_SCHEME				= 38
	WSI_TOKEN_HTTP_COLON_STATUS				= 39
	WSI_TOKEN_HTTP_ACCEPT_CHARSET				= 40
	WSI_TOKEN_HTTP_ACCEPT_RANGES				= 41
	WSI_TOKEN_HTTP_ACCESS_CONTROL_ALLOW_ORIGIN		= 42
	WSI_TOKEN_HTTP_AGE					= 43
	WSI_TOKEN_HTTP_ALLOW					= 44
	WSI_TOKEN_HTTP_CONTENT_DISPOSITION			= 45
	WSI_TOKEN_HTTP_CONTENT_ENCODING				= 46
	WSI_TOKEN_HTTP_CONTENT_LANGUAGE				= 47
	WSI_TOKEN_HTTP_CONTENT_LOCATION				= 48
	WSI_TOKEN_HTTP_CONTENT_RANGE				= 49
	WSI_TOKEN_HTTP_ETAG					= 50
	WSI_TOKEN_HTTP_EXPECT					= 51
	WSI_TOKEN_HTTP_EXPIRES					= 52
	WSI_TOKEN_HTTP_FROM					= 53
	WSI_TOKEN_HTTP_IF_MATCH					= 54
	WSI_TOKEN_HTTP_IF_RANGE					= 55
	WSI_TOKEN_HTTP_IF_UNMODIFIED_SINCE			= 56
	WSI_TOKEN_HTTP_LAST_MODIFIED				= 57
	WSI_TOKEN_HTTP_LINK					= 58
	WSI_TOKEN_HTTP_LOCATION					= 59
	WSI_TOKEN_HTTP_MAX_FORWARDS				= 60
	WSI_TOKEN_HTTP_PROXY_AUTHENTICATE			= 61
	WSI_TOKEN_HTTP_PROXY_AUTHORIZATION			= 62
	WSI_TOKEN_HTTP_REFRESH					= 63
	WSI_TOKEN_HTTP_RETRY_AFTER				= 64
	WSI_TOKEN_HTTP_SERVER					= 65
	WSI_TOKEN_HTTP_SET_COOKIE				= 66
	WSI_TOKEN_HTTP_STRICT_TRANSPORT_SECURITY		= 67
	WSI_TOKEN_HTTP_TRANSFER_ENCODING			= 68

	WSI_TOKEN_HTTP_VARY					= 70
	WSI_TOKEN_HTTP_VIA					= 71
	WSI_TOKEN_HTTP_WWW_AUTHENTICATE				= 72
	WSI_TOKEN_PATCH_URI					= 73
	WSI_TOKEN_PUT_URI					= 74
	WSI_TOKEN_DELETE_URI					= 75
	WSI_TOKEN_HTTP_URI_ARGS					= 76
	WSI_TOKEN_PROXY						= 77
	WSI_TOKEN_HTTP_X_REAL_IP				= 78
	WSI_TOKEN_HTTP1_0					= 79

-}

lws_http_transaction_completed : (wsi : Wsi) -> IO Int
lws_http_transaction_completed wsi = foreign FFI_C "lws_http_transaction_completed" (Ptr -> IO Int) (unwrap_wsi wsi)

||| Undocumented
|||
||| @code - HTTP status code
||| @p    - pointer to pointer of bytes
||| @end  - pointer to bytes
lws_add_http_header_status : (wsi : Wsi) -> (code : Int) -> (p : Ptr) -> (end : Ptr) -> IO Int
lws_add_http_header_status wsi code p end = 
  foreign FFI_C "lws_add_http_header_status" (Ptr -> Int -> Ptr -> Ptr -> IO Int) (unwrap_wsi wsi) code p end

lws_add_http_header_by_token : (wsi : Wsi) -> (token : Int) -> (value : Ptr) -> (len : Int) ->
  (p : Ptr) -> (end : Ptr) -> IO Int
lws_add_http_header_by_token wsi token value len p end =
  foreign FFI_C "lws_add_http_header_by_token" (Ptr -> Int -> Ptr -> Int -> Ptr -> Ptr -> IO Int)
    (unwrap_wsi wsi) token value len p end

lws_add_http_header_content_length : (wsi : Wsi) -> (content_len : Bits64) ->
  (p : Ptr) -> (end : Ptr) -> IO Int
lws_add_http_header_content_length wsi content_len p end = 
  foreign FFI_C "lws_add_http_header_content_length" (Ptr -> Bits64 -> Ptr -> Ptr -> IO Int)
    (unwrap_wsi wsi) content_len p end
    
lws_finalize_http_header : (wsi : Wsi) -> (p : Ptr) -> (end : Ptr) -> IO Int
lws_finalize_http_header wsi p end = 
foreign FFI_C "lws_finalize_http_header" (Ptr -> Ptr -> Ptr -> IO Int) (unwrap_wsi wsi) p end
