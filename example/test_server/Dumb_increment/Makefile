# the compiler: gcc for C program
CC = gcc

# compiler flags:
CFLAGS  = -Wall -fpic

SRCS = ../test_server.c

all: exports.c dumb.o test_server.o
	$(CC) $(CFLAGS) -shared exports.c test_server.o dumb.o `idris --include` `idris --link` -o libprotocol_dumb_increment.so

test_server.o: $(SRCS)
	$(CC) $(CFLAGS) -c $(SRCS) $(LFLAGS) $(LIBS)

dumb.o : Dumb_increment.idr
	IDRIS_CFLAGS="-I ../../../src" idris -p libwebsockets -p contrib -p posix Dumb_increment.idr --interface -o dumb.o

clean:
	$(RM) *.ibc *.so *.o *.h *~  a.out
