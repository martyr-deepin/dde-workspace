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
#include <glib/gstdio.h>
#include <gtk/gtk.h>
#include <string.h>
#include <gio/gio.h>
#include <sys/stat.h>
#include "utils.h"
#include "xdg_misc.h"
#include "jsextension.h"
#include "dwebview.h"
#include "dcore.h"
#include "pixbuf.h"


#define DESKTOP_SCHEMA_ID "com.deepin.dde.desktop"
#define DOCK_SCHEMA_ID "com.deepin.dde.dock"
#define SCHEMA_KEY_ENABLED_PLUGINS "enabled-plugins"

static GSettings* desktop_gsettings = NULL;
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
    return icon_name_to_path_with_check_xpm(name, (int)size);
}


JS_EXPORT_API
char* dcore_get_name_by_appid(const char* id)
{
    GDesktopAppInfo* a = guess_desktop_file(id);
    if (a != NULL) {
        char* name = g_strdup(g_app_info_get_name(G_APP_INFO(a)));
        g_object_unref(a);
        return name;
    }
    return g_strdup("");
}


JS_EXPORT_API
void dcore_init_plugins(char const* app_name)
{
    return;
}
JS_EXPORT_API
JSValueRef dcore_get_plugins(const char* app_name)
{
    JSObjectRef array = json_array_create();

    return array;
}


JS_EXPORT_API
void dcore_enable_plugin(char const* id, gboolean value)
{
    return;
}


JS_EXPORT_API
JSValueRef dcore_get_plugin_info(char const* path)
{
    JSObjectRef json = json_create();
    return json;
}


JS_EXPORT_API
void dcore_new_window(const char* url, const char* title, double w, double h)
{
    g_warning("Don't use the function now!");
    GtkWidget* container = gtk_window_new(GTK_WINDOW_TOPLEVEL);
    gtk_window_set_title(GTK_WINDOW(container), title);
    gtk_widget_set_size_request(container, (int)w, (int)h);
    GtkWidget *webview = d_webview_new_with_uri(url);
    gtk_container_add(GTK_CONTAINER(container), webview);
    gtk_widget_show_all(container);
}


JS_EXPORT_API
gboolean dcore_open_browser(char const* origin_uri)
{
    if (origin_uri == NULL || origin_uri[0] == '\0')
        return FALSE;

    char* uri = g_uri_unescape_string(origin_uri, G_URI_RESERVED_CHARS_ALLOWED_IN_PATH);
    char* scheme = g_uri_parse_scheme(uri);
    if (scheme == NULL) {
        char* uri_without_scheme = uri;
        uri = g_strconcat("http://", uri_without_scheme, NULL);
        g_free(uri_without_scheme);
    }
    g_free(scheme);

    gboolean launch_result = g_app_info_launch_default_for_uri(uri, NULL, NULL);
    g_free(uri);

    return launch_result;
}


char* dcore_backup_app_icon(char const* path)
{
    char* dir = g_build_filename(g_get_user_cache_dir(), "dde", "uninstall", NULL);
    if (!g_file_test(dir, G_FILE_TEST_EXISTS)) {
        g_mkdir_with_parents(dir, 0755);
    }

    char* backup = NULL;

    if (g_str_has_prefix(path, "data:image")) {
        char* basename = g_path_get_basename(path);
        char* name = g_strconcat(basename, ".png", NULL);
        g_free(basename);
        backup = g_build_filename(dir, name, NULL);
        g_free(name);
        data_uri_to_file(path, backup);
    } else {
        GFile* f = g_file_new_for_path(path);
        if (f == NULL) {
            return NULL;
        }

        char* basename = g_path_get_basename(path);
        backup = g_build_filename(dir, basename, NULL);
        g_free(basename);

        GFile* dest = g_file_new_for_path(backup);
        if (dest == NULL) {
            g_object_unref(f);
            return NULL;
        }

        GError* err = NULL;
        g_file_copy(f, dest, G_FILE_COPY_OVERWRITE, NULL, NULL, NULL, &err);
        g_object_unref(dest);
        g_object_unref(f);
        if (err != NULL) {
            g_warning("copy file(%s) failed: %s", path, err->message);
            g_clear_error(&err);
            return NULL;
        }
    }

    g_free(dir);

    return backup;
}


void dcore_delete_backup_app_icon(char const* path)
{
    g_warning("delete backup app icon: %s", path);
    g_remove(path);
}

