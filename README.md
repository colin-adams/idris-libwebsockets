# idris-libwebsockets
An Idris wrapper around libwebsockets 2.0 (and probably later)

This requires compiling in support for lws_daemonize into the shared library. On Fedora 23 this is not done by default.
I changed the .spec file from the source rpm so that the %cmake clause reads:

%cmake -D LWS_WITHOUT_DAEMONIZE=OFF ..

then rebuilt and reinstalled the rpms. That won't suffice for plugins though.

Building from github source:

cmake -D LWS_WITHOUT_DAEMONIZE=OFF -D LWS_WITH_PLUGINS=ON -DLWS_WITH_LWSWS=1 ..

The last is only if you want to use lwsws (makes sense to do so).

To install:

idris --install ws.ipkg

To compile and run the test server:

cd example/test_server
idris --build test_server.ipkg
cd Dumb_increment
make
cd ../Mirror
make
cd ../Server_status
make
cd ../Post
make
cd ..
sudo ./test_server

Now point your web-browser to http://localhost:7681/


