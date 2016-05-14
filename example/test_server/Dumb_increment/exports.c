#include <libwebsockets.h>
#include "init.h"
#include "destroy.h"

static VM *vm;

int init_protocol_dumb_increment (struct lws_context *context,
			     struct lws_plugin_capability *c)
{
  vm = idris_vm();
  return init_protocol_dumb_increment_exported(vm, context, c);
}

int destroy_protocol_dumb_increment (struct lws_context *context)
{
  return destroy_protocol_dumb_increment_exported(vm, context);
  close_vm(vm);
}
