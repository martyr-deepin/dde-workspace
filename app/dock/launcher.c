/**
 * Copyright (c) 2011 ~ 2013 Deepin, Inc.
 *               2011 ~ 2012 snyh
 *               2013 ~ 2013 Liqiang Lee
 *
 * Author:      snyh <snyh@snyh.org>
 * Maintainer:  snyh <snyh@snyh.org>
 *              Liqiang Lee <liliqiang@linuxdeepin.com>
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
#include "desktop_action.h"

#include <string.h>
#include <gio/gdesktopappinfo.h>

extern char* dcore_get_theme_icon(char const*, double);


/* * app_id is
 * 1. the desktop file name in whitelist
 * 2. the normal desktop file name
 * 3. the executable file name
 * */

GKeyFile* k_apps = NULL;
static GList* _apps_position = NULL;

PRIVATE
JSValueRef build_app_info(const char* app_id)
{
    g_assert(app_id != NULL);
    g_assert(g_key_file_has_group(k_apps, app_id));
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

    if (info == NULL) {
        g_warning("cannot get app info");
        g_key_file_remove_group(k_apps, app_id, NULL);
        save_app_config(k_apps, APPS_INI);
        update_task_list();
        return jsvalue_null();
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
            if (g_path_is_absolute(icon_name) && !is_deepin_icon(icon_name)) {
                char* temp_icon_name_holder = icon_name;
                icon_name = check_absolute_path_icon(app_id, icon_name);
                g_free(temp_icon_name_holder);
            }

            char* icon_path = icon_name_to_path(icon_name, 48);
            g_debug("[%s] icon_path: %s", __func__, icon_path);
            if (is_deepin_icon(icon_path)) {
                json_append_string(json, "Icon", icon_path);
            } else {
                gboolean use_board = TRUE;
                GdkPixbuf* pixbuf = gdk_pixbuf_new_from_file(icon_path, NULL);
                double width = gdk_pixbuf_get_width(pixbuf);
                g_object_unref(pixbuf);
                pixbuf = NULL;
                int operator_code = -1;
                if (width == 48 || (is_deepin_app_id(app_id)
                    && (operator_code = get_deepin_app_id_operator(app_id)) == \
                    ICON_OPERATOR_USE_RUNTIME_WITHOUT_BOARD)) {
                    pixbuf = gdk_pixbuf_new_from_file_at_scale(icon_path,
                                                               BOARD_WIDTH,
                                                               BOARD_HEIGHT,
                                                               TRUE, NULL);
                    use_board = FALSE;
                } else {
                    pixbuf = gdk_pixbuf_new_from_file_at_scale(icon_path,
                                                               IMG_WIDTH,
                                                               IMG_HEIGHT,
                                                               TRUE, NULL);
                }

                if (pixbuf == NULL) {
                    json_append_string(json, "Icon", NULL);
                } else {
                    char* icon_data = handle_icon(pixbuf, use_board);
                    g_object_unref(pixbuf);
                    json_append_string(json, "Icon", icon_data);
                    g_free(icon_data);
                }
            }
            g_free(icon_path);
        }
        g_free(icon_name);

    }

    // append actions
    JSObjectRef actions_js_array = json_array_create();

    GPtrArray* actions = get_app_actions(G_DESKTOP_APP_INFO(info));

    if (actions != NULL) {
        for (gsize i = 0; i < actions->len; ++i) {
            struct Action* action = g_ptr_array_index(actions, i);

            JSObjectRef action_item = json_create();
            json_append_string(action_item, "name", action->name);
            json_append_string(action_item, "exec", action->exec);

            json_array_insert(actions_js_array, i, action_item);
        }

        g_ptr_array_unref(actions);
    }

    json_append_value(json, "Actions", actions_js_array);

    g_object_unref(info);

    return json;
}


