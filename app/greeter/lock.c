/**
 * Copyright (c) 2011 ~ 2014 Deepin, Inc.
 *               2011 ~ 2014 Long Wei
 *
 * Author:      Long Wei <yilang2007lw@gmail.com>
 *              bluth <yuanchenglu001@gmail.com>
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

#include <string.h>
#include <gtk/gtk.h>
#include <gdk/gdk.h>
#include <gdk/gdkx.h>
#include <glib.h>
#include <glib/gstdio.h>
#include <gio/gio.h>
#include <stdio.h>
#include <errno.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <pwd.h>
#include <X11/XKBlib.h>

#include "jsextension.h"
#include "dwebview.h"
#include "i18n.h"
#include "utils.h"
#include "mutils.h"
#include "background.h"

#include "X_misc.h"
#include "gs-grab.h"
#include "lock_util.h"
#include "theme.h"

#define LOCK_HTML_PATH "file://"RESOURCE_DIR"/greeter/lock.html"


#ifdef NDEBUG
static GSGrab* grab = NULL;
#endif
static GtkWidget* container = NULL;
const gchar *username = NULL;

JS_EXPORT_API
void lock_quit()
{
    gtk_main_quit();
}

JS_EXPORT_API
char* lock_get_theme()
{
    return get_theme_config();
}

JS_EXPORT_API
gboolean lock_try_unlock (const gchar *username,const gchar *password)
{
    gboolean succeed = FALSE;

    GDBusProxy *lock_proxy = NULL;
    GVariant *lock_succeed = NULL;
    GError *error = NULL;

    lock_proxy = g_dbus_proxy_new_for_bus_sync (G_BUS_TYPE_SYSTEM,
                                                G_DBUS_PROXY_FLAGS_NONE,
                                                NULL,
                                                "com.deepin.dde.lock",
                                                "/com/deepin/dde/lock",
                                                "com.deepin.dde.lock",
                                                NULL,
                                                &error);

    if (error != NULL) {
        g_warning ("connect com.deepin.dde.lock failed");
        g_error_free (error);
    }
    error = NULL;

    /*if (username == NULL) {*/
        /*username = lock_get_username ();*/
    /*}*/

    lock_succeed  = g_dbus_proxy_call_sync (lock_proxy,
                    "UnlockCheck",
                    g_variant_new ("(ss)", username, password),
                    G_DBUS_CALL_FLAGS_NONE,
                    -1,
                    NULL,
                    &error);

    //g_assert (lock_succeed != NULL);
    if (error != NULL) {
        g_warning ("try unlock:UnlockCheck %s\n", error->message);
        g_error_free (error);
    }
    error = NULL;

    g_variant_get (lock_succeed, "(b)", &succeed);

    g_variant_unref (lock_succeed);
    g_object_unref (lock_proxy);

    if (succeed) {
        js_post_signal("auth-succeed");

    } else {
        JSObjectRef error_message = json_create();
        json_append_string(error_message, "error", _("Invalid Password"));
        js_post_message("auth-failed", error_message);
    }

    return succeed;
}


static void
sigterm_cb (int signum G_GNUC_UNUSED)
{
    gtk_main_quit ();
}


#ifdef NDEBUG
static void
focus_out_cb (GtkWidget* w G_GNUC_UNUSED, GdkEvent*e G_GNUC_UNUSED, gpointer user_data G_GNUC_UNUSED)
{
    gdk_window_focus (gtk_widget_get_window (container), 0);
}

static void
show_cb (GtkWindow* container, gpointer data G_GNUC_UNUSED)
{
    gs_grab_move_to_window (grab,gtk_widget_get_window (container),gtk_window_get_screen (container),FALSE);
}

#endif

int main (int argc, char **argv)
{
    if (argc == 2 && 0 == g_strcmp0(argv[1], "-d"))
        g_setenv("G_MESSAGES_DEBUG", "all", FALSE);

    init_i18n ();
    init_theme();
    gtk_init (&argc, &argv);
    g_log_set_default_handler((GLogFunc)log_to_file, "dde-lock");

    signal (SIGTERM, sigterm_cb);

    if (lock_is_running ()) {
        return 1;
    }

    if (lock_is_guest ()) {
        g_warning("you are the guest!!!");
        return 1;
    }

    lock_report_pid ();

    container = create_web_container (FALSE, TRUE);
    GtkWidget* webview = d_webview_new_with_uri (LOCK_HTML_PATH);
    gtk_container_add (GTK_CONTAINER (container), GTK_WIDGET (webview));
    monitors_adaptive(container,webview);
    set_theme_background(container,webview);

#ifdef NDEBUG
    grab = gs_grab_new ();
    g_message(" Lock Not DEBUG");
    gtk_window_set_keep_above (GTK_WINDOW (container), TRUE);
    g_signal_connect (container, "show", G_CALLBACK (show_cb), NULL);
    g_signal_connect (webview, "focus-out-event", G_CALLBACK(focus_out_cb), NULL);
#endif
    gtk_widget_realize (container);
    gtk_widget_realize (webview);
    
    GdkWindow* gdkwindow = gtk_widget_get_window (container);
    gdk_window_move_resize(gdkwindow, 0, 0, gdk_screen_width(), gdk_screen_height());

#ifdef NDEBUG
    gdk_window_set_keep_above (gdkwindow, TRUE);
    gdk_window_set_override_redirect (gdkwindow, TRUE);
#endif

    gtk_widget_show_all (container);

    /*turn_numlock_on ();*/
    gtk_main ();
    return 0;
}

