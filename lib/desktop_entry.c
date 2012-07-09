#include <glib.h>
#include <glib/gstdio.h>
#include <stdio.h>
#include <string.h>
#define _JS_FUNC

static const char* 
XDG_PATH(const char* name)
{
    static char _name[100];
    snprintf(_name, 100, "XDG_%s", name);
    return g_environ_getenv(g_get_environ(), _name);
}

enum {
    SIZE_16,
    SIZE_32,
    SIZE_48,
};

gchar* try_get_path(const gchar* dir, 
        const gchar* theme, 
        int _size, 
        gchar* name)
{
    gchar* path = NULL;

    const gchar* size;
    switch (_size) {
        case SIZE_16:
            size = "16x16";
            break;
        case SIZE_32:
            size = "32x32";
            break;
        case SIZE_48:
            size = "48x48";
            break;
        default:
            g_assert(!"size didn't support");
    }

    path = g_strconcat(dir, "/icons/",
            theme, "/",
            size, "/", 
            "/apps/",
            name, ".png", NULL);
    if (g_file_test(path, G_FILE_TEST_IS_REGULAR)) {
        return path;
    } else {
        g_free(path);
        return NULL;
    }
}

gchar* find_icon_path(gchar* name)
{
    const gchar* home_dir = XDG_PATH("DATA_HOME");
    gchar* path = try_get_path(home_dir, "hicolor", SIZE_16, name);
    if (path)
        return path;

    gchar** dirs = g_strsplit(XDG_PATH("DATA_DIRS"), ":", -1);
    gchar** tmp = dirs;
    gchar* dir = NULL;
    while ((dir = *tmp++) != NULL) {
        gchar* path = try_get_path(dir, "hicolor", SIZE_48, name);
        if (path) {
            g_strfreev(dirs);
            return path;
        }

        path = try_get_path(dir, "oxygen", SIZE_48, name);
        if (path) {
            g_strfreev(dirs);
            return path;
        }

    }

    g_strfreev(dirs);
    return g_strdup("None");
}

gchar* parse_desktop_entry(const gchar* path)
{
    gchar *group = "Desktop Entry";
    GKeyFile *de = g_key_file_new();
    if (!g_key_file_load_from_file(de, path, G_KEY_FILE_NONE, NULL)) {
        g_assert(!"shoud an desktip file");
    } 
    gchar* icon = find_icon_path(g_key_file_get_value(de, group, "Icon", NULL));
    gchar* name = g_key_file_get_value(de, group, "Name", NULL);
    gchar* exec = g_key_file_get_value(de, group, "Exec", NULL);
    const gchar* format = "{name:\'%s\', icon:\'file://%s\', exec:\'%s\'},";

    gchar* result = g_new(gchar, strlen(icon) + strlen(name) + strlen(exec) + strlen(format));
    sprintf(result, format, name, icon, exec);

    g_free(icon);
    g_free(name);
    g_free(exec);
    return result;
}

_JS_FUNC
char* get_desktop_entries()
{
    GString *content = g_string_new("[");

    gchar* base_dir = g_strconcat(g_environ_getenv(g_get_environ(), "HOME"),
            "/Desktop", NULL);
    GDir *dir =  g_dir_open(base_dir, 0, NULL);
    const gchar* filename = NULL;
    gchar path[1000];

    while ((filename = g_dir_read_name(dir)) != NULL) {
        if (g_str_has_suffix(filename, ".desktop")) {
            g_sprintf(path, "%s/%s", base_dir, filename);
            gchar* tmp = parse_desktop_entry(path);
            g_string_append(content, tmp);
            g_free(tmp);
        }
    }
    g_free(base_dir);
    g_string_append(content, "]");
    return content->str;
}
