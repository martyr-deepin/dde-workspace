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


JS_EXPORT_API
void desktop_enable_plugin(char const* id, gboolean value)
{
    GSettings* gsettings = NULL;
    if (desktop_gsettings == NULL)
        desktop_gsettings = g_settings_new(DESKTOP_SCHEMA_ID);

    if (enabled_plugins == NULL)
        enabled_plugins = g_hash_table_new_full(g_str_hash, g_str_equal, g_free, NULL);

    gsettings = desktop_gsettings;

    if (value && !g_hash_table_contains(enabled_plugins, id))
        g_hash_table_add(enabled_plugins, g_strdup(id));
    else if (!value)
       g_hash_table_remove(enabled_plugins, id);
}

