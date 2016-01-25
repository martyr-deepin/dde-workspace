#include <stdlib.h>
#include <glib.h>
#include <gio/gio.h>

#define SCHEMA_ID "com.deepin.dde.personalization"
#define CURRENT_PCITURE "picture-uri"

static GSettings* s = NULL;
static gsize len = 0;

gboolean change_bg(char** bgs)
{
    int i = rand() % len;
    if (g_settings_set_string(s, CURRENT_PCITURE, bgs[i]))
        g_warning("change background to %s", bgs[i]);

    return G_SOURCE_CONTINUE;
}

int main()
{
    /* GMainLoop* main_loop = g_main_loop_new(NULL, FALSE); */
    GKeyFile* conf = g_key_file_new();
    GError* err = NULL;
    g_key_file_load_from_file(conf, "../app/launcher/test/bgs.conf", G_KEY_FILE_NONE, &err);
    if (err != NULL) {
        g_warning("%s", err->message);
        goto out;
    }

    char** bgs = g_key_file_get_string_list(conf, "bgs", "values", &len, &err);
    if (err != NULL) {
        g_warning("%s", err->message);
        goto out;
    }

    srand(time(NULL));
    s = g_settings_new(SCHEMA_ID);
    while(1) {
#include <unistd.h>
        sleep(1);
        change_bg(bgs);
        /* g_timeout_add(500, (GSourceFunc)change_bg, bgs); */
    }
    /* g_main_loop_run(main_loop); */
    g_strfreev(bgs);
    g_object_unref(s);

    return 0;

out:
    g_error_free(err);
    g_key_file_unref(conf);
    /* g_main_loop_unref(main_loop); */

    return 1;
}

