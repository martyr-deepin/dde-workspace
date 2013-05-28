#include <string.h>
#include <glib.h>
#include <gio/gio.h>
#include <jsextension.h>

#define DESKTOP_SCHEMA_ID "com.deepin.dde.desktop"
#define DOCK_SCHEMA_ID "com.deepin.dde.dock"
#define SCHEMA_KEY_ENABLED_PLUGINS "enabled-plugins"

PRIVATE GSettings* desktop_gsettings = NULL;
PRIVATE GHashTable* enabled_plugins = NULL;


PRIVATE
void _filter_disabled_plugins(gpointer key, gpointer value, gpointer user_data)
{
    g_ptr_array_add((GPtrArray*)user_data, g_strdup(key));
}


PRIVATE
void update_gsettings(GSettings* gsettings)
{
    GPtrArray* _enabled_plugins = g_ptr_array_new_with_free_func(g_free);
    g_hash_table_foreach(enabled_plugins, _filter_disabled_plugins, _enabled_plugins);
    g_ptr_array_add(_enabled_plugins, NULL);

    g_settings_set_strv(gsettings, SCHEMA_KEY_ENABLED_PLUGINS,
                        (char const* const*)_enabled_plugins->pdata);
    g_settings_sync();

    g_ptr_array_unref(_enabled_plugins);
}


JS_EXPORT_API
void desktop_enable_plugin(char const* id, gboolean value)
{
    GSettings* gsettings = NULL;
    if (desktop_gsettings == NULL)
        desktop_gsettings = g_settings_new(DESKTOP_SCHEMA_ID);

    if (enabled_plugins == NULL)
        enabled_plugins = g_hash_table_new_full(g_str_hash, g_str_equal, g_free, NULL);

    /* if (g_str_equal(parent, "desktop")) { */
        gsettings = desktop_gsettings;
    /* } else if (g_str_equal(parent, "dock")) { */
    /*     settings = NULL; */
    /* } else if (g_str_equal(parent, "launcher")) { */
    /*     settings = NULL; */
    /* } else { */
    /*     settigs = NULL; */
    /*     #<{(| js_post_message_simply(""); |)}># */
    /* } */

    if (value && !g_hash_table_contains(enabled_plugins, id)) {
        char* basename = g_path_get_basename(id);
        g_hash_table_add(enabled_plugins, g_strndup(basename, strlen(basename) / 2));
        g_free(basename);
        update_gsettings(gsettings);
    } else if (!value && g_hash_table_remove(enabled_plugins, id)) {
        update_gsettings(gsettings);
    }
}

