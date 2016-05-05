# idris-libwebsockets
An Idris wrapper around libwebsockets 2.0 (and probably later)

This requires compiling in support for lws_daemonize into the shared library. On Fedora 23 this is not done by default.
I changed the .spec file from the source rpm so that the %cmake clause reads:

%cmake -D LWS_WITHOUT_DAEMONIZE=OFF ..

then rebuilt and reinstalled the rpms.

Building from github source:

cmake -D LWS_WITHOUT_DAEMONIZE=OFF -D LWS_WITH_PLUGINS=ON ..

