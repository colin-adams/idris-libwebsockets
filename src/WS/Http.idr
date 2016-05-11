||| C routines used for http handlers
module Http

import CFFI

%include C "lws.h"

string_to_c : String -> IO Ptr
string_to_c str = foreign FFI_C "string_to_c" (String -> IO Ptr) str

||| Returns True if the HTTP connection must close now, or
||| Returns False and resets connection to wait for new HTTP header / transaction if possible
export
lws_transaction_completed : (wsi : Ptr) -> IO Bool
lws_transaction_completed wsi = do
  compl <- foreign FFI_C "lws_transaction_completed" (Ptr -> IO Int) wsi
  if compl == 0 then
    pure False
  else
    pure True

||| Socket file descriptor
export
lws_get_socket_fd : (wsi : Ptr) -> IO Int
lws_get_socket_fd wsi = foreign FFI_C "lws_get_socket_fd" (Ptr -> IO Int) wsi

||| Get client address information
|||
||| @name_buffer - Buffer to take client address name
||| @rip         - Buffer to take client address IP dotted quad
export
lws_get_peer_addresses : (wsi : Ptr) -> (fd : Int) -> (name_buffer : Ptr) -> (name_len : Int) -> 
  (rip : Ptr) -> (rip_len : Int) -> IO ()
lws_get_peer_addresses wsi fd name n_len rip rip_len = foreign FFI_C "lws_get_peer_addresses"
  (Ptr -> Int -> Ptr -> Int -> Ptr -> Int -> IO ()) wsi fd name n_len rip rip_len

export
HTTP_STATUS_BAD_REQUEST : Int
HTTP_STATUS_BAD_REQUEST = 400

export 
lws_return_http_status : (wsi : Ptr) -> (status_code : Int) -> (body : String) -> IO Int
lws_return_http_status wsi status_code body = do
  case length body of
    Z => foreign FFI_C "lws_return_http_status" (Ptr -> Int -> Ptr -> IO Int) wsi status_code null
    _ => foreign FFI_C "lws_return_http_status" (Ptr -> Int -> Ptr -> IO Int) wsi status_code !(string_to_c body)


export
lws_get_child : (wsi : Ptr) -> IO Ptr
lws_get_child wsi = foreign FFI_C "lws_get_child" (Ptr -> IO Ptr) wsi
