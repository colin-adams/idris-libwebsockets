#include <stdlib.h>
#include <libwebsockets.h>
#include "time.h"

struct per_session_data__lws_status {
	struct per_session_data__lws_status *list;
	struct timeval tv_established;
	int last;
	char ip[270];
	char user_agent[512];
	const char *pos;
	int len;
};

int server_info_length (void);

void decrement_live_wsi (struct per_session_data__lws_status *pss);

struct per_session_data__lws_status *get_list (void);

char * get_cache (void);

size_t cache_length(void);

void update_status(struct lws *wsi, struct per_session_data__lws_status *pss);

void set_server_info (const char * ver, const char * nm);

void set_last (struct per_session_data__lws_status *pss, int last);

void set_list (struct per_session_data__lws_status *pss);

void set_ip (struct per_session_data__lws_status *pss, const char * name, const char * rip);

void set_user_agent (struct per_session_data__lws_status *pss, const char * name);

char * user_agent (struct per_session_data__lws_status *pss);
