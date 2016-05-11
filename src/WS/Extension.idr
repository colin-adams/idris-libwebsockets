||| Extensions to libwebsockets
module Extension

import Data.Fin
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

extensions_array : Int -> Composite
extensions_array n = ARRAY n extension_structure

-- Field indices into extension_structure

name_field : Ptr -> CPtr
name_field exts = (extension_structure#0) exts

callback_field : Ptr -> CPtr
callback_field exts = (extension_structure#1) exts

client_offer_field : Ptr -> CPtr
client_offer_field exts = (extension_structure#2) exts

export
data Extensions_array = Make_extensions_array Ptr

export
unwrap_extensions_array : Extensions_array -> Ptr
unwrap_extensions_array (Make_extensions_array p) = p

||| Allocate the extensions array for @count + 1 structures
||| (the additional 1 is the null terminator)
|||
||| @count - how many extensions we shall support?
export
allocate_extensions_array : (count : Int) -> IO Extensions_array
allocate_extensions_array count = do
  cpt <- alloc (ARRAY (count + 1) extension_structure)
  pure $ Make_extensions_array $ toPtr cpt

export 
data Extension = Make_extension Ptr

export
unwrap_extension : Extension -> Ptr
unwrap_extension (Make_extension p) = p

||| Built-in extension 
export
lws_extension_callback_deflate_pm : IO Extension
lws_extension_callback_deflate_pm = do
  ptr <- foreign FFI_C "pm_deflate" (IO Ptr) 
  pure $ Make_extension ptr
  
||| Fill in pre-allocated extensions array with an Idris-written extension
|||
||| @array        - Extensions array to be filled
||| @size         - size of @array
||| @slot         - Extension number to fill
||| @name         - Formal name of extension
||| @callback     - Wrapper around a service callback which implement the extension
||| @client_offer - String containing extensions and options client offers
export
add_extension : (array : Extensions_array) -> (size : Nat) -> (slot : Fin size) -> (name : String) -> (callback : IO Extension) ->
  (client_offer : String) -> IO ()
add_extension (Make_extensions_array array) size slot name callback offer = do
  struct <- pure $ ((extensions_array $ toIntNat size)#(finToNat slot)) array
  str <- string_to_c name
  poke PTR (name_field struct) str
  (Make_extension cb) <- callback
  poke PTR (callback_field struct) cb
  str <- string_to_c offer
  poke PTR (client_offer_field struct) str

