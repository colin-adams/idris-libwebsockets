||| Wrapper around JavaScript WebSocket interface
module WS.WebSocket

import IdrisScript.Arrays
import IdrisScript

%access export

data WebSocket = Make_WebSocket JSRef

wrap_websocket : JSRef -> WebSocket
wrap_websocket p = Make_WebSocket p

unwrap_websocket : WebSocket -> JSRef
unwrap_websocket (Make_WebSocket p) = p

as_object : WebSocket -> JSValue (JSObject "WebSocket")
as_object ws =
  let p = unwrap_websocket ws
  in MkJSObject p

||| Create a new websocket for @url
||| Retuns Nothing if the port to which the connection is being attempted is being blocked.
|||
||| @url - The URL to which to connect; this should be the URL to which the WebSocket server will respond.
new_websocket : (url : String) -> JS_IO (Maybe WebSocket)
new_websocket url = do
  ws <- jscall "new WebSocket(%0)" (String -> JS_IO JSRef) url
  if ws == null then
    pure Nothing
  else
    pure $ Just $ Make_WebSocket ws

||| Create a new websocket for @url with protocol @protocol
||| Retuns Nothing if the port to which the connection is being attempted is being blocked.
|||
||| @url      - The URL to which to connect; this should be the URL to which the WebSocket server will respond.
||| @protocol - The websocket sub-protocol to be used
new_websocket_with_protocol : (url : String) -> (protocol : String) -> JS_IO (Maybe WebSocket)
new_websocket_with_protocol url prot = do
  ws <- jscall "new WebSocket(%0,%1)" (String -> String -> JS_IO JSRef) url prot
  if ws == null then
    pure Nothing
  else
    pure $ Just $ Make_WebSocket ws
    
{-
When checking argument fty to function IdrisScript.jscall:
             Can't find a value of type 
                     FTy FFI_JS
                         []
                         (String -> JSValue (JSObject "Array") -> JS_IO Ptr)

||| Create a new websocket for @url with possible protocols @protocols
||| Retuns Nothing if the port to which the connection is being attempted is being blocked.
|||
||| @url      - The URL to which to connect; this should be the URL to which the WebSocket server will respond.
||| @protocols - The websocket sub-protocols to be used
new_websocket_with_protocols : (Traversable f) => (url : String) -> (protocols : f String) -> JS_IO (Maybe WebSocket)
new_websocket_with_protocols url prots = do
  ps <- toJSArray {to=JSString} prots
  ws <- jscall "new WebSocket(%0,%1)" (String -> JSValue JSArray -> JS_IO Ptr) url ps
  if ws == null then
    pure Nothing
  else
    pure $ Just $ Make_WebSocket ws
-}
