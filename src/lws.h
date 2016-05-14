/*
  C declarations for libebsockets wrapper
*/
#include <string.h>
#include <libwebsockets.h>


char * string_to_c (char * str) {
  char * dest;
  dest = malloc (strlen (str) + 1);
  strcpy (dest, str);
  return dest;
}

char * make_string (char * str) {return str;} 

struct lws_context_creation_info connection_information;

/*
 * take care to zero down the info struct, he contains random garbaage
 * from the stack otherwise
*/
void clear_connection_information ()
{
  memset(&connection_information, 0, sizeof connection_information);
}

void set_log_level_syslog (int level)
{
  lws_set_log_level (level, lwsl_emit_syslog);
}

lws_extension_callback_function * pm_deflate ()
{
  return &lws_extension_callback_pm_deflate;
}

void * uv_user_data (uv_signal_t *watcher)
{
  return watcher->data;
}

size_t uv_timer_t_size ()
{
  return sizeof(uv_timer_t);
}

