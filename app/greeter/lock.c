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

/*#include "settings.h"*/
/*#include "camera.h"*/

#include "X_misc.h"
#include "gs-grab.h"
#include "lock_util.h"
#include "background.h"
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
double lock_get_theme()
{
    return get_theme_config();
}

JS_EXPORT_API
gboolean lock_try_unlock (const gchar *username,const gchar *password)
{
    g_message("face_login hide");
/*    if (lock_use_face_recognition_login(lock_get_username()) && recognition_info.detect_is_enabled) {*/
        /*gtk_main_quit();*/
        /*return TRUE;*/
    /*}*/

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


JS_EXPORT_API
gboolean lock_start_session(const gchar *username,const gchar *password,const gchar *session)
{

    if (g_str_equal(username,lock_get_username())){
        gboolean lock = lock_try_unlock(username,password);
        return lock;
    }

    GError *error = NULL;
    const gchar *startsession_cmd = g_strdup_printf ("startsession %s %s %s",username, password, session);
    g_spawn_command_line_sync (startsession_cmd, NULL, NULL, NULL, &error);
    if (error != NULL) {
        g_warning ("startsession_cmd error:%s\n", error->message);
        g_error_free (error);
        return FALSE;
    }
    error = NULL;
    return TRUE;

}

static gboolean
prevent_exit (GtkWidget* w G_GNUC_UNUSED, GdkEvent* e G_GNUC_UNUSED)
{
    return TRUE;
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
lock_show_cb (GtkWindow* container, gpointer data G_GNUC_UNUSED)
{
    gs_grab_move_to_window (grab,
                            gtk_widget_get_window (GTK_WIDGET(container)),
                            gtk_window_get_screen (container),
                            FALSE);
}

static void
select_popup_events (void)
{
    XWindowAttributes attr;
    unsigned long     events;

    gdk_error_trap_push ();

    memset (&attr, 0, sizeof (attr));
    XGetWindowAttributes (GDK_DISPLAY_XDISPLAY (gdk_display_get_default ()), GDK_ROOT_WINDOW (), &attr);

    events = SubstructureNotifyMask | attr.your_event_mask;
    XSelectInput (GDK_DISPLAY_XDISPLAY (gdk_display_get_default ()), GDK_ROOT_WINDOW (), events);

    gdk_error_trap_pop_ignored ();
}

static gboolean
x11_window_is_ours (Window window)
{
    GdkWindow *gwindow;
    gboolean   ret;

    ret = FALSE;

    gwindow = gdk_x11_window_lookup_for_display (gdk_display_get_default (), window);

    if (gwindow && (window != GDK_ROOT_WINDOW ())) {
            ret = TRUE;
    }

    return ret;
}

static GdkFilterReturn
xevent_filter (GdkXEvent *xevent, GdkEvent  *event G_GNUC_UNUSED, GdkWindow *window)
{
    XEvent *ev = xevent;

    switch (ev->type) {

        g_debug ("event type: %d", ev->xany.type);
        case MapNotify:
            g_debug("dlock: MapNotify");
             {
                 XMapEvent *xme = &ev->xmap;
                 if (! x11_window_is_ours (xme->window))
                 {
            g_debug("dlock: gdk_window_raise");
                      gdk_window_raise (window);
                 }
             }
             break;

        case ConfigureNotify:
             g_debug("dlock: ConfigureNotify");
             {
                  XConfigureEvent *xce = &ev->xconfigure;
                  if (! x11_window_is_ours (xce->window))
                  {
                      g_debug("dlock: gdk_window_raise");
                      gdk_window_raise (window);
                  }
             }
             break;

        default:
             break;
    }

    return GDK_FILTER_CONTINUE;
}
#endif

int main (int argc, char **argv)
{
    if (argc == 2 && 0 == g_strcmp0(argv[1], "-d"))
        g_setenv("G_MESSAGES_DEBUG", "all", FALSE);

    init_i18n ();
    init_theme();
    gtk_init (&argc, &argv);

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

    gtk_window_set_decorated (GTK_WINDOW(container), FALSE);
    gtk_window_set_skip_taskbar_hint (GTK_WINDOW (container), TRUE);
    gtk_window_set_skip_pager_hint (GTK_WINDOW (container), TRUE);

    gtk_widget_set_events (GTK_WIDGET (container),
                           gtk_widget_get_events (GTK_WIDGET (container))
                           | GDK_POINTER_MOTION_MASK
                           | GDK_BUTTON_PRESS_MASK
                           | GDK_BUTTON_RELEASE_MASK
                           | GDK_KEY_PRESS_MASK
                           | GDK_KEY_RELEASE_MASK
                           | GDK_EXPOSURE_MASK
                           | GDK_VISIBILITY_NOTIFY_MASK
                           | GDK_ENTER_NOTIFY_MASK
                           | GDK_LEAVE_NOTIFY_MASK);

    GtkWidget *webview = d_webview_new_with_uri (LOCK_HTML_PATH);
    gtk_container_add (GTK_CONTAINER (container), GTK_WIDGET (webview));

    monitors_adaptive(container,webview);
    BackgroundInfo* bg_info = create_background_info(container, webview);
    background_info_set_background_by_file(bg_info, "/usr/share/backgrounds/default_background.jpg");

#ifdef NDEBUG
    g_message(" Lock Not DEBUG");
    gtk_window_set_keep_above (GTK_WINDOW (container), TRUE);
    g_signal_connect (container, "show", G_CALLBACK (lock_show_cb), NULL);
    g_signal_connect (webview, "focus-out-event", G_CALLBACK( focus_out_cb), NULL);
#endif
    g_signal_connect (container, "delete-event", G_CALLBACK (prevent_exit), NULL);
    gtk_widget_realize (container);
    gtk_widget_realize (webview);

    GdkWindow *gdkwindow = gtk_widget_get_window (container);
    GdkRGBA rgba = { 0, 0, 0, 0.0 };
    gdk_window_set_background_rgba (gdkwindow, &rgba);
    gdk_window_set_skip_taskbar_hint (gdkwindow, TRUE);
    gdk_window_set_cursor (gdkwindow, gdk_cursor_new(GDK_LEFT_PTR));


#ifdef NDEBUG
    gdk_window_set_keep_above (gdkwindow, TRUE);
    gdk_window_set_override_redirect (gdkwindow, TRUE);
    select_popup_events ();
    gdk_window_add_filter (NULL, (GdkFilterFunc)xevent_filter, gdkwindow);
    grab = gs_grab_new ();
#endif

    gtk_widget_show_all (container);

    gdk_window_focus (gtk_widget_get_window (container), 0);
    gdk_window_stick (gdkwindow);

    /*init_camera(argc, argv);*/
    /*turn_numlock_on ();*/
    gtk_main ();
    /*destroy_camera();*/

    return 0;
}

