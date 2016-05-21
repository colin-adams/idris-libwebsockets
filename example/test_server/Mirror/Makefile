# the compiler: gcc for C program
CC = gcc

# compiler flags:
CFLAGS  = -Wall -fpic

all: exports.c mirror.o test_server.o
	$(CC) $(CFLAGS) -shared exports.c mirror.o test_server.o `idris --include` `idris --link` -o libprotocol_lws_mirror.so

test_server.o: ../test_server.c
	$(CC) $(CFLAGS) -c ../test_server.c $(LFLAGS) $(LIBS)

mirror.o : Mirror.idr
	IDRIS_CFLAGS="-I ../../../src" idris -p libwebsockets -p contrib -p posix Mirror.idr --interface -o mirror.o

clean:
	$(RM) *.ibc *.o *~ exports.h a.out

clobber: clean
	$(RM) *.so
