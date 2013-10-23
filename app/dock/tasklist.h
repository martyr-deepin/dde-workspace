/**
 * Copyright (c) 2011 ~ 2013 Deepin, Inc.
 *               2011 ~ 2012 snyh
 *               2013 ~ 2013 Liqiang Lee
 *
 * Author:      snyh <snyh@snyh.org>
 * Maintainer:  snyh <snyh@snyh.org>
 *              Liqiang Lee <liliqiang@linuxdeepin.com>
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
#ifndef __TASKLIST_ACTIVE_WINDOW_H
#define __TASKLIST_ACTIVE_WINDOW_H

#define FILTER_FILE "dock/filter.ini"

void init_task_list();
gboolean is_has_client(const char* app_id);
void update_task_list();
void close_launcher_window();
gboolean dock_has_overlay_client();
gboolean dock_has_maximize_client();
double dock_get_active_window();

#endif
