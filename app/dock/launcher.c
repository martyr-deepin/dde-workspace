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
#include "xdg_misc.h"
#include "jsextension.h"
#include "utils.h"
#include "launcher.h"
#include "dock_config.h"
#include "tasklist.h"
#include "xid2aid.h"
#include "handle_icon.h"

#include <string.h>
#include <gio/gdesktopappinfo.h>

/* * app_id is 
 * 1. the desktop file name in whitelist
 * 2. the normal desktop file name
 * 3. the executable file name
 * */

#define APPS_INI "dock/apps.ini"
static GKeyFile* k_apps = NULL;
static GList* _apps_position = NULL;

static
JSValueRef build_app_info(const char* app_id)
{
    char* path = g_key_file_get_string(k_apps, app_id, "Path", NULL);
    GAppInfo* info = NULL;
    if (path != NULL) {
        info = G_APP_INFO(g_desktop_app_info_new_from_filename(path));
        if (info == NULL) {
            // if the path is invalid then info will be none, e.g. the path save in ini file is remove on filesystem.
            g_key_file_remove_key(k_apps, app_id, "Path", NULL);
        }
        g_free(path);
    }

    if (info == NULL) {
        char* cmdline = g_key_file_get_string(k_apps, app_id, "CmdLine", NULL);
        char* name = g_key_file_get_string(k_apps, app_id, "Name", NULL);
        if (g_key_file_get_boolean(k_apps, app_id, "Terminal", NULL))
            info = g_app_info_create_from_commandline(cmdline, name, G_APP_INFO_CREATE_NEEDS_TERMINAL, NULL);
        else
            info = g_app_info_create_from_commandline(cmdline, name, G_APP_INFO_CREATE_NONE, NULL);
        g_free(name);
        g_free(cmdline);
    }

    JSObjectRef json = json_create();
    json_append_nobject(json, "Core", info, g_object_ref, g_object_unref);
    json_append_string(json, "Id", app_id);
    json_append_string(json, "Name", g_app_info_get_display_name(info));

    char* icon_name = NULL;
    GIcon* icon = g_app_info_get_icon(info);
    if (icon != NULL) {
        icon_name = g_icon_to_string(icon);
    } else {
        icon_name = g_key_file_get_string(k_apps, app_id, "Icon", NULL);
    }

    if (icon_name != NULL) {
        if (g_str_has_prefix(icon_name, "data:image")) {
            json_append_string(json, "Icon", icon_name);
        } else {
            char* icon_path = icon_name_to_path(icon_name, 48);
            if (is_deepin_icon(icon_path)) {
                json_append_string(json, "Icon", icon_path);
            } else {
                GdkPixbuf* pixbuf = gdk_pixbuf_new_from_file_at_scale(icon_path, IMG_WIDTH, IMG_HEIGHT, TRUE, NULL);
                if (pixbuf == NULL) {
                    json_append_string(json, "Icon", NULL);
                } else {
                    char* icon_data = handle_icon(pixbuf);
                    g_object_unref(pixbuf);
                    json_append_string(json, "Icon", icon_data);
                    g_free(icon_data);
                }
            }
            g_free(icon_path);
        }
        g_free(icon_name);

    }
    g_object_unref(info);
    return json;
}


static
char* get_app_id(GDesktopAppInfo* info)
{
    char* app_id = NULL;
    char* basename = g_path_get_basename(g_desktop_app_info_get_filename(info));
    basename[strlen(basename) - 8 /*strlen(".desktop")*/] = '\0';
    if (is_app_in_white_list(basename)) {
        app_id = basename;
    } else {
        g_free(basename);

        app_id = g_path_get_basename(g_app_info_get_executable(G_APP_INFO(info)));
    }
    return to_lower_inplace(app_id);
}

void update_dock_apps()
{
    gsize size = 0;
    GError* err = NULL;
    char** list = g_key_file_get_string_list(k_apps, "__Config__", "Position", &size, &err);
    g_assert(list != NULL);

    if (_apps_position != NULL) {
        g_list_free_full(_apps_position, g_free);
        _apps_position = NULL;
    }

    for (gsize i=0; i<size; i++) {
        printf("launcher added %s\n", list[i]);
        js_post_message("launcher_added", build_app_info(list[i]));
        _apps_position = g_list_prepend(_apps_position, g_strdup(list[i]));
    }

    _apps_position = g_list_reverse(_apps_position);

    g_strfreev(list);
}

void init_launchers()
{
    if (k_apps == NULL) {
        k_apps = load_app_config(APPS_INI);
        update_dock_apps();
    }
}

static 
int get_need_terminal(GDesktopAppInfo* info)
{
    //copy from gio source code.
    struct _GDesktopAppInfo
    {
        GObject parent_instance;

        char *desktop_id;
        char *filename;

        char *name;
        char *generic_name;
        char *fullname;
        char *comment;
        char *icon_name;
        GIcon *icon;
        char **keywords;
        char **only_show_in;
        char **not_show_in;
        char *try_exec;
        char *exec;
        char *binary;
        char *path;
        char *categories;

        guint nodisplay       : 1;
        guint hidden          : 1;
        guint terminal        : 1;
        guint startup_notify  : 1;
        guint no_fuse         : 1;
        /* FIXME: what about StartupWMClass ? */
    };
    return ((struct _GDesktopAppInfo*)info)->terminal;
}

