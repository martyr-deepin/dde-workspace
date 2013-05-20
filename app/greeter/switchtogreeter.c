/**
 * Copyright (c) 2011 ~ 2012 Deepin, Inc.
 *               2011 ~ 2012 Long Wei
 *
 * Author:      Long Wei <yilang2007lw@gmail.com>
 * Maintainer:  Long Wei <yilang2007lw@gamil.com>
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
#include <unistd.h>
#include <pwd.h>
#include <sys/types.h>

GError *error = NULL;

int main(int argc, char **argv)
{
    GDBusProxy *display_proxy = NULL;

    display_proxy = g_dbus_proxy_new_for_bus_sync(G_BUS_TYPE_SYSTEM,
            G_DBUS_PROXY_FLAGS_NONE,
            NULL,
            "org.freedesktop.DisplayManager",
            "/org/freedesktop/DisplayManager",
            "org.freedesktop.DisplayManager",
            NULL, 
            &error);

    if(error != NULL){
        g_debug("connect org.freedesktop.DisplayManager failed");
        g_clear_error(&error);
    }

    GVariant *sessions_prop_var = NULL;
    sessions_prop_var = g_dbus_proxy_get_cached_property(display_proxy, "Sessions");

    const gchar **sessions = NULL;
    gsize length = 0;
    sessions = g_variant_get_objv(sessions_prop_var, &length);

    g_object_unref(display_proxy);

    struct passwd *pw = NULL;
    gchar *username = NULL;

    pw = getpwuid(getuid());
    if(pw == NULL){
        g_debug("getpwuid failed");
    }

    username = pw->pw_name;

    for(int i = 0; i < length; ++ i){
        GDBusProxy *session_proxy = NULL;

        session_proxy = g_dbus_proxy_new_for_bus_sync(G_BUS_TYPE_SYSTEM,
                        G_DBUS_PROXY_FLAGS_NONE,
                        NULL,
                        "org.freedesktop.DisplayManager",
                        sessions[i],
                        "org.freedesktop.DisplayManager.Session",
                        NULL,
                        &error);

        if(error != NULL){
            g_debug("connect session proxy failed");
            g_clear_error(&error);
        }

        GVariant *username_prop_var = NULL;
        username_prop_var = g_dbus_proxy_get_cached_property(session_proxy, "UserName");

        if(error != NULL){
            g_debug("session proxy get username failed");
            g_clear_error(&error);
        }

        gchar *user_name = g_variant_dup_string(username_prop_var, NULL);

        if(g_strcmp0(username, user_name) == 0){
            GVariant *seat_prop_var = NULL;
            seat_prop_var = g_dbus_proxy_get_cached_property(session_proxy, "Seat");
            gsize seat_length;
            gchar *seat_path = g_variant_dup_string(seat_prop_var, &seat_length);

            GDBusProxy *seat_proxy = NULL;

            seat_proxy = g_dbus_proxy_new_for_bus_sync(G_BUS_TYPE_SYSTEM,
                        G_DBUS_PROXY_FLAGS_NONE,
                        NULL,
                        "org.freedesktop.DisplayManager",
                        seat_path,
                        "org.freedesktop.DisplayManager.Seat",
                        NULL,
                        &error);

            if(error != NULL){
                g_debug("connect seat proxy failed");
                g_clear_error(&error);
            }

            g_dbus_proxy_call_sync(seat_proxy,
                        "SwitchToGreeter",
                        g_variant_new("()"),
                        G_DBUS_CALL_FLAGS_NONE,
                        -1,
                        NULL,
                        &error);

            if(error != NULL){
                g_debug("switch to greeter failed");
                g_clear_error(&error);
            }

            g_free(seat_path);
            g_variant_unref(seat_prop_var);
            g_object_unref(seat_proxy);

            g_free(user_name);
            g_variant_unref(username_prop_var);
            g_object_unref(session_proxy);
            break;

        }else{
            g_free(user_name);
            g_variant_unref(username_prop_var);
            g_object_unref(session_proxy);
            continue;
        }
    }

    g_variant_unref(sessions_prop_var);
    g_free(username);
    g_free(sessions);

    return 0;
}
