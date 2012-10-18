#include "utils.h"
#include <glib.h>
#include <sys/stat.h>
#include <stdio.h>
#include <string.h>

char* get_html_path(const char* name)
{
    GString *path = g_string_new("file://");
    g_string_append_printf(path, "%s/%s/index.html", RESOURCE_DIR, name);
    return g_string_free(path, FALSE);
}
char* get_config_path(const char* name)
{
    GString *path = g_string_new(g_environ_getenv(g_get_environ(), "HOME"));
    g_string_append_printf(path, "/.config/%s", name);

    g_mkdir_with_parents(path->str, S_IRWXU);

    return g_string_free(path, FALSE);
}


char* json_escape (const char *source)
{
    const unsigned char *p;
    char *dest;
    char *q;

    g_return_val_if_fail (source != NULL, NULL);

    p = (unsigned char *) source;
    q = dest = g_malloc (strlen (source) * 4 + 1);

    while (*p)
    {
        switch (*p)
        {
            case '\b':
                *q++ = '\\';
                *q++ = 'b';
                break;
            case '\f':
                *q++ = '\\';
                *q++ = 'f';
                break;
            case '\n':
                *q++ = '\\';
                *q++ = 'n';
                break;
            case '\r':
                *q++ = '\\';
                *q++ = 'r';
                break;
            case '\t':
                *q++ = '\\';
                *q++ = 't';
                break;
            case '\v':
                *q++ = '\\';
                *q++ = 'v';
                break;
            case '\\':
                *q++ = '\\';
                *q++ = '\\';
                break;
            case '"':
                *q++ = '\\';
                *q++ = '"';
                break;
            default:
                *q++ = *p;
        }
        p++;
    }
    *q = 0;
    return dest;
}
