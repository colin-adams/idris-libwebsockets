module Main

import WS.WebSocket
import IdrisScript

export
san : String -> String
san s = 
  if isInfixOf "<" s then
    "invalid string"
  else
    s

document_url : JS_IO String
document_url = foreign FFI_JS "document.URL" (JS_IO String)

set_browser : String -> JS_IO ()
set_browser s = foreign FFI_JS "function(){document.getElementById('brow').textContent = %0;}()" (String -> JS_IO ()) s

set_number : String -> JS_IO ()
set_number s = foreign FFI_JS "function(){document.getElementById('number').textContent = %0;}()" (String -> JS_IO ()) s

get_appropriate_ws_url : JS_IO String
get_appropriate_ws_url = do
  u <- document_url
  let pcol    = if substr 0 5 u == "https" then "wss://" else "ws://"
  let len     = length u
  let u2      = if substr 0 5 u == "https" then substr 8 len u else substr 7 len u
  let (u3, _) = span (/= '/') u2
  pure $ pcol ++ u3 ++ "/xxx" -- last bit is for IE 10 workaround

reset : WebSocket -> JS_IO ()
reset sock = jscall "function(){ console.log(\"clicking\"); var socket_di; socket_di = %0; socket_di.send(\"reset\\n\"); }" (JSRef -> JS_IO ()) (unwrap_websocket sock)

set_dumb_increment_callbacks : WebSocket -> JS_IO ()
set_dumb_increment_callbacks sock = jscall """
  (function () {
    var socket_di;
    
    socket_di = %0;
  try {
    %0.onopen = function() {
    document.getElementById("wsdi_statustd").style.backgroundColor = "#40ff40";
    document.getElementById("wsdi_status").innerHTML = " <b>websocket connection opened</b><br>" +
    san(%0.extensions);
    } 

    %0.onmessage =function got_packet(msg) {
    document.getElementById("number").textContent = msg.data + "\n";
    } 

    %0.onclose = function(){
      document.getElementById("wsdi_statustd").style.backgroundColor = "#ff4040";
      document.getElementById("wsdi_status").textContent = " websocket connection CLOSED ";
    }
  } catch(exception) {
    alert('<p>Error' + exception);  
  }}())"""
  (JSRef -> JS_IO ()) (unwrap_websocket sock)

element_by_id : String -> JS_IO JSRef
element_by_id id = jscall "document.getElementById(%0)" (String -> JS_IO JSRef) id

add_event_listener : JSRef -> String -> (JS_IO ()) -> JS_IO ()
add_event_listener target event action = do
  if target == null then
    jscall "function () {console.log(\"No target\");}()" (JS_IO ())
  else
    jscall "function () {%0.addEventListener(%1,%2);}()" (JSRef -> String -> (JsFn (JS_IO ())) -> JS_IO ()) target event (MkJsFn action)

--namespace BrowserDetect

--  ||| BrowserDetect came from http://www.quirksmode.org/js/detect.html
--  browser : String
  
namespace Main 
  main : JS_IO () 
  main = do
    -- TODO set_browser
    u <- get_appropriate_ws_url
    set_number u
    offset <- element_by_id "offset"
    (Just socket_di) <- new_websocket_with_protocol u "dumb-increment-protocol"
    jscall "console.log(Object.getPrototypeOf(%0));" (JSRef -> JS_IO ()) (unwrap_websocket socket_di)
    add_event_listener offset "click" (reset socket_di)
    set_dumb_increment_callbacks socket_di
    pure () 
 
-- the following has no effect, even with the --interface option specified:
exports : FFI_Export FFI_JS "exports.js" []
exports = Fun san "san" $ End
