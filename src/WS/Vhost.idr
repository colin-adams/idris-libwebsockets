||| Virtual host functions and protocol options
module Vhost

import WS.Wsi
import WS.Protocol
import CFFI

%include C "lws.h"

string_to_c : String -> IO Ptr
string_to_c str = foreign FFI_C "string_to_c" (String -> IO Ptr) str

||| Format of a protocol vhost options definition
|||
||| Fields are:
||| next - pointer to next vhost options definition
||| options - pointer to (? plugin-per-vhost options)
||| name (String) - protocol name
||| value (String) - ?
pvo_structure : Composite
pvo_structure = STRUCT [PTR, PTR, PTR, PTR]

-- Field indices into pvo_structure

next_field : Ptr -> CPtr
next_field pvo = (pvo_structure#0) pvo

options_field : Ptr -> CPtr
options_field pvo = (pvo_structure#1) pvo

name_field : Ptr -> CPtr
name_field pvo = (pvo_structure#2) pvo

value_field : Ptr -> CPtr
value_field pvo = (pvo_structure#3) pvo

||| Allocate pvo memory
alloc_pvo : IO Ptr
alloc_pvo = do
 ptr <- alloc pvo_structure
 pure ptr

||| Allocate a pvo
|||
||| @next    - next pvo
||| @options - another pvo (?)
||| @name    - protocol name
||| @value   - ?
export
allocate_pvo : (next : Ptr) -> (options : Ptr) -> (name : String) -> (value : String) -> IO Ptr
allocate_pvo next options name value = do
  res <- alloc_pvo
  poke PTR (next_field res) next
  poke PTR (options_field res) options
  str <- string_to_c name
  poke PTR (name_field res) str
  str <- string_to_c value
  poke PTR (value_field res) str
  pure res

export
data Vhost = Make_vhost Ptr

export
unwrap_vhost : Vhost -> Ptr
unwrap_vhost (Make_vhost p) = p

export
lws_get_vhost : (wsi : Wsi) -> IO Vhost
lws_get_vhost wsi = do
  vh <- foreign FFI_C "lws_get_vhost" (Ptr -> IO Ptr) (unwrap_wsi wsi)
  pure $ Make_vhost vh

||| Allocate protocol virtual-host private data for @protocols in @vhost
||| allocate the vh private data array only on demand
|||
||| @vhost     - the virtual host concerned
||| @protocols - the protocols array that we are interested in
||| @size      - size of private data
export
lws_protocol_vh_priv_zalloc : (vhost : Vhost) -> (protocols : Protocols_array) -> (size : Int) -> IO Ptr
lws_protocol_vh_priv_zalloc vhost protocols size = 
  foreign FFI_C "lws_protocol_vh_priv_zalloc" (Ptr -> Ptr -> Int -> IO Ptr) (unwrap_vhost vhost) (unwrap_protocols_array protocols) size

||| protocol virtual-host private data for @protocols in @vhost
|||
||| @vhost     - the virtual host concerned
||| @protocols - the protocols array that we are interested in
export
lws_protocol_vh_priv_get : (vhost : Vhost) -> (protocols : Protocols_array) -> IO Ptr
lws_protocol_vh_priv_get vhost protocols =
  foreign FFI_C "lws_protocol_vh_priv_get" (Ptr -> Ptr -> IO Ptr) (unwrap_vhost vhost) (unwrap_protocols_array protocols)

export 
lws_callback_on_writable_all_protocol_vhost : Ptr -> Ptr -> IO Int
lws_callback_on_writable_all_protocol_vhost vh prots =
  foreign FFI_C "lws_callback_on_writable_all_protocol_vhost" (Ptr -> Ptr -> IO Int) vh prots
