#include <stdlib.h>
#include <libwebsockets.h>

extern int close_testing_flag;

void * transmission_buffer (unsigned int size);

void * transmission_buffer_start (void * buf);

void close_testing (void);

void open_testing (void);

int is_close_testing (void);



