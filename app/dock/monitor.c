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

#include <gio/gio.h>

#include "jsextension.h"
#include "utils.h"

static GFile* trash_can = NULL;
static GFileMonitor* m = NULL;


void destroy_monitor()
{
    g_object_unref(trash_can);
    g_object_unref(m);
}


void trash_changed(GFileMonitor* monitor G_GNUC_UNUSED,
                   GFile* file G_GNUC_UNUSED,
                   GFile* other_file G_GNUC_UNUSED,
                   GFileMonitorEvent event_type G_GNUC_UNUSED,
                   gpointer data G_GNUC_UNUSED)
{
    GFileInfo* info = g_file_query_info(trash_can, G_FILE_ATTRIBUTE_TRASH_ITEM_COUNT, G_FILE_QUERY_INFO_NONE, NULL, NULL);
    int count = g_file_info_get_attribute_uint32(info, G_FILE_ATTRIBUTE_TRASH_ITEM_COUNT);
    g_object_unref(info);
    JSObjectRef value = json_create();
    json_append_number(value, "value", count);
    js_post_message("trash_count_changed", value);
}


GFileMonitor* monitor_trash()
{
    atexit(destroy_monitor);
    trash_can = g_file_new_for_uri("trash:///");
    m = g_file_monitor_directory(trash_can, G_FILE_MONITOR_SEND_MOVED, NULL, NULL);
    g_signal_connect(m, "changed", G_CALLBACK(trash_changed), NULL);
    return m;
}

