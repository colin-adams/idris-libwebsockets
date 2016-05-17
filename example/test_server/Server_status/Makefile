# the compiler: gcc for C program
CC = gcc

# compiler flags:
CFLAGS  = -Wall -fpic

all: exports.c status.o test_server.o lws_status.o
	$(CC) $(CFLAGS) -shared exports.c test_server.o lws_status.o status.o `idris --include` `idris --link` -o libprotocol_lws_status.so

test_server.o: ../test_server.c
	$(CC) $(CFLAGS) -c ../test_server.c $(LFLAGS) $(LIBS)

lws_status.o: lws_status.c
	$(CC) $(CFLAGS) -c lws_status.c $(LFLAGS) $(LIBS)

status.o : Server_status.idr
	IDRIS_CFLAGS="-I ../../../src" idris -p libwebsockets -p contrib -p posix Server_status.idr --interface -o status.o

clean:
	$(RM) *.ibc *.so *.o *~  a.out
