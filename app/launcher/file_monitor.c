/**
 * Copyright (c) 2011 ~ 2013 Deepin, Inc.
 *               2011 ~ 2013 Liqiang Lee
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

#include "file_monitor.h"
#include "jsextension.h"

#define APP_DIR "applications"
#define DELAY_TIME 3


static gulong timeout_id = 0;


PRIVATE
GPtrArray* _get_all_applications_dirs()
{
    const char *const * dirs = g_get_system_data_dirs();
    GPtrArray* app_dirs = g_ptr_array_new_with_free_func(g_object_unref);

    for (int i = 0; dirs[i] != NULL; ++i) {
        char* app_dir = g_build_filename(dirs[i], APP_DIR, NULL);
        if (g_file_test(app_dir, G_FILE_TEST_EXISTS))
            g_ptr_array_add(app_dirs, g_file_new_for_path(app_dir));
        g_free(app_dir);
    }

    char* user_dir = g_build_path(g_get_user_data_dir(), APP_DIR, NULL);
    if (g_file_test(user_dir, G_FILE_TEST_EXISTS))
        g_ptr_array_add(app_dirs, g_file_new_for_path(user_dir));
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
void monitor_callback(GFileMonitor* monitor, GFile* file, GFile* other_file,
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
    g_warning("[monitor_callback] event type: %s", names[event_type]);
#endif
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
GPtrArray* monitors = NULL;

void monitor_apps()
{
    if (monitors == NULL)
        monitors = g_ptr_array_new_with_free_func(g_object_unref);

    GPtrArray* dirs = _get_all_applications_dirs();
    for (int i = 0; i < dirs->len; ++i) {
        GError* err = NULL;
        GFileMonitor* monitor =
            g_file_monitor_directory((GFile*)g_ptr_array_index(dirs, i),
                                     G_FILE_MONITOR_SEND_MOVED,
                                     NULL,
                                     &err);
        if (err != NULL) {
            g_warning("[monitor_apps] %s", err->message);
            g_error_free(err);
            continue;
        }

        g_debug("[monitor_apps] monitor %s", g_file_get_path(g_ptr_array_index(dirs, i)));
        /* g_file_monitor_set_rate_limit(monitor, min(1)); */
        g_signal_connect(monitor, "changed", G_CALLBACK(monitor_callback), NULL);

        g_ptr_array_add(monitors, monitor);
    }

    g_ptr_array_unref(dirs);
}


void monitor_destroy()
{
    g_ptr_array_unref(monitors);
}

