#include <libwebsockets.h>
#include "exports.h"

static VM *vm;

int init_protocol_post_demo (struct lws_context *context,
			     struct lws_plugin_capability *c)
{
  vm = idris_vm();
  return init_protocol_post_demo_exported(vm, context, c);
}

int destroy_protocol_post_demo (struct lws_context *context)
{
  return destroy_protocol_post_demo_exported(vm, context);
  close_vm(vm);
}
