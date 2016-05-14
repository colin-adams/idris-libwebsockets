||| Functions needed by plugins
module Plugin

import WS.Protocol

import CFFI

||| fields are:
||| api_magic
||| protocols
||| count_protocols
||| extensions
||| count_extensions
lws_plugin_capability : Composite
lws_plugin_capability = STRUCT [I32, PTR, I32, PTR, I32]

api_magic_field : Ptr -> CPtr
api_magic_field caps = (lws_plugin_capability#0) caps

protocols_field : Ptr -> CPtr
protocols_field caps = (lws_plugin_capability#1) caps

count_protocols_field : Ptr -> CPtr
count_protocols_field caps = (lws_plugin_capability#2) caps

extensions_field : Ptr -> CPtr
extensions_field caps = (lws_plugin_capability#3) caps

count_extensions_field : Ptr -> CPtr
count_extensions_field caps = (lws_plugin_capability#4) caps

export
LWS_PLUGIN_API_MAGIC : Bits32
LWS_PLUGIN_API_MAGIC = 180

export
api_magic : (capabilities : Ptr) -> IO Bits32
api_magic capabilities = do
  peek I32 (api_magic_field capabilities)

export
set_capabilities_protocols : (capabilities : Ptr) -> (protocols : Protocols_array) -> (count : Int) -> IO ()
set_capabilities_protocols capabilities protocols count = do
  poke PTR (protocols_field capabilities) (unwrap_protocols_array protocols)
  poke I32 (count_protocols_field capabilities) (prim__truncInt_B32 count)

export
set_capabilities_extensions : (capabilities : Ptr) -> (extensions : Ptr) -> (count : Int) -> IO ()
set_capabilities_extensions capabilities extensions count = do
  poke PTR (extensions_field capabilities) extensions
  poke I32 (count_extensions_field capabilities) (prim__truncInt_B32 count)
