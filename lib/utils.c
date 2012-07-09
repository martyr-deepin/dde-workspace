#include "utils.h"
#include <glib.h>
#include <sys/stat.h>
#include <stdio.h>
#include <string.h>

char* get_html_path(const char* name)
{
    GString *path = g_string_new("file:///");
    g_string_append_printf(path, "%s/%s", 
            g_environ_getenv(g_get_environ(), "PWD"),
            name);
    return g_string_free(path, FALSE);
}
char* get_config_path(const char* name)
{
    GString *path = g_string_new(g_environ_getenv(g_get_environ(), "HOME"));
    g_string_append_printf(path, "/.config/%s", name);

    g_mkdir_with_parents(path->str, S_IRWXU);

    return g_string_free(path, FALSE);
}
