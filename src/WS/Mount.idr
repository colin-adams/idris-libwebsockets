||| HTTP pathspace mounts
module Mount

import CFFI

%include C "lws.h"

string_to_c : String -> IO Ptr
string_to_c str = foreign FFI_C "string_to_c" (String -> IO Ptr) str

||| Format of a mount definition
|||
||| Fields are:
||| next - pointer to next mount, or null if this is the last or sole mount
||| mountpoint (String) - mountpoint in http pathspace, eg, "/"
||| origin (String) - path to be mounted, eg, "/var/www/warmcat.com"
||| def (String) - default target, eg, "index.html"
||| cgienv - pointer to an lws_protocol_vhost_options
||| extra-mimetypes
||| interpret
||| cgi_timeout
||| auth mask
||| cache_max_age
||| cache_reusable, cache_revalidate, cache_intermediaries - 1-bit fields in an I8
||| origin_protocol
||| mountpoint length
mount_structure : Composite
mount_structure = STRUCT [PTR, PTR, PTR, PTR, PTR, PTR, PTR, PTR, I32, I32, I32, I8, I8, I8]

-- Field indices into mount_structure

next_field : Ptr -> CPtr
next_field mount = (mount_structure#0) mount

mountpoint_field : Ptr -> CPtr
mountpoint_field mount = (mount_structure#1) mount

origin_field : Ptr -> CPtr
origin_field mount = (mount_structure#2) mount

default_field : Ptr -> CPtr
default_field mount = (mount_structure#3) mount

origin_protocol_field : Ptr -> CPtr
origin_protocol_field mount = (mount_structure#12) mount

mountpoint_length_field : Ptr -> CPtr
mountpoint_length_field mount = (mount_structure#13) mount

-- values for origin_protocol field:

||| HTTP protocol
export
LWSMPRO_HTTP : Bits8
LWSMPRO_HTTP = 0

||| HTTPS protocol
export
LWSMPRO_HTTPS : Bits8
LWSMPRO_HTTPS = 1

||| Directory in a filesystem
export
LWSMPRO_FILE : Bits8
LWSMPRO_FILE = 2

||| CGI protocol
export
LWSMPRO_CGI : Bits8
LWSMPRO_CGI = 3

||| Redirected (?) HTTP protocol
export
LWSMPRO_REDIR_HTTP : Bits8
LWSMPRO_REDIR_HTTP = 4

||| Redirected (?) HTTPS protocol
export
LWSMPRO_REDIR_HTTPS : Bits8
LWSMPRO_REDIR_HTTPS = 5

||| Protocol implemented by a callback
export
LWSMPRO_CALLBACK : Bits8
LWSMPRO_CALLBACK = 6


||| Allocate a mount point
export
allocate_mount : IO Ptr
allocate_mount = do
 ptr <- alloc mount_structure
 pure ptr

||| Allocate a filesystem mount point
|||
||| @next        - next mount point
||| @mount_point - e.g. "/"
||| @path        - e.g. "/var/www/html"
||| @def         - default filename if none given - e.g. "index.html"
export
allocate_filesystem_mount : (next : Ptr) -> (mount_point : String) -> (path : String) -> (def : String) -> IO Ptr
allocate_filesystem_mount next mount_point path def = do
  res <- allocate_mount
  poke PTR (next_field res) next
  str <- string_to_c mount_point
  poke PTR (mountpoint_field res) str
  str <- string_to_c path
  poke PTR (origin_field res) str
  str <- string_to_c def
  poke PTR (default_field res) str  
  poke I8 (origin_protocol_field res) LWSMPRO_FILE
  let len = toIntegerNat $ length mount_point
  let b8 = fromInteger len
  poke I8 (mountpoint_length_field res) b8
  pure res

||| Allocate a callback mount point
|||
||| @next        - next mount point
||| @mount_point - e.g. "/"
||| @callback     - Name of handler
export
allocate_callback_mount : (next : Ptr) -> (mount_point : String) -> (callback : String)  -> IO Ptr
allocate_callback_mount next mount_point callback = do
  res <- allocate_mount
  poke PTR (next_field res) next
  str <- string_to_c mount_point
  poke PTR (mountpoint_field res) str
  str <- string_to_c callback
  poke PTR (origin_field res) str
  poke I8 (origin_protocol_field res) LWSMPRO_CALLBACK
  let len = toIntegerNat $ length mount_point
  let b8 = fromInteger len
  poke I8 (mountpoint_length_field res) b8
  pure res
