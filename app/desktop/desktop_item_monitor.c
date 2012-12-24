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
#include "dwebview.h"
#include "xdg_misc.h"
#include "utils.h"
#include <gio/gio.h>
#include <glib/gprintf.h>

GFile* _desktop = NULL;

JS_EXPORT_API
void desktop_cancel_monitor_dir(const char* path);

JS_EXPORT_API
void begin_monitor_dir(const char* path, GCallback cb);
void end_monitor_dir(const char* path);

static
void monitor_dir_cb(GFileMonitor *m, GFile *file, GFile *other, GFileMonitorEvent t, const char* _path);

static
void monitor_desktop_dir_cb(GFileMonitor *m, GFile *file, GFile *other, GFileMonitorEvent t, gpointer user_data);

GHashTable *monitor_table = NULL;

void monitor_desktop_dir_cb(GFileMonitor *m, 
        GFile *file, GFile *other, GFileMonitorEvent t, 
        gpointer user_data)
{
    switch (t) {
        case G_FILE_MONITOR_EVENT_MOVED:
            {
                JSObjectRef json = json_create();
                json_append_nobject(json, "old", file, g_object_ref, g_object_unref);
                json_append_nobject(json, "new", other, g_object_ref, g_object_unref);
                js_post_message("item_rename", json);
                break;
            }
        case G_FILE_MONITOR_EVENT_DELETED:
            {
                char* path = g_file_get_path(file);

                g_hash_table_remove(monitor_table, path); //if the path is not an monitored dir, the remove operation will no effect.

                if (g_file_equal(file, _desktop)) {
                    g_assert_not_reached();
                    /*desktop_cancel_monitor_dir(path);*/
                    /*g_object_unref(_desktop);*/
                    /*char* desktop = get_desktop_dir(TRUE);*/
                    /*[>begin_monitor_dir(desktop, G_CALLBACK(monitor_desktop_dir_cb));<]*/
                    /*g_free(desktop);*/
                } else {
                    JSObjectRef json = json_create();
                    json_append_nobject(json, "entry", file, g_object_ref, g_object_unref);
                    js_post_message("item_delete", json);
                }
                g_free(path);
                break;
            }
        case G_FILE_MONITOR_EVENT_CREATED:
            {
                char* path = g_file_get_path(file);
                if (g_file_test(path, G_FILE_TEST_IS_DIR)) {
                    begin_monitor_dir(path, G_CALLBACK(monitor_dir_cb));
                }

                JSObjectRef json = json_create();
                json_append_nobject(json, "entry", file, g_object_ref, g_object_unref);
                js_post_message("item_update", json);

                g_free(path);
                break;
            }
    }
}

void monitor_dir_cb(GFileMonitor *m, GFile *file, GFile *other, GFileMonitorEvent t, const char* _path)
{
    char* p = g_file_get_path(file);
    if (g_strcmp0(p, _path) == 0)
        return;


    switch (t) {
        case G_FILE_MONITOR_EVENT_MOVED:
            {
                // TODO:desktop's monitor can't receive this moved event, because event is consumptioned.
                char* new_path = g_file_get_path(other);
                if (g_strcmp0(new_path, get_desktop_dir(FALSE)) == 0) {
                    JSObjectRef json = json_create();
                    json_append_nobject(json, "entry", other, g_object_ref, g_object_unref);
                    js_post_message("item_update", json);
                }
                g_free(new_path);
                break;
            }
        case G_FILE_MONITOR_EVENT_DELETED:
        case G_FILE_MONITOR_EVENT_CREATED:
        case G_FILE_MONITOR_EVENT_ATTRIBUTE_CHANGED:
            {
                // update the directory' content on desktop.
                JSObjectRef json = json_create();
                GFile* dir = g_file_get_parent(file);
                json_append_nobject(json, "entry", dir, g_object_ref, g_object_unref);
                g_object_unref(dir);
                js_post_message("item_update", json);
                break;
            }
    }
}



void begin_monitor_dir(const char* path, GCallback cb)
{
    if (!g_hash_table_contains(monitor_table, path)) {
        GFile* dir = g_file_new_for_path(path);
        GFileMonitor* monitor = g_file_monitor_directory(dir, G_FILE_MONITOR_SEND_MOVED, NULL, NULL);
        g_file_monitor_set_rate_limit(monitor, 0);
        char* key = g_strdup(path);
        g_hash_table_insert(monitor_table, key, monitor);
        g_signal_connect(monitor, "changed", cb, key);
        g_object_unref(dir);
    } else {
        g_warning("The %s has aleardy monitored! You many forget call the function of end_monitor_dir", path);
    }
}

void end_monitor_dir(const char* path)
{
    g_hash_table_remove(monitor_table, path);
}


JS_EXPORT_API
void desktop_cancel_monitor_dir(const char* path)
{
    end_monitor_dir(path);
}

void begin_monitor_desktop()
{
    GFileMonitor* monitor = g_file_monitor_directory(_desktop,
            G_FILE_MONITOR_SEND_MOVED, NULL, NULL);
    g_file_monitor_set_rate_limit(monitor, 0);

    g_hash_table_insert(monitor_table, g_file_get_path(_desktop), monitor);
    g_signal_connect(monitor, "changed", G_CALLBACK(monitor_desktop_dir_cb), NULL);
}


//JS_EXPORT
void install_monitor()
{
    if (monitor_table == NULL) {
        monitor_table = g_hash_table_new_full(g_str_hash, g_str_equal, g_free, (GDestroyNotify)g_object_unref);

        char* desktop_path = get_desktop_dir(TRUE);
        _desktop = g_file_new_for_path(desktop_path);
        g_free(desktop_path);

        begin_monitor_desktop();

        char* desktop = g_file_get_path(_desktop);
        GDir *dir =  g_dir_open(desktop, 0, NULL);
        if (dir != NULL) {
            const char* filename = NULL;
            char path[500];
            while ((filename = g_dir_read_name(dir)) != NULL) {
                g_sprintf(path, "%s/%s", desktop, filename);
                if (g_file_test(path, G_FILE_TEST_IS_DIR)) {
                    begin_monitor_dir(path, G_CALLBACK(monitor_dir_cb));
                }
            }
            g_dir_close(dir);
        }
        g_free(desktop);
    }
}
