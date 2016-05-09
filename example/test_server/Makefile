# the compiler: gcc for C program
CC = gcc

# compiler flags:
CFLAGS  = -Wall

SRCS = test_server.c

all: $(SRCS)
	$(CC) $(CFLAGS) -c $(SRCS) $(LFLAGS) $(LIBS)

clean:
	$(RM) *.o *~  a.out
