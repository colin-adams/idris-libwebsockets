# the compiler: gcc for C program
CC = gcc

# compiler flags:
CFLAGS  = -Wall -fpic

all: exports.c post.o test_server.o
	$(CC) $(CFLAGS) -shared exports.c post.o test_server.o `idris --include` `idris --link` -o libprotocol_post_demo.so

test_server.o: ../test_server.c
	$(CC) $(CFLAGS) -c ../test_server.c $(LFLAGS) $(LIBS)

post.o : Post.idr
	IDRIS_CFLAGS="-I ../../../src" idris -p libwebsockets -p contrib -p posix Post.idr --interface -o post.o

clean:
	$(RM) *.ibc *.o *~ exports.h a.out

clobber: clean
	$(RM) *.so
