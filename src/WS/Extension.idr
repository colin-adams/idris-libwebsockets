||| Extensions to libwebsockets
module Extension

import CFFI

%include C "lws.h"

string_to_c : String -> IO Ptr
string_to_c str = foreign FFI_C "string_to_c" (String -> IO Ptr) str

||| Format of an extension definition
|||
||| Fields are:
||| name (String) - Formal name of the extension
||| callback - the callback function that implements the service
||| client offer - String containing exts and options client offers
extension_structure : Composite
extension_structure = STRUCT [PTR, PTR, PTR]

-- Field indices into extension_structure

name_field : Ptr -> CPtr
name_field exts = (extension_structure#0) exts

callback_field : Ptr -> CPtr
callback_field exts = (extension_structure#1) exts

client_offer_field : Ptr -> CPtr
client_offer_field exts = (extension_structure#2) exts


||| Allocate the extensions array for @count + 1 structures
||| (the additional 1 is the null terminator)
|||
||| @count - how many extensions we shall support?
export
allocate_extensions_array : (count : Int) -> IO Ptr
allocate_extensions_array count = do
  cpt <- alloc (ARRAY (count + 1) extension_structure)
  pure $ toPtr cpt

||| Built-in extension 
export
lws_extension_callback_deflate_pm : IO Ptr
lws_extension_callback_deflate_pm = foreign FFI_C "pm_deflate" (IO Ptr) 
  
||| Fill in pre-allocated extensions array with an Idris-written extension
||| (not sure if this is possible yet)
|||
||| @array        - Extensions array to be filled
||| @slot         - Extension number to fill - this had better be in range
||| @name         - Formal name of extension
||| @callback     - Wrapper around a service callback which implement the extension
||| @client_offer - String containing extensions and options client offers
export
add_extension : (array : Ptr) -> (slot : Nat) -> (name : String) -> (callback : IO Ptr) ->
  (client_offer : String) -> IO ()
add_extension array slot name callback offer = do
  struct <- pure $ (extension_structure#slot) array
  str <- string_to_c name
  poke PTR (name_field struct) str
  poke PTR (callback_field struct) !callback
  str <- string_to_c offer
  poke PTR (client_offer_field struct) str

