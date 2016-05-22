||| Wrapping the websockets instance (wsi) Ptr
module Wsi

import CFFI

%access export

%include C "lws.h"

||| Instance of a websocket
data Wsi = Make_wsi Ptr

unwrap_wsi : Wsi -> Ptr
unwrap_wsi (Make_wsi p) = p

wrap_wsi : Ptr -> Wsi
wrap_wsi p = Make_wsi p
