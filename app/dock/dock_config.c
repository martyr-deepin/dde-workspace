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
#include <gtk/gtk.h>
#include "dock_config.h"
#include "display_info.h"
#include "jsextension.h"

#define SCHEMA_ID "com.deepin.dde.dock"
#define HIDE_MODE_KEY "hide-mode"
#define DISPLAY_MODE_KEY "display-mode"


extern struct DisplayInfo dock;
struct _GlobalData GD;
void dock_update_hide_mode();
void _change_workarea_height(int height);
gboolean workaround_change_workarea_height(int height);
void dock_force_set_region(double x, double y, double items_width, double panel_width, double height);

#define MODERN_DOCK_HEIGHT 68
#define MODERN_DOCK_PANEL_HEIGHT 60

#define CLASSIC_DOCK_HEIGHT 48
#define CLASSIC_DOCK_PANEL_HEIGHT 48

void setting_changed(GSettings* s, gchar* key, gpointer user_data G_GNUC_UNUSED)
{
    GD.config.display_mode = g_settings_get_enum(s, key);
    if (GD.config.display_mode == CLASSIC_MODE) {
        GD.dock_height = CLASSIC_DOCK_HEIGHT;
        GD.dock_panel_height = CLASSIC_DOCK_PANEL_HEIGHT;
    } else {
        GD.dock_height = MODERN_DOCK_HEIGHT;
        GD.dock_panel_height = MODERN_DOCK_PANEL_HEIGHT;
    }

    // _base_rect and workarea should be updated,
    // workaround_change_workarea_height will do it.
    if (GD.config.hide_mode == NO_HIDE_MODE ) {
        workaround_change_workarea_height(GD.dock_height);
    } else {
        workaround_change_workarea_height(0);
    }

    // update dock region, otherwise, the effective input region is a
    // rectangle with screen width.
    js_post_signal("display-mode-changed");
}

void init_config()
{
    GD.config.color = 0;
    GD.is_webview_loaded = FALSE;
    GD.dock_panel_width = 0;

    GSettings* s = g_settings_new(SCHEMA_ID);
    GD.config.hide_mode = g_settings_get_enum(s, HIDE_MODE_KEY);
    GD.config.display_mode = g_settings_get_enum(s, DISPLAY_MODE_KEY);
    if (GD.config.display_mode == CLASSIC_MODE) {
        GD.dock_height = CLASSIC_DOCK_HEIGHT;
        GD.dock_panel_height = CLASSIC_DOCK_PANEL_HEIGHT;
    } else {
        GD.dock_height = MODERN_DOCK_HEIGHT;
        GD.dock_panel_height = MODERN_DOCK_PANEL_HEIGHT;
    }
    g_signal_connect(s, "changed::"DISPLAY_MODE_KEY, G_CALLBACK(setting_changed), NULL);
}