PRIVATE
char* get_app_id(GDesktopAppInfo* info)
{
    char* app_id = NULL;
    char* basename = g_path_get_basename(g_desktop_app_info_get_filename(info));
    char* t = basename;
    basename = g_strndup(basename, strlen(basename) - 8 /*strlen(".desktop")*/);
    g_free(t);
    g_debug("[%s] basename: %s", __func__, basename);
    if (g_strcmp0(basename, "google-chrome") == 0 || is_app_in_white_list(basename)) {
        app_id = basename;
        g_debug("[%s] is_app_in_white_list: %s", __func__, app_id);
    } else {
        g_free(basename);

        app_id = g_path_get_basename(g_app_info_get_executable(G_APP_INFO(info)));
        g_debug("[%s] not is_app_in_white_list: %s", __func__, app_id);
    }
    g_strdelimit(app_id, "_", '-');
    return to_lower_inplace(app_id);
}

void update_dock_apps()
{
    gsize size = 0;
    GError* err = NULL;
    char** list = g_key_file_get_string_list(k_apps,
                                             DOCKED_ITEM_GROUP_NAME,
                                             DOCKED_ITEM_KEY_NAME,
                                             &size,
                                             &err);
    if (list != NULL) {
        g_assert(list != NULL);

        if (_apps_position != NULL) {
            g_list_free_full(_apps_position, g_free);
            _apps_position = NULL;
        }

        for (gsize i=0; i<size; i++) {
            if (g_key_file_has_group(k_apps, list[i])) {
                g_debug("[%s] build app info: %s", __func__, list[i]);
                JSValueRef app_info = build_app_info(list[i]);
                if (app_info) {
                    js_post_message("launcher_added", app_info);
                    _apps_position = g_list_prepend(_apps_position, g_strdup(list[i]));
                }
            }
        }

        _apps_position = g_list_reverse(_apps_position);

        g_strfreev(list);
    } else {
        g_warning("[%s] get string list from file(%s) failed: %s",
                  __func__, APPS_INI, err->message);
        g_error_free(err);
    }
}

void init_launchers()
{
    if (k_apps == NULL) {
        k_apps = load_app_config(APPS_INI);
        update_dock_apps();
    }
}

PRIVATE
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

