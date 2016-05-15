#include "test_server.h"

int close_testing_flag;

void * transmission_buffer (unsigned int size)
{
  //printf ("LWS_PRE is %d\n", LWS_PRE);
  return calloc(1, LWS_PRE + size);
}

void * transmission_buffer_start (void * buf)
{
  //printf ("LWS_PRE is %d, buffer address is %p, writing address is %p\n", LWS_PRE, buf, buf + LWS_PRE);
  return (buf + LWS_PRE);
}

void fill_buffer (char * buf, const char * text)
{
  sprintf (buf, "%s", text);
}

extern int close_testing_flag;

void close_testing (void)
{
  close_testing_flag = 1;
}

void open_testing (void)
{
  close_testing_flag = 0;
}

int is_close_testing ()
{
  return close_testing_flag;
}

void print_pointer (const char * nm, const void * ptr)
{
  printf ("%s is %p\n", nm, ptr);
}

struct per_vhost_data__dumb_increment {
	uv_timer_t timeout_watcher;
	struct lws_context *context;
	struct lws_vhost *vhost;
	const struct lws_protocols *protocol;
};

void * per_vhost_data__dumb_increment_from_timeout_watcher (uv_timer_t *tw)
{
  struct per_vhost_data__dumb_increment *vhd = lws_container_of(tw,
	     struct per_vhost_data__dumb_increment, timeout_watcher);
  return vhd;
}
