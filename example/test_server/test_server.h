#include <stdlib.h>
#include <libwebsockets.h>

extern int close_testing_flag;

size_t LWS_PREfix (void);

void * transmission_buffer (unsigned int size);

void * transmission_buffer_start (void * buf);

void fill_buffer (char * buf, const char * text);

void close_testing (void);

void open_testing (void);

int is_close_testing (void);

void print_pointer (const char * nm, const void * ptr);

void * per_vhost_data__dumb_increment_from_timeout_watcher (uv_timer_t *tw);

void * bytes_on_from (size_t count, void * ptr);

size_t pointer_difference (void *p1, void * p2);
