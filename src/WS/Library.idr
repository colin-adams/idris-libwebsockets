||| General information about the library
module Library

export
lws_get_library_version : IO String
lws_get_library_version = foreign FFI_C "lws_get_library_version" (IO String)
