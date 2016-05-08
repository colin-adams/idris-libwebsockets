||| Functions supporting a libwebsockets service
module Service

%default total

%include C "lws.h"

||| Cancel servicing of pending websocket activity
|||
||| @context - 
export
lws_cancel_service : (context : Ptr) -> IO ()
lws_cancel_service context = foreign FFI_C "lws_cancel_service" (Ptr -> IO ()) context
