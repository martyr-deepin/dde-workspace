/**
 * Copyright (c) 2011 ~ 2013 Deepin, Inc.
 *               2013 ~ 2013 Liqiang Lee
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

#include "item.h"
#include "jsextension.h"
#include "utils.h"
#include "xdg_misc.h"


PRIVATE GKeyFile* hidden_apps = NULL;
PRIVATE GPtrArray* autostart_paths = NULL;
PRIVATE GKeyFile* launcher_config = NULL;


void free_resources()
{
    if (hidden_apps != NULL)
        g_key_file_unref(hidden_apps);

    if (autostart_paths != NULL)
        g_ptr_array_unref(autostart_paths);

    if (launcher_config != NULL)
        g_key_file_unref(launcher_config);
}

JS_EXPORT_API
JSValueRef launcher_load_hidden_apps()
{
    if (hidden_apps == NULL) {
        hidden_apps = load_app_config(APPS_INI);
    }

    g_assert(hidden_apps != NULL);
    GError* error = NULL;
    gsize length = 0;
    gchar** raw_hidden_app_ids = g_key_file_get_string_list(hidden_apps,
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
        g_debug("[%s] hidden appid: %s\n", __func__, raw_hidden_app_ids[i]);
        json_array_insert(hidden_app_ids, i, jsvalue_from_cstr(cxt, raw_hidden_app_ids[i]));
    }

    g_strfreev(raw_hidden_app_ids);
    return hidden_app_ids;
}


JS_EXPORT_API
void launcher_save_hidden_apps(ArrayContainer hidden_app_ids)
{
    if (hidden_app_ids.data != NULL) {
        g_key_file_set_string_list(hidden_apps, "__Config__", "app_ids",
            (const gchar* const*)hidden_app_ids.data, hidden_app_ids.num);
        save_app_config(hidden_apps, APPS_INI);
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
    g_debug("[%s] %s exist? %d", __func__, desktop_item_path, is_exist);
    g_free(desktop_item_path);

    return is_exist;
}

GPtrArray* get_autostart_paths()
{
    if (autostart_paths != NULL)
        return g_ptr_array_ref(autostart_paths);

    GPtrArray* paths = g_ptr_array_new_with_free_func(g_free);

    char* autostart_dir = g_build_filename(g_get_user_config_dir(),
                                           AUTOSTART_DIR, NULL);

    if (g_file_test(autostart_dir, G_FILE_TEST_EXISTS))
        g_ptr_array_add(paths, autostart_dir);
    else
        g_free(autostart_dir);

    char const* const* sys_paths = g_get_system_config_dirs();
    for (int i = 0 ; sys_paths[i] != NULL; ++i) {
        autostart_dir = g_build_filename(sys_paths[i], AUTOSTART_DIR, NULL);

        if (g_file_test(autostart_dir, G_FILE_TEST_EXISTS))
            g_ptr_array_add(paths, autostart_dir);
        else
            g_free(autostart_dir);
    }

    return paths;
}

gboolean _read_gnome_autostart_enable(const char* path, const char* name, gboolean* is_autostart/* output */)
{
    gboolean read_success = FALSE;

    char* full_path = g_build_filename(path, name, NULL);
    GKeyFile* candidate_app = g_key_file_new();
    GError* err = NULL;
    g_key_file_load_from_file(candidate_app, full_path, G_KEY_FILE_NONE, &err);

    if (err != NULL) {
        g_warning("[%s] load desktop file(%s) failed: %s", __func__, full_path, err->message);
        goto out;
    }

    gboolean has_autostart_key = g_key_file_has_key(candidate_app,
                                                    G_KEY_FILE_DESKTOP_GROUP,
                                                    GNOME_AUTOSTART_KEY,
                                                    &err);
    if (err != NULL) {
        g_warning("[%s] function g_key_has_key error: %s", __func__, err->message);
        goto out;
    }

    if (has_autostart_key) {
        gboolean gnome_autostart = g_key_file_get_boolean(candidate_app,
                                                          G_KEY_FILE_DESKTOP_GROUP,
                                                          GNOME_AUTOSTART_KEY,
                                                          &err);
        if (err != NULL) {
            g_warning("[%s] get value failed: %s", __func__, err->message);
        } else {
            *is_autostart = gnome_autostart;

            read_success = TRUE;
        }
    }

out:
    if (err != NULL)
        g_error_free(err);
    g_free(full_path);
    g_key_file_unref(candidate_app);

    return read_success;
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

    char* lowercase_name = g_utf8_strdown(name, -1);
    const char* filename = NULL;
    while ((filename = g_dir_read_name(dir)) != NULL) {
        char* lowercase_filename = g_utf8_strdown(filename, -1);

        if (0 == g_strcmp0(lowercase_name, lowercase_filename)) {
            g_free(lowercase_filename);
            is_existing = TRUE;
            break;
        }

        g_free(lowercase_filename);
    }

    g_free(lowercase_name);
    g_dir_close(dir);

    return is_existing;
}


