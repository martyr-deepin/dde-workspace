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
#include <gtk/gtk.h>
#include "dock_config.h"
#define SCHEMA_ID "com.deepin.dde.dock"

struct _GlobalData GD;
void update_dock_show();
void update_dock_color();
void update_dock_apps();

void setting_changed(GSettings* s, gchar* key, gpointer user_data)
{
    if (g_strcmp0(key, "show") == 0) {
        GD.config.show = g_settings_get_boolean(s, key);
        update_dock_show();
    } else if (g_strcmp0(key, "color") == 0) {
        GD.config.color = g_settings_get_uint(s, key);
        update_dock_color();
    } else if (g_strcmp0(key, "apps") == 0) {
        g_strfreev(GD.config.apps);
        GD.config.apps = g_settings_get_strv(s, key);
        update_dock_apps();
    }
}

void init_config()
{
    GD.config.show = TRUE;
    GD.config.color = 0;
    GD.config.apps = NULL;
    GD.is_webview_loaded = FALSE;

    GSettings* s = g_settings_new(SCHEMA_ID);
    g_signal_connect(s, "changed", G_CALLBACK(setting_changed), NULL);
    g_signal_emit_by_name(s, "changed", "show", NULL);
    g_signal_emit_by_name(s, "changed", "color", NULL);
    g_signal_emit_by_name(s, "changed", "apps", NULL);
}
