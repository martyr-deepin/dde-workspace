/**
 * Copyright (c) 2011 ~ 2014 Deepin, Inc.
 *               2011 ~ 2014 snyh
 *
 * Author:      snyh <snyh@snyh.org>
 *              bluth <yuanchenglu001@gmail.com>
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
#include "inotify_item.h"
#include "utils.h"
#include <gio/gio.h>
#include <sys/inotify.h>
#include <fcntl.h>
#include <glib-object.h>

extern void desktop_item_update();
PRIVATE gboolean _inotify_poll();
PRIVATE void _remove_monitor_directory(GFile*);
PRIVATE void _add_monitor_directory(GFile*);
void handle_delete(GFile* f);
PRIVATE GFile* get_gfile_from_ievent(GFile* parent, const struct inotify_event* event);

static GHashTable* _monitor_table = NULL;
static GFile* _desktop_file = NULL;
static GFile* _trash_can = NULL;
static int _inotify_fd = -1;

void trash_changed()
{
    GFileInfo* info = g_file_query_info(_trash_can, G_FILE_ATTRIBUTE_TRASH_ITEM_COUNT, G_FILE_QUERY_INFO_NONE, NULL, NULL);
    int count = g_file_info_get_attribute_uint32(info, G_FILE_ATTRIBUTE_TRASH_ITEM_COUNT);
    g_object_unref(info);
    JSObjectRef value = json_create();
    json_append_number(value, "value", count);
    js_post_message("trash_count_changed", value);
}

PRIVATE
void _add_monitor_directory(GFile* f)
{
    g_assert(_inotify_fd != -1);

    GFileInfo* info = g_file_query_info(f, "standard::type", G_FILE_QUERY_INFO_NOFOLLOW_SYMLINKS, NULL, NULL);
    if (info == NULL) return; //temp file may cause this like downloading file or compressing file
    GFileType type = g_file_info_get_attribute_uint32(info, G_FILE_ATTRIBUTE_STANDARD_TYPE);
    g_assert(info != NULL);
    if (g_file_info_get_is_symlink(info)) {
        GFile* maybe_real_target = g_file_new_for_uri(g_file_info_get_symlink_target(info));
        _add_monitor_directory(maybe_real_target);
        g_object_unref(maybe_real_target);
    } else if (type == G_FILE_TYPE_DIRECTORY) {
        char* path = g_file_get_path(f);
        int watch = inotify_add_watch(_inotify_fd, path, IN_CREATE | IN_DELETE | IN_MODIFY | IN_MOVED_FROM | IN_MOVED_TO | IN_ATTRIB);
        g_free(path);
        g_hash_table_insert(_monitor_table, GINT_TO_POINTER(watch), g_object_ref(f));
    }
    g_object_unref(info);
}

void install_monitor()
{
    if (_inotify_fd != -1) {
        return;
    }

    _inotify_fd = inotify_init1(IN_NONBLOCK|IN_CLOEXEC);
    _monitor_table = g_hash_table_new_full(g_direct_hash, g_direct_equal, NULL, (GDestroyNotify)g_object_unref);
    g_timeout_add(50, (GSourceFunc)_inotify_poll, NULL);

    _desktop_file = g_file_new_for_commandline_arg(DESKTOP_DIR());
    _trash_can = g_file_new_for_uri("trash:///");
    GFileMonitor* m = g_file_monitor(_trash_can, G_FILE_MONITOR_NONE, NULL, NULL);
    g_signal_connect(m, "changed", G_CALLBACK(trash_changed), NULL);

    _add_monitor_directory(_desktop_file);

    GDir *dir =  g_dir_open(DESKTOP_DIR(), 0, NULL);
    if (dir == NULL) {
        g_warning("can't open desktop directory: %s\n", DESKTOP_DIR());
        return;
    }

    const char* filename = NULL;
    while ((filename = g_dir_read_name(dir)) != NULL) {
        GFile* f = g_file_get_child(_desktop_file, filename);
        _add_monitor_directory(f);
        g_object_unref(f);
    }
    g_dir_close(dir);
}

PRIVATE
gboolean has_same_parent(GFile* a, GFile* b)
{
    GFile* parent = g_file_get_parent(a);
    if (parent == NULL) {
        parent = g_file_get_parent(b);
        if (parent != NULL) {
            g_object_unref(parent);
            return FALSE;
        } else {
            return TRUE;
        }
    }

    gboolean same = FALSE;
    if (g_file_has_parent(b, parent)) {
        same = TRUE;
    }
    g_object_unref(parent);
    return same;
}

void handle_rename(GFile* old_f, GFile* new_f)
{
    g_debug("handle_rename:%s-->%s\n", g_file_get_path(old_f), g_file_get_path(new_f));
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
    g_debug("handle_delete:%s\n", g_file_get_path(f));
    _remove_monitor_directory(f);
    JSObjectRef json = json_create();
    json_append_nobject(json, "entry", f, g_object_ref, g_object_unref);
    js_post_message("item_delete", json);
}

void handle_update(GFile* f)
{
    g_debug("handle_update:%s\n", g_file_get_path(f));
    if (g_file_query_file_type(f, G_FILE_QUERY_INFO_NONE ,NULL) != G_FILE_TYPE_UNKNOWN) {
        char* path = g_file_get_path(f);
        Entry* entry = dentry_create_by_path(path);
        g_free(path);

        JSObjectRef json = json_create();
        json_append_nobject(json, "entry", entry, g_object_ref, g_object_unref);
        js_post_message("item_update", json);
        desktop_item_update();

        g_object_unref(entry);
    }
}

void handle_new(GFile* f)
{
    g_debug("handle_new:%s\n", g_file_get_path(f));
    _add_monitor_directory(f);
    handle_update(f);
}

// test : use real fileops to test it

PRIVATE
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


// test important
PRIVATE
gboolean _inotify_poll()
{
    if (_inotify_fd == -1) {
        return FALSE;
    }

#define EVENT_SIZE  ( sizeof (struct inotify_event) )
#define EVENT_BUF_LEN     ( 1024 * ( EVENT_SIZE + 16 ) )
    char buffer[EVENT_BUF_LEN];
    int length = read(_inotify_fd, buffer, EVENT_BUF_LEN);

    struct inotify_event *move_out_event = NULL;

    for (int i=0; i<length; ) {
        struct inotify_event *event = (struct inotify_event *) &buffer[i];
        i += EVENT_SIZE+event->len;
        if(desktop_file_filter(event->name))
            continue;
        if (event->len == 0) {
            continue;
        }

        GFile* p = g_hash_table_lookup(_monitor_table, GINT_TO_POINTER(event->wd));
        if (!g_file_equal(p, _desktop_file)) {
            handle_update(p);
            continue;
        }

        /* BEGIN MOVE EVENT HANDLE */
        if ((event->mask & IN_MOVED_FROM) && (move_out_event == NULL)) {
            move_out_event = event;
            continue;
        } else if ((event->mask & IN_MOVED_FROM) && (move_out_event != NULL)) {
            GFile* f = get_gfile_from_ievent(NULL, event);
            handle_delete(f);
            g_object_unref(f);
            continue;
        } else if ((event->mask & IN_MOVED_TO) && (move_out_event != NULL)) {
            GFile* f = get_gfile_from_ievent(NULL, event);
            GFile* old = get_gfile_from_ievent(NULL, move_out_event);

            move_out_event = NULL;
            if (has_same_parent(old, f)) {
                handle_rename(old, f);
            } else {
                handle_new(f);
            }
            g_object_unref(f);
            g_object_unref(old);
            continue;
            /* END MVOE EVENT HANDLE */
        } else if (event->mask & IN_DELETE) {
            GFile* f = get_gfile_from_ievent(NULL, event);
            handle_delete(f);
            g_object_unref(f);
        } else if (event->mask & IN_CREATE) {
            GFile* f = get_gfile_from_ievent(NULL, event);
            handle_new(f);
            g_object_unref(f);
        } else {
            GFile* f = get_gfile_from_ievent(NULL, event);
            _add_monitor_directory(f);
            handle_update(f);
            g_object_unref(f);
        }
    }
    if (move_out_event != NULL) {
        GFile* old = get_gfile_from_ievent(NULL, move_out_event);
        handle_delete(old);
        g_object_unref(old);
        move_out_event = NULL;
    }
    return TRUE;
}

static
GFile* get_gfile_from_ievent(GFile* parent, const struct inotify_event* event)
{
    g_assert(event != NULL);
    if (parent == NULL) {
        parent = g_hash_table_lookup(_monitor_table, GINT_TO_POINTER(event->wd));
    }
    if (parent == NULL) {
        g_assert_not_reached();
        return NULL;
    }
    g_assert(G_IS_FILE(parent));
    return  g_file_get_child(parent, event->name);
}

gboolean desktop_file_filter(const char *file_name)
{
    g_assert(file_name != NULL);
    if((file_name[0] == '.' && !g_str_has_prefix(file_name, DEEPIN_RICH_DIR)) || g_str_has_suffix(file_name, "~"))
        return TRUE;
    else
        return FALSE;
}

