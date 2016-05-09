||| Sending data with the websockets protocols
module Write

import CFFI

%access export

%include C "lws.h"

|||  Set reason and aux data to send with Close packet
|||  If you are going to return nonzero from the callback
|||		requesting the connection to close, you can optionally
|||		call this to set the reason the peer will be told if possible.
|||
||| @wsi:	The websocket connection to set the close reason on
||| @status:	A valid close status from websocket standard
||| @buf:	Null or buffer containing up to 124 bytes of auxiliary data
||| @len:	Length of data in @buf to send
lws_close_reason : (wsi : Ptr) -> (status : Bits16) -> (buf : Ptr) -> (len : Bits64) -> IO ()
lws_close_reason wsi status buf len = foreign FFI_C "lws_close_reason" (Ptr -> Bits16 -> Ptr -> Bits64 -> IO ()) wsi status buf len

-- Close reasons follow

LWS_CLOSE_STATUS_NOSTATUS : Bits16
LWS_CLOSE_STATUS_NOSTATUS = 0

LWS_CLOSE_STATUS_NORMAL : Bits16
LWS_CLOSE_STATUS_NORMAL = 1000

LWS_CLOSE_STATUS_GOINGAWAY : Bits16
LWS_CLOSE_STATUS_GOINGAWAY = 1001

LWS_CLOSE_STATUS_PROTOCOL_ERR : Bits16
LWS_CLOSE_STATUS_PROTOCOL_ERR = 1002

LWS_CLOSE_STATUS_UNACCEPTABLE_OPCODE : Bits16
LWS_CLOSE_STATUS_UNACCEPTABLE_OPCODE = 1003

LWS_CLOSE_STATUS_RESERVED : Bits16
LWS_CLOSE_STATUS_RESERVED = 1004

LWS_CLOSE_STATUS_NO_STATUS : Bits16
LWS_CLOSE_STATUS_NO_STATUS = 1005

LWS_CLOSE_STATUS_ABNORMAL_CLOSE	: Bits16
LWS_CLOSE_STATUS_ABNORMAL_CLOSE	= 1006

LWS_CLOSE_STATUS_INVALID_PAYLOAD : Bits16
LWS_CLOSE_STATUS_INVALID_PAYLOAD = 1007

LWS_CLOSE_STATUS_POLICY_VIOLATION : Bits16
LWS_CLOSE_STATUS_POLICY_VIOLATION = 1008

LWS_CLOSE_STATUS_MESSAGE_TOO_LARGE : Bits16
LWS_CLOSE_STATUS_MESSAGE_TOO_LARGE = 1009

LWS_CLOSE_STATUS_EXTENSION_REQUIRED : Bits16
LWS_CLOSE_STATUS_EXTENSION_REQUIRED = 1010

LWS_CLOSE_STATUS_UNEXPECTED_CONDITION : Bits16
LWS_CLOSE_STATUS_UNEXPECTED_CONDITION = 1011

LWS_CLOSE_STATUS_TLS_FAILURE : Bits16
LWS_CLOSE_STATUS_TLS_FAILURE = 1015

LWS_CLOSE_STATUS_NOSTATUS_CONTEXT_DESTROY : Bits16
LWS_CLOSE_STATUS_NOSTATUS_CONTEXT_DESTROY = 9999

||| Write @len bytes of data from @buf over @wsi using @protocol
|||
||| @wsi      - The websocket connection to write to
||| @buf      - The data to write (must be preceded by LWS_PRE bytes
||| @len      - Number of bytes to write
||| @protocol - How the data is interpreted
||| Return value is the number of bytes written
lws_write : (wsi : Ptr) -> (buf : Ptr) -> (len : Bits64) -> (protocol : Bits8) -> IO Int
lws_write wsi buf len protocol = foreign FFI_C "lws_write" (Ptr -> Ptr -> Bits64 -> Bits8 -> IO Int) wsi buf len protocol

-- Values for protocol follow

LWS_WRITE_TEXT : Bits8
LWS_WRITE_TEXT = 0

LWS_WRITE_BINARY : Bits8
LWS_WRITE_BINARY = 1

LWS_WRITE_CONTINUATION : Bits8
LWS_WRITE_CONTINUATION = 2

LWS_WRITE_HTTP : Bits8
LWS_WRITE_HTTP = 3

-- LWS_WRITE_CLOSE = 4 is done via lws_close_reason

LWS_WRITE_PING : Bits8
LWS_WRITE_PING = 5

LWS_WRITE_PONG : Bits8
LWS_WRITE_PONG = 6


||| Same as LWS_WRITE_HTTP, but we know this write ends the transmission
LWS_WRITE_HTTP_FINAL : Bits8
LWS_WRITE_HTTP_FINAL = 7

|||A For HTTP 2
LWS_WRITE_HTTP_HEADERS : Bits8
LWS_WRITE_HTTP_HEADERS = 8

||| Flag
LWS_WRITE_NO_FIN : Bits8
LWS_WRITE_NO_FIN = 0x40

||| Flag
||| client packet payload goes out on wire unmunged
||| only useful for security tests since normal servers cannot
||| decode the content if used
LWS_WRITE_CLIENT_IGNORE_XOR_MASK : Bits8
LWS_WRITE_CLIENT_IGNORE_XOR_MASK = 0x80
