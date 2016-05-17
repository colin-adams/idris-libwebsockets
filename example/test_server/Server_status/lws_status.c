#include "lws_status.h"

static unsigned char server_info[1024];
static int server_info_len;
static int current;
static char cache[16384];
static int cache_len;
static struct per_session_data__lws_status *list;
static int live_wsi;

int server_info_length ()
{
  return server_info_len;
}

void decrement_live_wsi (struct per_session_data__lws_status *pss)
{
  struct per_session_data__lws_status **pp;
  pp = &list;
  while (*pp) {
    if (*pp == pss) {
      *pp = pss->list;
      pss->list = NULL;
      live_wsi--;
      break;
    }
    pp = &((*pp)->list);
  }
}

struct per_session_data__lws_status *get_list ()
{
  return list;
}

char * get_cache ()
{
  return cache;
}

size_t cache_length()
{
  return (size_t) cache_len;
}

void update_status(struct lws *wsi, struct per_session_data__lws_status *pss)
{
	struct per_session_data__lws_status **pp = &list;
	int subsequent = 0;
	char *p = cache + LWS_PRE, *start = p;
	char date[128];
	time_t t;
	struct tm *ptm;
#ifndef WIN32
	struct tm tm;
#endif

	p += snprintf(p, 512, " { %s, \"wsi\":\"%d\", \"conns\":[",
		     server_info, live_wsi);

	/* render the list */
	while (*pp) {
		t = (*pp)->tv_established.tv_sec;
#ifdef WIN32
		ptm = localtime(&t);
		if (!ptm)
#else
		ptm = &tm;
		if (!localtime_r(&t, &tm))
#endif
			strcpy(date, "unknown");
		else
			strftime(date, sizeof(date), "%F %H:%M %Z", ptm);
		if ((p - start) > (sizeof(cache) - 512))
			break;
		if (subsequent)
			*p++ = ',';
		subsequent = 1;
		p += snprintf(p, sizeof(cache) - (p - start) - 1,
				"{\"peer\":\"%s\",\"time\":\"%s\","
				"\"ua\":\"%s\"}",
			     (*pp)->ip, date, (*pp)->user_agent);
		pp = &((*pp)->list);
	}

	p += sprintf(p, "]}");
	cache_len = p - start;
	lwsl_err("cache_len %d\n", cache_len);
	*p = '\0';

	/* since we changed the list, increment the 'version' */
	current++;
	/* update everyone */
	lws_callback_on_writable_all_protocol(lws_get_context(wsi),
					      lws_get_protocol(wsi));
}

void set_server_info (const char * ver, const char * nm)
{
  server_info_len = sprintf((char *)server_info,
			    "\"version\":\"%s\","
			    " \"hostname\":\"%s\"", ver, nm);
}

void set_last (struct per_session_data__lws_status *pss, int last)
{
  pss-> last = last;
}

void set_list (struct per_session_data__lws_status *pss)
{
  pss-> list = list;
  list = pss;
}

void increment_live_wsi ()
{
  live_wsi++;
}

void set_ip (struct per_session_data__lws_status *pss, const char * name, const char * rip)
{
  sprintf(pss->ip, "%s (%s)", name, rip);
  gettimeofday(&pss->tv_established, NULL);
}

void set_user_agent (struct per_session_data__lws_status *pss, const char * name)
{
  strcpy(pss->user_agent, name);
}

char * user_agent (struct per_session_data__lws_status *pss)
{
  return pss->user_agent;
}
