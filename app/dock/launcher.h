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
#ifndef _LAUNCHER_H__
#define _LAUNCHER_H__

#define APPS_INI "dock/apps.ini"
#define DOCKED_ITEM_GROUP_NAME "__Config__"
#define DOCKED_ITEM_KEY_NAME "Position"

#define DOCKED_ITEM_APP_TYPE "App"
#define DOCKED_ITEM_PLUGIN_TYPE "Plugin"
#define DOCKED_ITEM_RICHDIR_TYPE "RichDir"

extern GKeyFile* k_apps;
void init_launchers();
gboolean dock_has_launcher(const char* app_id);
gboolean request_by_info(const char* name, const char* cmdline, const char* icon);
void update_dock_apps();

#endif
