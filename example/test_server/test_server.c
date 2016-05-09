#include "test_server.h"

int close_testing_flag;

void * transmission_buffer (unsigned int size)
{
  printf ("LWS_PRE is %d\n", LWS_PRE);
  return calloc(1, LWS_PRE + size);
}

void * transmission_buffer_start (void * buf)
{
  printf ("LWS_PRE is %d, buffer address is %p, writing address is %p\n", LWS_PRE, buf, buf + LWS_PRE);
  return (buf + LWS_PRE);
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
