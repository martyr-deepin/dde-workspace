/**
 * Copyright (c) 2011 ~ 2012 Deepin, Inc.
 *               2011 ~ 2012 Liqiang Lee
 *
 * Author:      Liqiang Lee <liliqiang@linuxdeepin.com>
 * Maintainer:  Liqiang Lee <liliqiang@linuxdeepin.com>
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

#include <string.h>

#include <gio/gdesktopappinfo.h>

#include "jsextension.h"
#include "dentry/entry.h"
#include "utils.h"
#include "xdg_misc.h"
#include "item.h"
#include "DBUS_launcher.h"

#define SOFTWARE_CENTER_NAME "com.linuxdeepin.softwarecenter"
#define SOFTWARE_CENTER_PATH "/com/linuxdeepin/softwarecenter"
#define SOFTWARE_CENTER_INTERFACE SOFTWARE_CENTER_NAME

PRIVATE GKeyFile* hidden_app_conf = NULL;
PRIVATE GKeyFile* launcher_config = NULL;
PRIVATE GPtrArray* config_paths = NULL;

void destroy_config_file()
{
    g_key_file_free(hidden_app_conf);
    g_key_file_free(launcher_config);
    g_ptr_array_unref(config_paths);
}

JS_EXPORT_API
JSValueRef launcher_load_hidden_apps()
{
    if (hidden_app_conf == NULL) {
        hidden_app_conf = load_app_config(APPS_INI);
    }

    g_assert(hidden_app_conf != NULL);
    GError* error = NULL;
    gsize length = 0;
    gchar** raw_hidden_app_ids = g_key_file_get_string_list(hidden_app_conf,
                                                            "__Config__",
                                                            "app_ids",
                                                            &length,
                                                            &error);
    if (raw_hidden_app_ids == NULL) {
        g_warning("read config file %s/%s failed: %s", g_get_user_config_dir(),
                  APPS_INI, error->message);
        g_error_free(error);
        return jsvalue_null();
    }

    JSObjectRef hidden_app_ids = json_array_create();
    JSContextRef cxt = get_global_context();
    for (gsize i = 0; i < length; ++i) {
        g_debug("%s\n", raw_hidden_app_ids[i]);
        json_array_insert(hidden_app_ids, i, jsvalue_from_cstr(cxt, raw_hidden_app_ids[i]));
    }

    g_strfreev(raw_hidden_app_ids);
    return hidden_app_ids;
}


JS_EXPORT_API
void launcher_save_hidden_apps(ArrayContainer hidden_app_ids)
{
    if (hidden_app_ids.data != NULL) {
        g_key_file_set_string_list(hidden_app_conf, "__Config__", "app_ids",
            (const gchar* const*)hidden_app_ids.data, hidden_app_ids.num);
        save_app_config(hidden_app_conf, APPS_INI);
    }
}


JS_EXPORT_API
gboolean launcher_has_this_item_on_desktop(Entry* _item)
{
    GDesktopAppInfo* item = (GDesktopAppInfo*)_item;
    const char* item_path = g_desktop_app_info_get_filename(item);
    char* basename = g_path_get_basename(item_path);
    char* desktop_item_path = g_build_filename(DESKTOP_DIR(), basename, NULL);

    GFile* desktop_item = g_file_new_for_path(desktop_item_path);
    g_free(basename);

    gboolean is_exist = g_file_query_exists(desktop_item, NULL);
    g_object_unref(desktop_item);
    g_debug("%s exist? %d", desktop_item_path, is_exist);
    g_free(desktop_item_path);

    return is_exist;
}


void _init_config_path()
{
    config_paths = g_ptr_array_new_with_free_func(g_free);

    char* autostart_dir = g_build_filename(g_get_user_config_dir(),
                                           AUTOSTART_DIR, NULL);

    if (g_file_test(autostart_dir, G_FILE_TEST_EXISTS))
        g_ptr_array_add(config_paths, autostart_dir);
    else
        g_free(autostart_dir);

    char const* const* sys_paths = g_get_system_config_dirs();
    for (int i = 0 ; sys_paths[i] != NULL; ++i) {
        autostart_dir = g_build_filename(sys_paths[i], AUTOSTART_DIR, NULL);

        if (g_file_test(autostart_dir, G_FILE_TEST_EXISTS))
            g_ptr_array_add(config_paths, autostart_dir);
        else
            g_free(autostart_dir);
    }

    g_ptr_array_add(config_paths, NULL);
}

gboolean _read_gnome_autostart_enable(const char* path, const char* name, gboolean* is_autostart)
{
    gboolean is_success = FALSE;

    char* full_path = g_build_filename(path, name, NULL);
    GKeyFile* candidate_app = g_key_file_new();
    GError* err = NULL;
    g_key_file_load_from_file(candidate_app, full_path, G_KEY_FILE_NONE, &err);

    if (err != NULL) {
        g_warning("[_read_gnome_autostart_enable] load desktop file(%s) failed: %s", full_path, err->message);
        goto out;
    }

    gboolean has_autostart_key = g_key_file_has_key(candidate_app,
                                                    G_KEY_FILE_DESKTOP_GROUP,
                                                    GNOME_AUTOSTART_KEY,
                                                    &err);
    if (err != NULL) {
        g_warning("[_read_gnome_autostart_enable] function g_key_has_key error: %s", err->message);
        goto out;
    }

    if (has_autostart_key) {
        gboolean gnome_autostart = g_key_file_get_boolean(candidate_app,
                                                          G_KEY_FILE_DESKTOP_GROUP,
                                                          GNOME_AUTOSTART_KEY,
                                                          &err);
        if (err != NULL) {
            g_warning("[_read_gnome_autostart_enable] get value failed: %s", err->message);
        } else {
            *is_autostart = gnome_autostart;
        }

        is_success = TRUE;
    }

out:
    g_free(full_path);
    if (err != NULL)
        g_error_free(err);
    g_key_file_unref(candidate_app);
    return is_success;
}

PRIVATE
gboolean _check_exist(const char* path, const char* name)
{
    GError* err = NULL;
    GDir* dir = g_dir_open(path, 0, &err);

    if (dir == NULL) {
        g_warning("[_check_exist] open dir(%s) failed: %s", path, err->message);
        g_error_free(err);
        return FALSE;
    }

    gboolean is_existing = FALSE;

    const char* filename = NULL;
    while ((filename = g_dir_read_name(dir)) != NULL) {
        char* lowercase_name = g_utf8_strdown(filename, -1);

        if (0 == g_strcmp0(name, lowercase_name)) {
            g_free(lowercase_name);
            is_existing = TRUE;
            break;
        }

        g_free(lowercase_name);
    }

    g_dir_close(dir);

    return is_existing;
}


JS_EXPORT_API
gboolean launcher_is_autostart(Entry* _item)
{
    if (config_paths == NULL) {
        _init_config_path();
    }


    gboolean is_autostart = FALSE;
    gboolean is_existing = FALSE;
    GDesktopAppInfo* item = (GDesktopAppInfo*)_item;
    char* name = get_desktop_file_basename(item);
    char* lowcase_name = g_utf8_strdown(name, -1);
    g_free(name);

    char* path = NULL;
    for (int i = 0; (path = (char*)g_ptr_array_index(config_paths, i)) != NULL; ++i) {
        if ((is_existing = _check_exist(path, lowcase_name))) {
            gboolean gnome_autostart = FALSE;


            if (i == 0 && _read_gnome_autostart_enable(path, lowcase_name, &gnome_autostart)) {
                // user config
                is_autostart = gnome_autostart;
            } else {
                is_autostart = is_existing;
            }

            break;
        }
    }

    g_free(lowcase_name);

    return is_autostart;
}


JS_EXPORT_API
void launcher_add_to_autostart(Entry* _item)
{
    if (launcher_is_autostart(_item))
        return;

    const char* item_path = g_desktop_app_info_get_filename(G_DESKTOP_APP_INFO(_item));
    GFile* item = g_file_new_for_path(item_path);

    char* app_name = g_path_get_basename(item_path);
    const char* config_dir = g_get_user_config_dir();
    char* dest_path = g_build_filename(config_dir, AUTOSTART_DIR, app_name, NULL);
    g_free(app_name);

    GFile* dest = g_file_new_for_path(dest_path);
    g_free(dest_path);

    do_dereference_symlink_copy(item, dest, G_FILE_COPY_NONE);
    g_object_unref(dest);
    g_object_unref(item);
}


JS_EXPORT_API
gboolean launcher_remove_from_autostart(Entry* _item)
{
    GDesktopAppInfo* item = (GDesktopAppInfo*)_item;

    if (config_paths == NULL) {
        _init_config_path();
    }

    int i = 0;
    char* path = NULL;
    while ((path = (char*)g_ptr_array_index(config_paths, i++)) != NULL) {
        GDir* dir = g_dir_open(path, 0, NULL);
        if (dir == NULL)
            return FALSE;

        char* name = get_desktop_file_basename(item);

        const char* filename = NULL;
        while ((filename = g_dir_read_name(dir)) != NULL) {
            char* lowercase_name = g_utf8_strdown(filename, -1);

            if (0 == g_strcmp0(name, lowercase_name)) {
                g_free(lowercase_name);
                char* file_path = g_build_filename(path, filename, NULL);
                GFile* file = g_file_new_for_path(file_path);
                g_free(file_path);
                GError* error = NULL;
                gboolean success = g_file_delete(file, NULL, &error);
                if (!success) {
                    g_warning("delete file failed: %s", error->message);
                    g_error_free(error);
                }
                g_object_unref(file);
                return success;
            }

            g_free(lowercase_name);
        }

        g_dir_close(dir);
        g_free(name);
    }

    return FALSE;
}


JS_EXPORT_API
JSValueRef launcher_sort_method()
{
    if (launcher_config == NULL) {
        launcher_config = load_app_config(LAUNCHER_CONF);
    }

    GError* error = NULL;
    char* sort_method = g_key_file_get_string(launcher_config, "main", "sort_method", &error);
    if (error != NULL) {
        g_warning("get sort method error: %s", error->message);
        g_error_free(error);
        return jsvalue_null();
    }


    JSContextRef ctx = get_global_context();
    JSValueRef method = jsvalue_from_cstr(ctx, sort_method);

    g_free(sort_method);

    return method;
}


JS_EXPORT_API
void launcher_save_config(char const* key, char const* value)
{
    if (launcher_config == NULL)
        launcher_config = load_app_config(LAUNCHER_CONF);

    g_key_file_set_string(launcher_config, "main", "sort_method", value);

    save_app_config(launcher_config, LAUNCHER_CONF);
}


JS_EXPORT_API
JSValueRef launcher_get_app_rate()
{
    GKeyFile* record_file = load_app_config("dock/record.ini");

    gsize size = 0;
    char** groups = g_key_file_get_groups(record_file, &size);

    JSObjectRef json = json_create();

    for (int i = 0; i < size; ++i) {
        GError* error = NULL;
        gint64 num = g_key_file_get_int64(record_file, groups[i], "StartNum", &error);

        if (error != NULL) {
            g_warning("get record file value failed: %s", error->message);
            continue;
        }

        json_append_number(json, groups[i], num);
    }

    g_strfreev(groups);
    g_key_file_free(record_file);

    return json;
}


PRIVATE
char* _get_pkg_name(const char* name)
{
    GError* err = NULL;
    gint exit_status = 0;
    char* cmd[] = { "dpkg", "-S", (char*)name, NULL};
    char* output = NULL;

    if (!g_spawn_sync(NULL, cmd, NULL,
                      G_SPAWN_SEARCH_PATH
                      | G_SPAWN_STDERR_TO_DEV_NULL,
                      NULL, NULL, &output, NULL, &exit_status, &err)) {
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


PRIVATE
gboolean _uninstall_pkg(const char* pkg_name, gboolean is_purge)
{
    GDBusConnection* conn = g_bus_get_sync(G_BUS_TYPE_SYSTEM, NULL, NULL);
    GError* err = NULL;
    g_dbus_connection_call_sync(conn,
                                SOFTWARE_CENTER_NAME,
                                SOFTWARE_CENTER_PATH,
                                SOFTWARE_CENTER_INTERFACE,
                                "uninstall_pkg",
                                g_variant_new("(sb)", pkg_name, is_purge),
                                NULL,
                                G_DBUS_CALL_FLAGS_NONE,
                                -1,
                                NULL,
                                &err
                               );
    if (err != NULL) {
        g_warning("%s", err->message);
        g_error_free(err);
        return FALSE;
    }

    g_object_unref(conn);
    return TRUE;
}


JS_EXPORT_API
gboolean launcher_uninstall(Entry* _item)
{
    GDesktopAppInfo* item = G_DESKTOP_APP_INFO(_item);
    const char* filename = g_desktop_app_info_get_filename(item);
    char* name = g_path_get_basename(filename);

    char* pkg_name = _get_pkg_name(name);
    g_free(name);

    gboolean is_uninstall_successful = FALSE;

    if (pkg_name != NULL) {
        is_uninstall_successful = _uninstall_pkg(pkg_name, TRUE);
        g_free(pkg_name);
    } else {
    }

    return is_uninstall_successful;
}

