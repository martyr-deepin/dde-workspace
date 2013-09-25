#include <glib.h>
#include <gio/gio.h>
#include <string.h>

char* _get_pkg_name(const char* name)
{
    GError* err = NULL;
    gint exit_status = 0;
    char* cmd[] = { "dpkg", "-S", (char*)name, NULL};
    char* output = NULL;
    g_spawn_sync(NULL, cmd, NULL,
                 G_SPAWN_SEARCH_PATH
                 | G_SPAWN_STDERR_TO_DEV_NULL,
                 NULL, NULL, &output, NULL, &exit_status, &err);
    if (err != NULL) {
        g_warning("[launcher_uninstall] get package name failed: %s", err->message);
        g_error_free(err);
        return NULL;
    }

    if (exit_status != 0) {
        g_free(output);
        return NULL;
    }

    char* del = strchr(output, ':');
    char* pkg_name = g_strndup(output, del - output);
    g_free(output);

    return pkg_name;
}


int main(int argc, char *argv[])
{
    g_free(_get_pkg_name("google-chrome.desktop"));

    return 0;
}

