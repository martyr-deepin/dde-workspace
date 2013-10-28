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

#ifndef FILE_MONITOR_H
#define FILE_MONITOR_H

void add_monitors();
void destroy_monitors();

enum DesktopStatus {
    UNKNOWN,
    DELETED,
    ADDED,
    CHANGED
};


struct DesktopInfo {
    char* path;
    enum DesktopStatus status;
};

#ifdef __DUI_DEBUG
void append_monitor(GPtrArray* monitors, const GPtrArray* paths, GCallback monitor_callback);
GPtrArray* _get_all_applications_dirs();
struct DesktopInfo* desktop_info_create(const char* path, enum DesktopStatus status);
void desktop_info_destroy(struct DesktopInfo** di);
gboolean _update_items(gpointer user_data);
void desktop_monitor_callback(GFileMonitor* monitor, GFile* file, GFile* other_file,
                              GFileMonitorEvent event_type, gpointer data);
void _monitor_desktop_files();
gboolean _update_autostart(gpointer user_data);
void autostart_monitor_callback(GFileMonitor* monitor, GFile* file, GFile* other_file,
                                GFileMonitorEvent event_type, gpointer data);
void _monitor_autostart_files();
#endif

#endif /* end of include guard: FILE_MONITOR_H */

