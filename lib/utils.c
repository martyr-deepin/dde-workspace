#include "utils.h"
#include <glib.h>

char* get_html_path(const char* name)
{
    const gchar* pwd = g_environ_getenv(g_get_environ(), "PWD");
    gchar* path = g_new(gchar, strlen(pwd) + strlen(name) + 2);
    sprintf(path, "%s/%s", pwd, name);
    return path;
}
