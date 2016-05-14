# the compiler: gcc for C program
CC = gcc

# compiler flags:
CFLAGS  = -Wall -fpic

SRCS = ../test_server.c

all: $(SRCS)
	$(CC) $(CFLAGS) -c $(SRCS) $(LFLAGS) $(LIBS)

dumb.o : Dumb_increment.idr
	IDRIS_CFLAGS="-I /home/colin/dev/.cabal-sandbox/share/x86_64-linux-ghc-7.8.4/idris-0.11.1/libwebsockets" idris -p libwebsockets -p contrib -p posix Dumb_increment.idr --interface -o dumb.o

so: exports.c dumb.o test_server.o
	$(CC) $(CFLAGS) -shared exports.c test_server.o dumb.o `idris --include` `idris --link` -o libprotocol_dumb_increment.so

clean:
	$(RM) *.ibc *.so *.o *.h *~  a.out
