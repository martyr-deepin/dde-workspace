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

#include <stdlib.h>

#include <glib.h>
#include <gio/gio.h>
#include <gio/gdesktopappinfo.h>

#include "dentry/entry.h"
#include "jsextension.h"
#include "utils.h"
#include "item.h"
#include "category.h"
#include "background.h"
#include "file_monitor.h"
#include "launcher_category.h"

#define APP_DIR "applications"
#define DELAY_TIME 3
#define AUTOSTART_DELAY_TIME 100


static GPtrArray* desktop_monitors = NULL;
static GPtrArray* autostart_monitors = NULL;
static GFileMonitor* gaussian_background_monitor = NULL;


PRIVATE
GFileMonitor* create_monitor(const char* path, GCallback monitor_callback)
{
    GError* err = NULL;
    GFile* file = g_file_new_for_path(path);
    GFileMonitor* monitor = g_file_monitor(file,
                                           G_FILE_MONITOR_SEND_MOVED,
                                           NULL,
                                           &err);
    g_object_unref(file);
    if (err != NULL) {
        g_warning("[%s] monitor %s failed: %s", __func__, path, err->message);
        g_error_free(err);
        return NULL;
    }

    g_debug("[%s] monitor %s", __func__, path);
    g_signal_connect(monitor, "changed", monitor_callback, NULL);

    return monitor;
}


PRIVATE
void append_monitor(GPtrArray* monitors, const GPtrArray* paths, GCallback monitor_callback)
{
    // check NULL to avoid the last one is NULL
    for (guint i = 0; i < paths->len && g_ptr_array_index(paths, i) != NULL; ++i) {
        GFileMonitor* monitor = create_monitor(g_ptr_array_index(paths, i), monitor_callback);
        if (monitor != NULL)
            g_ptr_array_add(monitors, monitor);
    }
}


PRIVATE
GPtrArray* _get_all_applications_dirs()
{
    const char *const * dirs = g_get_system_data_dirs();
    GPtrArray* app_dirs = g_ptr_array_new_with_free_func(g_free);

    for (int i = 0; dirs[i] != NULL; ++i) {
        char* app_dir = g_build_filename(dirs[i], APP_DIR, NULL);
        if (g_file_test(app_dir, G_FILE_TEST_EXISTS))
            g_ptr_array_add(app_dirs, g_strdup(app_dir));
        g_free(app_dir);
    }

    char* user_dir = g_build_filename(g_get_user_data_dir(), APP_DIR, NULL);
    if (g_file_test(user_dir, G_FILE_TEST_EXISTS))
        g_ptr_array_add(app_dirs, g_strdup(user_dir));
    g_free(user_dir);

    return app_dirs;
}


PRIVATE
struct DesktopInfo* desktop_info_create()
{
    struct DesktopInfo* info = g_slice_new0(struct DesktopInfo);
    info->status = UNKNOWN;

    return info;
}


PRIVATE
void desktop_info_destroy(struct DesktopInfo* di)
{
    g_free(di->id);
    g_free(di->path);

    if (di->core != NULL)
        g_object_unref(di->core);

    if (di->categories)
        g_list_free(di->categories);

    g_slice_free(struct DesktopInfo, di);
}


PRIVATE
gboolean _update_items(gpointer user_data)
{
    struct DesktopInfo* info = (struct DesktopInfo*)user_data;

    if (info->status != DELETED) {
        GKeyFile* valid_file = g_key_file_new();
        GError* error = NULL;
        g_key_file_load_from_file(valid_file, info->path, 0, &error);
        if (error != NULL) {
            g_warning("[%s] desktop file(\"%s\") is changed and it's INVALID: %s",
                      __func__, info->path, error->message);
            g_key_file_unref(valid_file);
            g_clear_error(&error);
            return G_SOURCE_REMOVE;
        }
        g_key_file_unref(valid_file);
    }

    const char* status = NULL;
    switch(info->status) {
    case UPDATED:  // distinguish between added and changed in front end
        status = "updated";
        break;
    case DELETED:
        status = "deleted";
        break;
    case UNKNOWN:
        status = "unknown";
        break;
    }

    g_message("status is %s", status);

    JSObjectRef update_info = json_create();
    json_append_string(update_info, "status", status);
    json_append_string(update_info, "id", info->id);

    if (info->status == DELETED) {
        json_append_value(update_info, "core", jsvalue_null());
    } else {
        // add ref because desktop_info_destroy will unref.
        json_append_nobject(update_info, "core", g_object_ref(info->core),
                            g_object_ref, g_object_unref);
    }

    JSObjectRef categories = json_array_create();
    int i = 0;
    json_array_insert(categories, i++,
                      jsvalue_from_number(get_global_context(), ALL_CATEGORY_ID));
    for (GList* iter = g_list_first(info->categories); iter != NULL;
         iter = g_list_next(iter)) {
        double category_index = GPOINTER_TO_INT(iter->data);
        json_array_insert(categories, i++,
                          jsvalue_from_number(get_global_context(), category_index));
    }
    json_append_value(update_info, "categories", categories);

    js_post_message("update_items", update_info);

    return G_SOURCE_REMOVE;
}



