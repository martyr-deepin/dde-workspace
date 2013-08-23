/**
 * Copyright (c) 2011 ~ 2012 Deepin, Inc.
 *               2011 ~ 2012 Liqiang Lee
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
#include <glib/gstdio.h>
#include <gio/gio.h>
#include "jsextension.h"
#include <dbus/dbus.h>
#include <dbus/dbus-glib.h>


void start_animation_handler()
{
    g_warning("[start_animation_handler] start animation");
    js_post_message_simply("start-animation", NULL);
}


void stop_animation_handler()
{
    g_warning("[stop_animation_handler] stop animation");
    js_post_message_simply("stop-animation", NULL);
}


void start_login_handler()
{
    g_warning("[start_login_handler] start login");
    js_post_message_simply("start-login", NULL);
}


gboolean connect_signal(gpointer dump) // {{{
{
    static gboolean started_animation = FALSE;
    static gboolean stopped_animation = FALSE;
    static gboolean started_login = FALSE;

    if (g_file_test("/tmp/start-animation", G_FILE_TEST_EXISTS)) {
        g_warning("main loop start animation");
        start_animation_handler();
        g_unlink("/tmp/start-animation");
    /* } else if (!stopped_animation && g_file_test("/tmp/stop-animation", G_FILE_TEST_EXISTS)) { */
    /*     g_warning("main loop stop animation"); */
    /*     g_unlink("/tmp/stop-animation"); */
    /*     stop_animation_handler(); */
    /*     stopped_animation = TRUE; */
    /* } else if (!started_login && g_file_test("/tmp/start-login", G_FILE_TEST_EXISTS)) { */
    /*     g_warning("main loop start login"); */
    /*     g_unlink("/tmp/start-login"); */
    /*     start_login_handler(); */
    /*     started_login = TRUE; */
    }
} // }}}


void connect_dbus_signal()  // {{{
{
    const char* rules = "eavesdrop=true,"
        "type=signal,"
        "interface=com.deepin.dde.lock,"
        "member=StartAnimation";


    DBusConnection* conn = dbus_bus_get(DBUS_BUS_SYSTEM, NULL);

    dbus_bus_add_match(conn, rules, NULL);
    dbus_connection_flush(conn);


    GError* err = NULL;
    GDBusConnection* connection = g_bus_get_sync(G_BUS_TYPE_SYSTEM,
                                                 NULL, &err);

    if (err != NULL) {
        g_warning("[rev signal] %s", err->message);
        g_error_free(err);
    }

    g_dbus_connection_signal_subscribe(connection,
                                       "com.deepin.dde.lock",
                                       "com.deepin.dde.lock",
                                       "StartAnimation",
                                       "/com/deepin/dde/lock",
                                       NULL,
                                       G_DBUS_SIGNAL_FLAGS_NONE,
                                       start_animation_handler,
                                       NULL, NULL
                                       );
    g_dbus_connection_signal_subscribe(connection,
                                       "com.deepin.dde.lock",
                                       "com.deepin.dde.lock",
                                       "StopAnimation",
                                       "/com/deepin/dde/lock",
                                       NULL,
                                       G_DBUS_SIGNAL_FLAGS_NONE,
                                       start_animation_handler,
                                       NULL, NULL
                                       );
    g_dbus_connection_signal_subscribe(connection,
                                       "com.deepin.dde.lock",
                                       "com.deepin.dde.lock",
                                       "StartLogin",
                                       "/com/deepin/dde/lock",
                                       NULL,
                                       G_DBUS_SIGNAL_FLAGS_NONE,
                                       start_animation_handler,
                                       NULL, NULL
                                       );
    g_object_unref(connection);
}
// }}}
