# idris-libwebsockets
An Idris wrapper around libwebsockets

This requires compiling in support for lws_daemonize into the shared library. On Fedora 23 this is not done by default.
I changed the .spec file from the source rpm so that the %cmake clause reads:

%cmake -D LWS_WITHOUT_DAEMONIZE=OFF ..

then rebuilt and reinstalled the rpms.