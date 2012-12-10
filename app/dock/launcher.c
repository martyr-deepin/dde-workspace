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
#include "desktop_file_matcher.h"
#include <string.h>
#include <gio/gdesktopappinfo.h>

#define APPS_INI "dock/apps.ini"
static GKeyFile* k_apps = NULL;

static
void post_app_info(const char* app_id)
{
    char* path = g_key_file_get_string(k_apps, app_id, "Path", NULL);
    GAppInfo* info = NULL;
    if (path != NULL) {
        info = g_desktop_app_info_new_from_filename(path);
        g_free(path);
    } else {
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
    json_append_nobject(json, "Core", info, g_object_unref);
    json_append_string(json, "Id", app_id);
    json_append_string(json, "Name", g_app_info_get_display_name(info));

    char* icon_name = NULL;
    GIcon* icon = g_app_info_get_icon(info);
    if (icon != NULL) {
        icon_name = g_icon_to_string(icon);
    } else {
        icon_name = g_key_file_get_string(k_apps, app_id, "Icon", NULL);
    }
    char* icon_path = icon_name_to_path(icon_name, 48);
    g_free(icon_name);
    json_append_string(json, "Icon", icon_path);
    g_free(icon_path);

    js_post_message_json("launcher_added", json);

    return;
}


static
char* get_app_id(GDesktopAppInfo* info)
{
    char* basename = g_path_get_basename(g_desktop_app_info_get_filename(info));
    basename[strlen(basename) - 8 /*strlen(".desktop")*/] = '\0';
    if (is_app_in_white_list(basename)) {
        return basename;
    } else {
        g_free(basename);

        return g_strdup(g_app_info_get_executable(G_APP_INFO(info)));
    }
}

void update_dock_apps()
{
    gsize size = 0;
    char** groups = g_key_file_get_groups(k_apps, &size);
    for (gsize i=0; i<size; i++) {
        post_app_info(groups[i]);
    }
    g_strfreev(groups);
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

    g_free(app_id);

    save_app_config(k_apps, APPS_INI);
}


JS_EXPORT_API
void request_dock(const char* path)
{
    GDesktopAppInfo* info = g_desktop_app_info_new_from_filename(path);
    if (info != NULL) {
        char* app_id = get_app_id(info);
        write_app_info(info);
        post_app_info(app_id);
        g_free(app_id);
    } else {
        g_warning("request dock %s is invalide\n", path);
    }
    g_object_unref(info);
}


JS_EXPORT_API
void request_undock(const char* app_id)
{
    g_key_file_remove_group(k_apps, app_id, NULL);
    save_app_config(k_apps, APPS_INI);

    js_post_message("launcher_deleted", "{\"Id\": \"%s\"}", app_id);
}

JS_EXPORT_API
void try_post_launcher_info(const char* app_id)
{
    if (g_key_file_has_group(k_apps, app_id)) {
        post_app_info(app_id);
    } else {
        g_debug("try find %s failed \n", app_id);
    }
}
