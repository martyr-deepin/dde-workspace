/**
 * Copyright (c) 2011 ~ 2012 Deepin, Inc.
 *               2011 ~ 2012 snyh
 *
 * Author:      snyh <snyh@snyh.org>
 * Maintainer:  snyh <snyh@snyh.org>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, see <http://www.gnu.org/licenses/>.
 **/
#include <glib.h>
#include <string.h>
#include <gio/gio.h>
#include <sys/stat.h>
#include "utils.h"
#include "xdg_misc.h"
#include "jsextension.h"


#define DESKTOP_SCHEMA_ID "com.deepin.dde.desktop"
#define DOCK_SCHEMA_ID "com.deepin.dde.dock"
#define SCHEMA_KEY_ENABLED_PLUGINS "enabled-plugins"

PRIVATE GSettings* desktop_gsettings = NULL;
GHashTable* enabled_plugins = NULL;
GHashTable* plugins_state = NULL;

enum PluginState {
    DISABLED_PLUGIN,
    ENABLED_PLUGIN,
    UNKNOWN_PLUGIN
};


//TODO run_command support variable arguments

JS_EXPORT_API
char* dcore_get_theme_icon(const char* name, double size)
{
    return icon_name_to_path_with_check_xpm(name, size);
}


#define IS_DIR(path) g_file_test(path, G_FILE_TEST_IS_DIR)


gboolean is_plugin(char const* path)
{
    char* basename = g_path_get_basename(path);
    char* js_name = g_strconcat(basename, ".js", NULL);
    g_free(basename);
    char* js_file_path = g_build_filename(path, js_name, NULL);
    g_free(js_name);

    return g_file_test(js_file_path, G_FILE_TEST_EXISTS);
}

void _init_state(gpointer key, gpointer value, gpointer user_data)
{
    g_hash_table_replace((GHashTable*)user_data, g_strdup(key), GINT_TO_POINTER(DISABLED_PLUGIN));
}


gchar * get_schema_id(GSettings* gsettings)
{
    GValue value = G_VALUE_INIT;
    g_value_init(&value, G_TYPE_STRING);
    g_object_get_property(G_OBJECT(gsettings), "schema-id", &value);
    char * schema_id = g_strdup(g_value_get_string(&value));
    g_value_unset(&value);
    return schema_id;
}


void get_enabled_plugins(GSettings* gsettings, char const* key)
{
    char * schema_id = get_schema_id(gsettings);
    char const* id_prefix = NULL;
    if (g_str_has_suffix(schema_id, "desktop"))
        id_prefix = "desktop:";

    g_free(schema_id);
    g_assert(id_prefix != NULL);

    char** values = g_settings_get_strv(gsettings, key);
    for (int i = 0; values[i] != NULL; ++i) {
        g_hash_table_add(enabled_plugins, g_strconcat(id_prefix, values[i], NULL));
        g_hash_table_replace(plugins_state, g_strconcat(id_prefix, values[i], NULL),
                             GINT_TO_POINTER(ENABLED_PLUGIN));
    }

    g_strfreev(values);
}


JS_EXPORT_API
void dcore_init_plugins(char const* app_name)
{
    GSettings* gsettings = NULL;
    if (desktop_gsettings == NULL)
        desktop_gsettings = g_settings_new(DESKTOP_SCHEMA_ID);

    if (g_str_equal(app_name, "desktop"))
        gsettings = desktop_gsettings;

    if (plugins_state == NULL)
        plugins_state = g_hash_table_new_full(g_str_hash, g_str_equal, g_free, NULL);

    g_hash_table_foreach(plugins_state, _init_state, plugins_state);

    if (enabled_plugins != NULL)
        g_hash_table_unref(enabled_plugins);

    enabled_plugins = g_hash_table_new_full(g_str_hash, g_str_equal, g_free, NULL);
    get_enabled_plugins(gsettings, SCHEMA_KEY_ENABLED_PLUGINS);
}


JS_EXPORT_API
JSValueRef dcore_get_plugins(const char* app_name)
{
    JSObjectRef array = json_array_create();
    JSContextRef ctx = get_global_context();
    char* path = g_build_filename(RESOURCE_DIR, app_name, "plugin", NULL);

    GDir* dir = g_dir_open(path, 0, NULL);
    if (dir != NULL) {
        const char* file_name = NULL;
        for (int i=0; NULL != (file_name = g_dir_read_name(dir));) {
            char* full_path = g_build_filename(path, file_name, NULL);

            if (IS_DIR(full_path) && is_plugin(full_path)) {
                char* js_name = g_strconcat(file_name, ".js", NULL);
                char* js_path = g_build_filename(full_path, js_name, NULL);
                g_free(js_name);

                char* key = g_strconcat(app_name, ":", file_name, NULL);
                if (g_hash_table_contains(enabled_plugins, key)) {

                    JSValueRef v = jsvalue_from_cstr(ctx, js_path);
                    json_array_insert(array, i++, v);
                }

                g_free(key);
                g_free(js_path);
            }

            g_free(full_path);
        }

        g_dir_close(dir);
    }

    g_free(path);

    return array;
}


void create_strv(gpointer key, gpointer value, gpointer user_data)
{
    g_ptr_array_add((GPtrArray*)user_data, g_strdup(value));
}


void enable_plugin(GSettings* gsettings, char const* id, gboolean value)
{
    if (value && !g_hash_table_contains(enabled_plugins, id)) {
        g_hash_table_add(enabled_plugins, g_strdup(id));
        g_hash_table_replace(plugins_state, g_strdup(id), GINT_TO_POINTER(ENABLED_PLUGIN));
    } else if (!value) {
        g_hash_table_remove(enabled_plugins, id);
        g_hash_table_replace(plugins_state, g_strdup(id), GINT_TO_POINTER(DISABLED_PLUGIN));
    }

    GPtrArray* values = g_ptr_array_new_with_free_func(g_free);
    g_hash_table_foreach(enabled_plugins, create_strv, (gpointer)values);
    g_ptr_array_add(values, NULL);
    g_settings_set_strv(gsettings, SCHEMA_KEY_ENABLED_PLUGINS, (char const* const*)values->pdata);
    g_ptr_array_unref(values);
    g_settings_sync();
}


JS_EXPORT_API
void dcore_enable_plugin(char const* id, gboolean value)
{
    GSettings* gsettings = NULL;
    char* pos = strchr(id, ':');
    char* app_name = g_strndup(id, pos - id);

    if (g_str_equal(app_name, "desktop"))
        gsettings = desktop_gsettings;

    g_free(app_name);

    enable_plugin(gsettings, id, value);
}