PRIVATE
void _save_apps_position()
{
    gsize size = g_list_length(_apps_position);
    GList* _tmp_list = _apps_position;

    const gchar**list = (const gchar**)g_slice_alloc(sizeof(char*) * size);
    for (size_t i=0; i<size; i++) {
        list[i] = _tmp_list->data;
        _tmp_list = g_list_next(_tmp_list);
    }
    g_key_file_set_string_list(k_apps,
                               DOCKED_ITEM_GROUP_NAME,
                               DOCKED_ITEM_KEY_NAME,
                               list,
                               size);
    g_slice_free1(sizeof(char*) * size, list);
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

JS_EXPORT_API
void dock_insert_apps_position(const char* id, const char* anchor_id)
{
    GList* l1 = g_list_find_custom(_apps_position, id, (GCompareFunc)g_strcmp0);
    GList* l2 = g_list_find_custom(_apps_position, anchor_id, (GCompareFunc)g_strcmp0);
    if (l1 == NULL)  {
        return;
    } else if (l2 == NULL) {
        // if anchor_id is null means the l1 should change to the end of the position
        _apps_position = g_list_append(_apps_position, g_strdup(l1->data));
        _apps_position = g_list_delete_link(_apps_position, l1);
    } else {
        _apps_position = g_list_insert_before(_apps_position, l2, g_strdup(l1->data));
        _apps_position = g_list_delete_link(_apps_position, l1);
    }

    _save_apps_position();
    save_app_config(k_apps, APPS_INI);
}

PRIVATE
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
    /* g_warning("[%s] write Name to %s", __func__, g_app_info_get_display_name(G_APP_INFO(info))); */

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


DBUS_EXPORT_API
JS_EXPORT_API
void dock_request_dock(const char* path)
{
    char* unescape_path = g_uri_unescape_string(path, "/:");
    GDesktopAppInfo* info = g_desktop_app_info_new_from_filename(unescape_path);
    g_debug("[%s] info filename: %s", __func__, g_desktop_app_info_get_filename(info));
    g_free(unescape_path);
    if (info != NULL) {
        g_debug("[%s]", __func__);
        char* app_id = get_app_id(info);
        write_app_info(info);
        JSValueRef app_info = build_app_info(app_id);
        if (app_info)
            js_post_message("dock_request", app_info);
        g_free(app_id);
        g_object_unref(info);
    } else {
        g_warning("request dock %s is invalid\n", path);
    }
}

JS_EXPORT_API
void dock_request_undock(const char* app_id)
{
    g_key_file_remove_group(k_apps, app_id, NULL);
    save_app_config(k_apps, APPS_INI);

    JSObjectRef id_info = json_create();
    json_append_string(id_info, "Id", app_id);
    js_post_message("launcher_removed", id_info);
}

JS_EXPORT_API
JSValueRef dock_get_launcher_info(const char* app_id)
{
    if (g_key_file_has_group(k_apps, app_id)) {
        return build_app_info(app_id);
    } else {
        g_debug("try find \"%s\" failed \n", app_id);
        return jsvalue_null();
    }
}

JS_EXPORT_API
gboolean dock_launch_by_app_id(const char* app_id, const char* exec, ArrayContainer fs)
{
    g_assert(app_id != NULL);
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
        GList* all_app_list = g_app_info_get_all();
        for (GList* iter = g_list_first(all_app_list); iter != NULL; iter = g_list_next(iter)) {
            if (g_strrstr(g_desktop_app_info_get_filename((GDesktopAppInfo*)iter->data), app_id) != NULL
                || g_strrstr(g_app_info_get_commandline((GAppInfo*)iter->data), app_id)) {
                info = g_app_info_dup((GAppInfo*)iter->data);
                break;
            }
        }

        g_list_free_full(all_app_list, g_object_unref);
        if (info == NULL)
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
    g_debug("[%s] ", __func__);
    char* id = g_strconcat(name, ".desktop", NULL);
    GDesktopAppInfo* info = g_desktop_app_info_new(id);
    g_free(id);
    if (info != NULL) {
        dock_request_dock(g_desktop_app_info_get_filename(info));
    } else {
        GList* pos = g_list_find_custom(_apps_position, name, (GCompareFunc)g_strcmp0);
        if (pos == NULL) {
            _apps_position = g_list_append(_apps_position, g_strdup(name));

            _save_apps_position();
        }

        if (is_chrome_app(name)) {
            g_debug("[%s] %s is chrome app", __func__, name);
            GKeyFile* f = load_app_config(FILTER_FILE);
            gsize length = 0;
            char** groups = g_key_file_get_groups(f, &length);
            for (gsize i = 0; i < length; ++i) {
                g_assert(groups[i] != NULL);
                char* appid = g_key_file_get_string(f, groups[i], "appid", NULL);
                /* g_warning("[%s] compare #%s# and #%s#", __func__, name, appid); */
                if (appid != NULL && 0 == g_strcmp0(appid, name)) {
                    char* path = g_key_file_get_string(f, groups[i], "path", NULL);
                    /* g_warning("[%s] find path: %s", __func__, path); */
                    g_key_file_set_string(k_apps, name, "Path", path);
                    GDesktopAppInfo* d = g_desktop_app_info_new_from_filename(path);
                    if (d != NULL) {
                        /* g_warning("[%s] ", __func__); */
                        write_app_info(d);
                    }
                    g_object_unref(d);
                    g_free(path);
                    break;
                }
                g_free(appid);
            }
            g_strfreev(groups);
            g_key_file_unref(f);
        } else {
            g_key_file_set_string(k_apps, name, "Name", name);
            g_key_file_set_string(k_apps, name, "CmdLine", cmdline);
            g_key_file_set_string(k_apps, name, "Icon", icon);
        }

        save_app_config(k_apps, APPS_INI);

        if (!is_has_client(name)) {
            JSValueRef app_info = build_app_info(name);
            if (app_info)
                js_post_message("launcher_added", app_info);
        }
    }
    return TRUE;
}


JS_EXPORT_API
void dock_launch_from_commandline(const char* name, const char* cmdline)
{
    GAppInfo* app = g_app_info_create_from_commandline(cmdline, name, G_APP_INFO_CREATE_NONE, NULL);
    GdkAppLaunchContext* launch_context = gdk_display_get_app_launch_context(gdk_display_get_default());
    gdk_app_launch_context_set_icon(launch_context, g_app_info_get_icon(app));
    gboolean ret G_GNUC_UNUSED = g_app_info_launch(app, NULL, (GAppLaunchContext*)launch_context, NULL);
    g_object_unref(launch_context);
    g_object_unref(app);
}

