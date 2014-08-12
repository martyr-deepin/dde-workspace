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


struct _GlobalData GD;
void update_dock_size_mode();
void dock_update_hide_mode();

void setting_changed(GSettings* s, gchar* key, gpointer user_data G_GNUC_UNUSED)
{
    if (g_strcmp0(key, "hide-mode") == 0) {
        GD.config.hide_mode = g_settings_get_enum(s, key);
        void _change_workarea_height(int height);
        if (GD.config.hide_mode == NO_HIDE_MODE ) {
            extern int _dock_height;
            _change_workarea_height(_dock_height);
        } else {
            _change_workarea_height(0);
        }
        g_debug("setting_changed");
        // dock_update_hide_mode();
    }
}

void init_config()
{
    GD.config.color = 0;
    GD.is_webview_loaded = FALSE;

    GSettings* s = g_settings_new(SCHEMA_ID);
    g_signal_connect(s, "changed", G_CALLBACK(setting_changed), NULL);
    g_signal_emit_by_name(s, "changed", "hide-mode", NULL);
}