PRIVATE
void desktop_monitor_callback(GFileMonitor* monitor, GFile* file, GFile* other_file,
                              GFileMonitorEvent event_type, gpointer data)
{
    NOUSED(monitor);
    NOUSED(data);
#if 0
    static char* names[] = {
        "changed",
        "changes_done_hint",
        "deleted",
        "created",
        "attribute_changed",
        "per_unmount",
        "mount",
        "moved",
    };
    char* file_path = g_file_get_path(file);
    char* other_file_path = other_file != NULL ? g_file_get_path(other_file) : NULL;
    g_warning("[%s] #%s#%s# event type: %s", __func__, file_path, other_file_path, names[event_type]);
    g_free(file_path);
    g_free(other_file_path);
#endif

    static gulong timeout_id = 0;
    char* escaped_uri = NULL;

    struct DesktopInfo* info = desktop_info_create();

    switch (event_type) {
    case G_FILE_MONITOR_EVENT_DELETED:
#ifndef NDEBUG
        g_message("[%s] G_FILE_MONITOR_EVENT_DELETED", __func__);
#endif
        escaped_uri = dentry_get_uri(file);
        if (g_str_has_suffix(escaped_uri, ".desktop")) {
            info->id = calc_id(escaped_uri);
            info->path = g_file_get_path(file);
            info->status = DELETED;
            info->categories = lookup_categories(info->id);
            if (info->categories == NULL) g_warning("=====================");
            info->core = NULL;

            remove_category_info(file);
            g_message("[%s] '%s' is deleted", __func__, escaped_uri);
        }
        break;

    case G_FILE_MONITOR_EVENT_MOVED:
#ifndef NDEBUG
        g_message("[%s] G_FILE_MONITOR_EVENT_MOVED", __func__);
#endif
        info->path = g_file_get_path(other_file);
        if (g_str_has_suffix(info->path, ".desktop")) {
            escaped_uri = dentry_get_uri(other_file);
            info->id = calc_id(escaped_uri);
            info->status = UPDATED;

            // have to use path not uri.
            info->core = g_desktop_app_info_new_from_filename(info->path);
            info->categories = get_categories(info->core);

            record_category_info(info->core);
            g_message("[%s] '%s' is added", __func__, escaped_uri);
        }
        break;

    case G_FILE_MONITOR_EVENT_CHANGES_DONE_HINT:
#ifndef NDEBUG
        g_message("[%s] G_FILE_MONITOR_EVENT_CHANGES_DONE_HINT", __func__);
#endif
        info->path = g_file_get_path(file);
        if (g_str_has_suffix(info->path, ".desktop")) {
            escaped_uri = dentry_get_uri(file);
            info->id = calc_id(escaped_uri);
            info->status = UPDATED;

            info->core = g_desktop_app_info_new_from_filename(info->path);
            info->categories = get_categories(info->core);

            record_category_info(info->core);
            g_message("[%s] '%s' is changed/added", __func__, escaped_uri);
        }
        break;
    case G_FILE_MONITOR_EVENT_CHANGED:
    case G_FILE_MONITOR_EVENT_CREATED:
    case G_FILE_MONITOR_EVENT_ATTRIBUTE_CHANGED:
    case G_FILE_MONITOR_EVENT_PRE_UNMOUNT:
    case G_FILE_MONITOR_EVENT_UNMOUNTED:
        break;
    }

    g_free(escaped_uri);

    if (info->status != UNKNOWN) {
        if (timeout_id != 0) {
            g_source_remove(timeout_id);
            timeout_id = 0;
        }

        timeout_id = g_timeout_add_full(G_PRIORITY_DEFAULT,
                                        AUTOSTART_DELAY_TIME,
                                        _update_items,
                                        info,
                                        (GDestroyNotify)desktop_info_destroy);
    } else {
        desktop_info_destroy(info);
    }
}


PRIVATE
void _monitor_desktop_files()
{
    if (desktop_monitors == NULL)
        desktop_monitors = g_ptr_array_new_with_free_func(g_object_unref);

    GPtrArray* dirs = _get_all_applications_dirs();
    append_monitor(desktop_monitors, dirs, G_CALLBACK(desktop_monitor_callback));
    g_ptr_array_unref(dirs);
}


