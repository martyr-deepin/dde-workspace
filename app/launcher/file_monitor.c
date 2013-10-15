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

#include <glib.h>
#include <gio/gio.h>
#include <gio/gdesktopappinfo.h>

#include "file_monitor.h"
#include "jsextension.h"
#include "item.h"

#define APP_DIR "applications"
#define DELAY_TIME 3
#define AUTOSTART_DELAY_TIME 100


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

    char* user_dir = g_build_path(g_get_user_data_dir(), APP_DIR, NULL);
    if (g_file_test(user_dir, G_FILE_TEST_EXISTS))
        g_ptr_array_add(app_dirs, g_strdup(user_dir));
    g_free(user_dir);

    return app_dirs;
}


static
gboolean _update_times(gpointer user_data)
{
    js_post_message_simply("update_items", NULL);
    return FALSE;
}


PRIVATE
GPtrArray* desktop_monitors = NULL;
GPtrArray* autostart_monitors = NULL;


PRIVATE
void append_monitor(GPtrArray* monitors, GPtrArray* paths, GCallback monitor_callback)
{
    // check NULL to avoid the last one is NULL
    for (int i = 0; i < paths->len && g_ptr_array_index(paths, i) != NULL; ++i) {
        GError* err = NULL;
        GFileMonitor* monitor =
            g_file_monitor_directory(g_file_new_for_path(g_ptr_array_index(paths, i)),
                                     G_FILE_MONITOR_SEND_MOVED,
                                     NULL,
                                     &err);
        if (err != NULL) {
            g_warning("[%s] %s", __func__, err->message);
            g_error_free(err);
            continue;
        }

        g_debug("[%s] monitor %s", __func__, (char*)g_ptr_array_index(paths, i));
        /* g_file_monitor_set_rate_limit(monitor, min(1)); */
        g_signal_connect(monitor, "changed", monitor_callback, NULL);

        g_ptr_array_add(monitors, monitor);
    }
}


PRIVATE
void desktop_monitor_callback(GFileMonitor* monitor, GFile* file, GFile* other_file,
                              GFileMonitorEvent event_type, gpointer data)
{
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
    g_warning("[%s] event type: %s", __func__, names[event_type]);
#endif

    static gulong timeout_id = 0;
    switch (event_type) {
        // fall through
    case G_FILE_MONITOR_EVENT_DELETED:
    case G_FILE_MONITOR_EVENT_CREATED:
    case G_FILE_MONITOR_EVENT_MOVED:
        if (timeout_id != 0) {
            g_source_remove(timeout_id);
            timeout_id = 0;
        }

        timeout_id = g_timeout_add_seconds(DELAY_TIME, _update_times, NULL);
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


gboolean _update_autostart(gpointer user_data)
{
    char* uri = (char*)user_data;
    char* id = calc_id(uri);

    g_debug("[%s] %s is changed", __func__, uri);
    js_post_message_simply("autostart-update", "{\"id\": \"%s\"}", id);

    g_free(uri);
    g_free(id);

    return FALSE;
}


PRIVATE
void autostart_monitor_callback(GFileMonitor* monitor, GFile* file, GFile* other_file,
                                GFileMonitorEvent event_type, gpointer data)
{
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
        char* uri = g_file_get_uri(file);
        char* escaped_uri = g_uri_escape_string(uri, G_URI_RESERVED_CHARS_ALLOWED_IN_PATH, FALSE);
        g_free(uri);
        timeout_id = g_timeout_add(AUTOSTART_DELAY_TIME, _update_autostart,
                                   g_strdup(escaped_uri));
        g_free(escaped_uri);
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


void add_monitors()
{
    _monitor_desktop_files();
    _monitor_autostart_files();
}


void destroy_monitors()
{
    if (desktop_monitors != NULL)
        g_ptr_array_unref(desktop_monitors);

    if (autostart_monitors != NULL)
        g_ptr_array_unref(autostart_monitors);
}

