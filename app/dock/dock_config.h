/**
 * Copyright (c) 2011 ~ 2012 Deepin, Inc.
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
#include <gtk/gtk.h>
#ifndef _DOCK_CONFIG_H__
#define _DOCK_CONFIG_H__

#define APP_NAME "dock"

enum {NO_HIDE_MODE=0, INTELLIGENT_HIDE_MODE=3, ALWAYS_HIDE_MODE=1, AUTO_HIDE_MODE=2} HideMode;
enum {UNKNOWN_MODE=-1, FASHION_MODE, EFFICIENT_MODE, CLASSIC_MODE};
struct _DockConfig {
    int display_mode;
    int hide_mode;
    guint32 color;
    int position; //hasn't use
};

struct _GlobalData {
    struct _DockConfig config;
    int dock_height;
    int dock_panel_height;
    int dock_panel_width;
    gboolean is_webview_loaded;
    GtkWidget* container;
    GtkWidget* webview;
};

extern struct _GlobalData GD;

void init_config();

#define NOT_FOUND_IMG_PATH "img/not_found.png"
#define DEFAULT_COLOR_R 0.71875
#define DEFAULT_COLOR_G 0.8046875
#define DEFAULT_COLOR_B 0.87109375

#endif

