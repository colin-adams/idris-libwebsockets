||| protocol virtual host options
module Vhost_options

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
