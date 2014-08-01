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

#define SCHEMA_ID "com.deepin.dde.dock"
#define HIDE_MODE_KEY "hide-mode"
#define DISPLAY_MODE_KEY "display-mode"


struct _GlobalData GD;
void update_dock_size_mode();
void dock_update_hide_mode();
void _change_workarea_height(int height);

void setting_changed(GSettings* s, gchar* key, gpointer user_data G_GNUC_UNUSED)
{
    if (g_strcmp0(key, HIDE_MODE_KEY) == 0) {
        GD.config.hide_mode = g_settings_get_enum(s, key);
        if (GD.config.hide_mode == NO_HIDE_MODE ) {
            _change_workarea_height(GD.dock_height);
        } else {
            _change_workarea_height(0);
        }
        g_debug("setting_changed");
    } else if (g_strcmp0(key, DISPLAY_MODE_KEY) == 0) {
        GD.config.display_mode = g_settings_get_enum(s, key);
        if (GD.config.display_mode == CLASSIC_MODE) {
            GD.dock_height = 48;
            GD.dock_panel_height = 48;
        } else {
            GD.dock_height = 68;
            GD.dock_panel_height = 60;
        }

        _change_workarea_height(GD.dock_height);
    }
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
        GD.dock_height = 48;
        GD.dock_panel_height = 48;
    } else {
        GD.dock_height = 68;
        GD.dock_panel_height = 60;
    }
    g_signal_connect(s, "changed", G_CALLBACK(setting_changed), NULL);
}

void dock_set_height(double _height)
{
    // TODO: lock
    GD.dock_height = (int)_height;
}

void dock_set_panel_height(double _height)
{
    // TODO: lock
    GD.dock_panel_height = (int)_height;
}