PRIVATE
gboolean _update_autostart(gpointer user_data)
{
    char* uri = (char*)user_data;
    char* id = calc_id(uri);

    g_debug("[%s] %s is changed", __func__, uri);
    JSObjectRef id_info = json_create();
    json_append_string(id_info, "id", id);
    js_post_message("autostart_update", id_info);

    g_free(id);

    return G_SOURCE_REMOVE;
}


PRIVATE
void autostart_monitor_callback(GFileMonitor* monitor, GFile* file, GFile* other_file,
                                GFileMonitorEvent event_type, gpointer data)
{
    NOUSED(monitor);
    NOUSED(data);
    GFile* changed_file = file;
    static gulong timeout_id = 0;
    switch (event_type) {
        // fall through
    case G_FILE_MONITOR_EVENT_MOVED:  // compatibility for gnome-session-properties
        changed_file = other_file;
    case G_FILE_MONITOR_EVENT_DELETED:
    case G_FILE_MONITOR_EVENT_CHANGES_DONE_HINT:
        if (timeout_id != 0) {
            g_source_remove(timeout_id);
            timeout_id = 0;
        }

        g_debug("[%s] delete or changed", __func__);
        char* uri = g_file_get_uri(changed_file);
        if (g_str_has_suffix(uri, ".desktop")) {
            char* escaped_uri = g_uri_escape_string(uri,
                                                    G_URI_RESERVED_CHARS_ALLOWED_IN_PATH,
                                                    FALSE);
            timeout_id = g_timeout_add_full(G_PRIORITY_DEFAULT,
                                            AUTOSTART_DELAY_TIME,
                                            _update_autostart,
                                            escaped_uri,
                                            g_free);
        }
        g_free(uri);
    case G_FILE_MONITOR_EVENT_CHANGED:
    case G_FILE_MONITOR_EVENT_ATTRIBUTE_CHANGED:
    case G_FILE_MONITOR_EVENT_PRE_UNMOUNT:
    case G_FILE_MONITOR_EVENT_UNMOUNTED:
    case G_FILE_MONITOR_EVENT_CREATED:
        break;
    }
}


PRIVATE
void _monitor_autostart_files()
{
    if (autostart_monitors == NULL)
        autostart_monitors = g_ptr_array_new_with_free_func(g_object_unref);

    GPtrArray* autostart_paths = get_autostart_paths();
    append_monitor(autostart_monitors, autostart_paths,
                   G_CALLBACK(autostart_monitor_callback));
    g_ptr_array_unref(autostart_paths);
}


void gaussian_update(GFileMonitor* monitor,
                     GFile* origin_file,
                     GFile* new_file,
                     GFileMonitorEvent event_type,
                     gpointer user_data)
{
    NOUSED(monitor);
    NOUSED(origin_file);
    NOUSED(user_data);
    switch (event_type) {
    case G_FILE_MONITOR_EVENT_MOVED: {
        // gaussian picture is generated.
        char* path = g_file_get_path(new_file);

        GSettings* settings = get_background_gsettings();
        char* bg_path = g_settings_get_string(settings, CURRENT_PCITURE);
        char* blur_path = bg_blur_pict_get_dest_path(bg_path);
        g_free(bg_path);

        if (g_strcmp0(path, blur_path) == 0)
            background_changed(settings, CURRENT_PCITURE, NULL);

        g_free(blur_path);
        g_free(path);
    }
    case G_FILE_MONITOR_EVENT_CHANGED:
    case G_FILE_MONITOR_EVENT_CHANGES_DONE_HINT:
    case G_FILE_MONITOR_EVENT_DELETED:
    case G_FILE_MONITOR_EVENT_CREATED:
    case G_FILE_MONITOR_EVENT_ATTRIBUTE_CHANGED:
    case G_FILE_MONITOR_EVENT_PRE_UNMOUNT:
    case G_FILE_MONITOR_EVENT_UNMOUNTED:
        break;
    }
}


PRIVATE
void _monitor_gaussian_background()
{
    char* path = g_build_filename(g_get_user_cache_dir(), "gaussian-background", NULL);
    gaussian_background_monitor = create_monitor(path, G_CALLBACK(gaussian_update));
    g_free(path);
}


void add_monitors()
{
    _monitor_desktop_files();
    _monitor_autostart_files();
    _monitor_gaussian_background();
}


void destroy_monitors()
{
    if (desktop_monitors != NULL)
        g_ptr_array_unref(desktop_monitors);

    if (autostart_monitors != NULL)
        g_ptr_array_unref(autostart_monitors);

    if (gaussian_background_monitor != NULL)
        g_clear_pointer(&gaussian_background_monitor, g_object_unref);
}

