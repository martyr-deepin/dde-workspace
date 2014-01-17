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


#include <glib.h>
#include <gio/gio.h>

#include "jsextension.h"


#define SCHEMA_ID "com.deepin.dde.launcher"
#define SORT_METHOD "sort-method"
#define PIN "pin"


static
GSettings* settings = NULL;


static
void sort_method_changed(GSettings* settings,
                         gchar* key,
                         gpointer user_data G_GNUC_UNUSED)
{
    char* method = g_settings_get_string(settings, key);
    JSObjectRef method_name = json_create();
    json_append_string(method_name, "method_name", method);
    g_free(method);
    js_post_message("sort_method_changed", method_name);
}


static
void pin_status_changed(GSettings* settings,
                        gchar* key,
                        gpointer user_data G_GNUC_UNUSED)
{
    gboolean is_pin = g_settings_get_boolean(settings, key);
    JSObjectRef pin_status = json_create();
    json_append_number(pin_status, "status", is_pin);
    js_post_message("pin_status_changed", pin_status);
}


GSettings* get_launcher_setting()
{
    if (settings == NULL) {
        settings = g_settings_new(SCHEMA_ID);
        g_signal_connect(G_OBJECT(settings), "changed::"SORT_METHOD, G_CALLBACK(sort_method_changed), NULL);
        g_signal_connect(G_OBJECT(settings), "changed::"PIN, G_CALLBACK(pin_status_changed), NULL);
    }

    return settings;
}


void destroy_setting()
{
    g_object_unref(settings);
}


DBUS_EXPORT_API
gboolean launcher_pin(gboolean pin)
{
    return g_settings_set_boolean(get_launcher_setting(), PIN, pin);
}


DBUS_EXPORT_API
gboolean launcher_is_pinned()
{
    return g_settings_get_boolean(get_launcher_setting(), PIN);
}


DBUS_EXPORT_API
gboolean launcher_set_sort_method(const char* method)
{
    return g_settings_set_string(get_launcher_setting(), SORT_METHOD, method);
}


DBUS_EXPORT_API
char* launcher_get_sort_method()
{
    return g_settings_get_string(get_launcher_setting(), SORT_METHOD);
}