static
void _save_apps_position()
{
    gsize size = g_list_length(_apps_position);
    GList* _tmp_list = _apps_position;

    const gchar**list = g_new(char*, size);
    for (size_t i=0; i<size; i++) {
        list[i] = _tmp_list->data;
        _tmp_list = g_list_next(_tmp_list);
    }
    g_key_file_set_string_list(k_apps, "__Config__", "Position", list, size);
    g_free(list);
}

JS_EXPORT_API
void dock_swap_apps_position(const char* id1, const char* id2)
{
    GList* l1 = g_list_find_custom(_apps_position, id1, (GCompareFunc)g_strcmp0);
    GList* l2 = g_list_find_custom(_apps_position, id2, (GCompareFunc)g_strcmp0);
    if (l1 == NULL || l2 == NULL)
        return;

    gpointer tmp = l1->data;
    l1->data = l2->data;
    l2->data = tmp;
    _save_apps_position();
    save_app_config(k_apps, APPS_INI);
}

static
void write_app_info(GDesktopAppInfo* info)
{
    char* app_id = get_app_id(info);

    g_key_file_set_string(k_apps, app_id, "CmdLine", g_app_info_get_commandline(G_APP_INFO(info)));

    GIcon* icon = g_app_info_get_icon(G_APP_INFO(info));
    if (icon != NULL) {
        char* icon_name = g_icon_to_string(icon);
        g_key_file_set_string(k_apps, app_id, "Icon", icon_name);
        g_free(icon_name);
    }

    g_key_file_set_string(k_apps, app_id, "Name", g_app_info_get_display_name(G_APP_INFO(info)));

    g_key_file_set_string(k_apps, app_id, "Path", g_desktop_app_info_get_filename(info));
    g_key_file_set_boolean(k_apps, app_id, "Terminal", get_need_terminal(info));

    GList* pos = g_list_find_custom(_apps_position, app_id, (GCompareFunc)g_strcmp0);
    if (pos == NULL) {
        _apps_position = g_list_append(_apps_position, g_strdup(app_id));
    }

    g_free(app_id);

    _save_apps_position();
    save_app_config(k_apps, APPS_INI);
}


JS_EXPORT_API
void dock_request_dock(const char* path)
{
    GDesktopAppInfo* info = g_desktop_app_info_new_from_filename(path);
    if (info != NULL) {
        char* app_id = get_app_id(info);
        write_app_info(info);
        js_post_message("dock_request", build_app_info(app_id));
        g_free(app_id);
    } else {
        g_warning("request dock %s is invalide\n", path);
    }
    g_object_unref(info);
}

JS_EXPORT_API
void dock_request_undock(const char* app_id)
{
    g_key_file_remove_group(k_apps, app_id, NULL);
    save_app_config(k_apps, APPS_INI);

    js_post_message_simply("launcher_removed", "{\"Id\": \"%s\"}", app_id);
}

JS_EXPORT_API
JSValueRef dock_get_launcher_info(const char* app_id)
{
    if (g_key_file_has_group(k_apps, app_id)) {
        return build_app_info(app_id);
    } else {
        g_debug("try find %s failed \n", app_id);
        return jsvalue_null();
    }
}

JS_EXPORT_API
gboolean dock_launch_by_app_id(const char* app_id, const char* exec, ArrayContainer fs)
{
    GAppInfo* info = NULL;
    gboolean ret = FALSE;
    if (g_key_file_has_group(k_apps, app_id)) {
        char* path = g_key_file_get_string(k_apps, app_id, "Path", NULL);
        if (path != NULL) {
            info = G_APP_INFO(g_desktop_app_info_new_from_filename(path));
            g_free(path);
        } else {
            char* cmdline = g_key_file_get_string(k_apps, app_id, "CmdLine", NULL);
            char* name = g_key_file_get_string(k_apps, app_id, "Name", NULL);
            if (g_key_file_get_boolean(k_apps, app_id, "Terminal", NULL))
                info = g_app_info_create_from_commandline(cmdline, name, G_APP_INFO_CREATE_NEEDS_TERMINAL, NULL);
            else
                info = g_app_info_create_from_commandline(cmdline, name, G_APP_INFO_CREATE_NONE, NULL);
            g_free(cmdline);
            g_free(name);
        }
    } else {
        info = g_app_info_create_from_commandline(exec, NULL, G_APP_INFO_CREATE_NONE, NULL);
    }

    GFile** files = fs.data;
    GList* list = NULL;
    for (size_t i=0; i<fs.num; i++) {
        if (G_IS_FILE(files[i]))
            list = g_list_append(list, files[i]);
    }
    ret = g_app_info_launch(info, list, NULL, NULL);
    g_list_free(list);
    g_object_unref(info);
    return ret;
}

JS_EXPORT_API
gboolean dock_has_launcher(const char* app_id)
{
    return g_key_file_has_group(k_apps, app_id);
}

gboolean request_by_info(const char* name, const char* cmdline, const char* icon)
{
    char* id = g_strconcat(name, ".desktop", NULL);
    GDesktopAppInfo* info = g_desktop_app_info_new(id);
    g_free(id);
    if (info != NULL) {
        dock_request_dock(g_desktop_app_info_get_filename(info));
    } else {
        g_key_file_set_string(k_apps, name, "Name", name);
        g_key_file_set_string(k_apps, name, "CmdLine", cmdline);
        g_key_file_set_string(k_apps, name, "Icon", icon);

        save_app_config(k_apps, APPS_INI);

        if (!is_has_client(name))
            js_post_message("launcher_added", build_app_info(name));
    }
    return TRUE;
}