JS_EXPORT_API
gboolean launcher_is_autostart(Entry* _item)
{
    if (autostart_paths == NULL) {
        autostart_paths = get_autostart_paths();
    }

    gboolean is_autostart = FALSE;
    gboolean is_existing = FALSE;
    GDesktopAppInfo* item = (GDesktopAppInfo*)_item;
    char* name = get_desktop_file_basename(item);

    for (int i = 0; i < autostart_paths->len; ++i) {
        char* path = g_ptr_array_index(autostart_paths, i);
        if ((is_existing = _check_exist(path, name))) {
            gboolean gnome_autostart = FALSE;

            if (i == 0 && _read_gnome_autostart_enable(path, name, &gnome_autostart)) {
                // user config
                is_autostart = gnome_autostart;
            } else {
                is_autostart = is_existing;
            }

            break;
        }
    }

    g_free(name);

    return is_autostart;
}


JS_EXPORT_API
gboolean launcher_add_to_autostart(Entry* _item)
{
    if (launcher_is_autostart(_item)){
        g_debug("[%s] already autostart", __func__);
        return TRUE;
    }

    gboolean success = TRUE;
    const char* item_path = g_desktop_app_info_get_filename(G_DESKTOP_APP_INFO(_item));
    GFile* item = g_file_new_for_path(item_path);

    char* app_name = g_path_get_basename(item_path);
    const char* config_dir = g_get_user_config_dir();
    char* dest_path = g_build_filename(config_dir, AUTOSTART_DIR, app_name, NULL);
    g_free(app_name);

    if (!g_file_test(dest_path, G_FILE_TEST_EXISTS)) {
        GFile* dest = g_file_new_for_path(dest_path);

        do_dereference_symlink_copy(item, dest, G_FILE_COPY_NONE);
        g_object_unref(dest);
    }

    g_object_unref(item);

    GKeyFile* dst = g_key_file_new();
    GError* err = NULL;
    g_key_file_load_from_file(dst, dest_path, G_KEY_FILE_NONE, &err);

    if (err != NULL) {
        g_warning("[%s] load file(%s) failed: %s", __func__, dest_path, err->message);
        g_error_free(err);
        success = FALSE;
        goto out;
    }

    g_key_file_set_boolean(dst, G_KEY_FILE_DESKTOP_GROUP,
                           GNOME_AUTOSTART_KEY, true);
    save_key_file(dst, dest_path);

out:
    g_free(dest_path);
    g_key_file_unref(dst);
    return success;
}


PRIVATE
gboolean _remove_autostart(const char* file_path)
{
    GKeyFile* file = g_key_file_new();
    GError* error = NULL;
    g_key_file_load_from_file(file, file_path, G_KEY_FILE_NONE, &error);
    if (error != NULL) {
        g_warning("[%s] load file(%s) failed: %s", __func__, file_path, error->message);
        g_error_free(error);
        g_key_file_unref(file);
        return FALSE;
    }

    g_key_file_set_boolean(file, G_KEY_FILE_DESKTOP_GROUP,
                           GNOME_AUTOSTART_KEY, FALSE);
    save_key_file(file, file_path);
    g_key_file_unref(file);
    return TRUE;
}


JS_EXPORT_API
gboolean launcher_remove_from_autostart(Entry* _item)
{
    if (!launcher_is_autostart(_item)) {
        g_debug("[%s] already not autostart", __func__);
        return TRUE;
    }

    gboolean success = FALSE;
    GDesktopAppInfo* item = (GDesktopAppInfo*)_item;
    char* name = get_desktop_file_basename(item);

    char* dest_path = g_build_filename(g_get_user_config_dir(),
                                       AUTOSTART_DIR, name, NULL);
    if (g_file_test(dest_path, G_FILE_TEST_EXISTS)) {
        success = _remove_autostart(dest_path);
        goto out;
    }

    to_lower_inplace(name);

    // start from 1 for skiping user autostart dir
    for (int i = 1; i < autostart_paths->len; ++i) {
        char* path = g_ptr_array_index(autostart_paths, i);
        GError* err = NULL;
        GDir* dir = g_dir_open(path, 0, &err);
        if (dir == NULL) {
            g_warning("[%s] open dir(%s) failed: %s", __func__, path, err->message);
            g_error_free(err);
            break;
        }

        const char* filename = NULL;
        while ((filename = g_dir_read_name(dir)) != NULL) {
            char* lowercase_name = g_utf8_strdown(filename, -1);

            if (0 == g_strcmp0(name, lowercase_name)) {
                g_free(lowercase_name);
                g_dir_close(dir);

                GFile* dest_file = g_file_new_for_path(dest_path);

                char* file_path = g_build_filename(path, filename, NULL);
                GFile* src_file = g_file_new_for_path(file_path);
                g_free(file_path);

                do_dereference_symlink_copy(src_file, dest_file, G_FILE_COPY_NONE);
                g_object_unref(src_file);
                g_object_unref(dest_file);

                success = _remove_autostart(dest_path);

                goto out;
            }

            g_free(lowercase_name);
        }

        g_dir_close(dir);
    }

out:
    g_free(dest_path);
    g_free(name);
    return success;
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

