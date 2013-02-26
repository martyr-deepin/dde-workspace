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
#include "dentry/entry.h"
#include "utils.h"
#include <gio/gio.h>
#include <sys/inotify.h>
#include <fcntl.h>

static gboolean _inotify_poll();
static void _remove_monitor_directory(GFile*);
static void _add_monitor_directory(GFile*);
void handle_delete(GFile* f);

static GHashTable* _monitor_table = NULL;
static GFile* _desktop_file = NULL;
static GFile* _trash_can = NULL;
static int _inotify_fd = -1;


void trash_changed()
{
    GFileInfo* info = g_file_query_info(_trash_can, G_FILE_ATTRIBUTE_TRASH_ITEM_COUNT, G_FILE_QUERY_INFO_NONE, NULL, NULL);
    int count = g_file_info_get_attribute_uint32(info, G_FILE_ATTRIBUTE_TRASH_ITEM_COUNT);
    g_object_unref(info);
    js_post_message_simply("trash_count_changed", "{\"value\":\"%d\"}", count);
}

static
void _add_monitor_directory(GFile* f)
{
    g_assert(_inotify_fd != -1);
    char* path = g_file_get_path(f);
    int watch = inotify_add_watch(_inotify_fd, path, IN_CREATE | IN_DELETE | IN_MODIFY | IN_MOVED_FROM | IN_MOVED_TO | IN_ATTRIB);
    g_free(path);
    g_hash_table_insert(_monitor_table, GINT_TO_POINTER(watch), g_object_ref(f));
}

void install_monitor()
{
    if (_inotify_fd == -1) {
        _inotify_fd = inotify_init();
        int flags = fcntl(_inotify_fd, F_GETFL, 0);
        fcntl(_inotify_fd, F_SETFL, flags | O_NONBLOCK);
        _monitor_table = g_hash_table_new_full(g_direct_hash, g_direct_equal, NULL, (GDestroyNotify)g_object_unref);
        g_timeout_add(50, (GSourceFunc)_inotify_poll, NULL);

        char* desktop_path = get_desktop_dir(TRUE);
        _desktop_file = g_file_new_for_commandline_arg(desktop_path);
        _trash_can = g_file_new_for_uri("trash:///");
        GFileMonitor* m = g_file_monitor(_trash_can, G_FILE_MONITOR_NONE, NULL, NULL);
        g_signal_connect(m, "changed", G_CALLBACK(trash_changed), NULL);

        _add_monitor_directory(_desktop_file);

        GDir *dir =  g_dir_open(desktop_path, 0, NULL);
        g_free(desktop_path);

        if (dir != NULL) {
            const char* filename = NULL;
            while ((filename = g_dir_read_name(dir)) != NULL) {
                GFile* f = g_file_get_child(_desktop_file, filename);
                if (g_file_query_file_type(f, G_FILE_QUERY_INFO_NONE, NULL) == G_FILE_TYPE_DIRECTORY) {
                    _add_monitor_directory(f);
                }
                g_object_unref(f);
            }
            g_dir_close(dir);
        }
    }
}

void handle_rename(GFile* old_f, GFile* new_f)
{
    handle_delete(new_f);

    _add_monitor_directory(new_f);
    _remove_monitor_directory(old_f);

    char* path = g_file_get_path(new_f);
    Entry* entry = dentry_create_by_path(path);
    g_free(path);

    JSObjectRef json = json_create();
    json_append_nobject(json, "old", old_f, g_object_ref, g_object_unref);
    json_append_nobject(json, "new", entry, g_object_ref, g_object_unref);
    js_post_message("item_rename", json);

    g_object_unref(entry);
}

void handle_delete(GFile* f)
{
    _remove_monitor_directory(f);
    JSObjectRef json = json_create();
    json_append_nobject(json, "entry", f, g_object_ref, g_object_unref);
    js_post_message("item_delete", json);
}

void handle_update(GFile* f)
{
    char* path = g_file_get_path(f);
    Entry* entry = dentry_create_by_path(path);
    g_free(path);

    JSObjectRef json = json_create();
    json_append_nobject(json, "entry", entry, g_object_ref, g_object_unref);
    js_post_message("item_update", json);

    g_object_unref(entry);
}

void handle_new(GFile* f)
{
    _add_monitor_directory(f);
    handle_update(f);
}


static
void _remove_monitor_directory(GFile* f)
{
    int wd = -1;
    GList* _keys = g_hash_table_get_keys(_monitor_table);
    GList* keys = _keys;
    while (keys != NULL) {
        GFile* test = g_hash_table_lookup(_monitor_table, keys->data);
        if (test != NULL && g_file_equal(f, test)) {
            wd = GPOINTER_TO_INT(keys->data);
            break;
        }
        keys = g_list_next(keys);
    }
    g_list_free(_keys);
    if (wd != -1) {
        inotify_rm_watch(_inotify_fd, wd);
        g_hash_table_remove(_monitor_table, GINT_TO_POINTER(wd));
    }
}

static
gboolean _inotify_poll()
{
#define EVENT_SIZE  ( sizeof (struct inotify_event) )
#define EVENT_BUF_LEN     ( 1024 * ( EVENT_SIZE + 16 ) )

    if (_inotify_fd != -1) {
        char buffer[EVENT_BUF_LEN];
        int length = read(_inotify_fd, buffer, EVENT_BUF_LEN); 

        GList* move_out_files = NULL;
        struct inotify_event *move_out_event = NULL;
        GFile* old = NULL;

        for (int i=0; i<length; ) {
            struct inotify_event *event = (struct inotify_event *) &buffer[i];
            i += EVENT_SIZE+event->len;
            if (event->name[0] == '.' && !g_str_has_prefix(event->name, DEEPIN_RICH_DIR)) continue;
            if (event->len) {
                GFile* p = g_hash_table_lookup(_monitor_table, GINT_TO_POINTER(event->wd));

                if (g_file_equal(p, _desktop_file)) {
                    /* BEGIN MVOE EVENT HANDLE */
                    if ((event->mask & IN_MOVED_FROM) && (move_out_event == NULL)) {
                        move_out_event = event;
                        old = g_file_get_child(p, event->name);
                        continue;
                    } else if ((event->mask & IN_MOVED_FROM) && (move_out_event != NULL)) {
                        GFile* f = g_file_get_child(_desktop_file, event->name);
                        handle_delete(f);
                        g_object_unref(f);
                        continue;
                    } else if ((event->mask & IN_MOVED_TO) && (move_out_event != NULL)) {
                        move_out_event = NULL;
                        GFile* f = g_file_get_child(p, event->name);

                        handle_rename(old, f);
                        g_object_unref(f);
                        g_object_unref(old);
                        old = NULL;
                        continue;
                    /* END MVOE EVENT HANDLE */
                    } else if (event->mask & IN_DELETE) {
                        GFile* f = g_file_get_child(p, event->name);
                        handle_delete(f);
                        g_object_unref(f);
                    } else if (event->mask & IN_CREATE) {
                        GFile* f = g_file_get_child(p, event->name);
                        handle_new(f);
                        g_object_unref(f);
                    } else {
                        GFile* f = g_file_get_child(p, event->name);
                        handle_update(f);
                        g_object_unref(f);
                    }

                } else {
                    if (event->mask & IN_MOVED_TO) {
                        GFile* f = g_file_get_child(_desktop_file, event->name);
                        handle_delete(f);
                        g_object_unref(f);
                    }
                    handle_update(p);
                }
            }
        }
        if (move_out_event != NULL) {
            handle_delete(old);
            move_out_event == NULL;
        }
        return TRUE;
    } else {
        return FALSE;
    }
}
