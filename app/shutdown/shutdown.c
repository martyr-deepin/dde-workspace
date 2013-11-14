/**
 * Copyright (c) 2011 ~ 2013 Deepin, Inc.
 *               2011 ~ 2013 Long Wei
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

#include <gtk/gtk.h>
#include <cairo-xlib.h>
#include <gdk/gdkx.h>
#include <gdk-pixbuf/gdk-pixbuf.h>
#include <lightdm.h>
#include <unistd.h>
#include <glib.h>
#include <stdlib.h>
#include <glib/gstdio.h>
#include <glib/gprintf.h>
#include <sys/types.h>
#include <signal.h>
#include <X11/XKBlib.h>


#include "X_misc.h"
#include "gs-grab.h"
#include "jsextension.h"
#include "dwebview.h"
#include "i18n.h"
#include "utils.h"
#include "mutils.h"
#include "DBUS_shutdown.h"
#include "background.h"


#define SHUTDOWN_ID_NAME "desktop.app.shutdown"

#define SHUTDOWN_HTML_PATH "file://"RESOURCE_DIR"/shutdown/shutdown.html"

#define SHUTDOWN_MAJOR_VERSION 2
#define SHUTDOWN_MINOR_VERSION 0
#define SHUTDOWN_SUBMINOR_VERSION 0
#define SHUTDOWN_VERSION STR(SHUTDOWN_MAJOR_VERSION)"."STR(SHUTDOWN_MINOR_VERSION)"."STR(SHUTDOWN_SUBMINOR_VERSION)
#define SHUTDOWN_CONF "shutdown/config.ini"
static GKeyFile* shutdown_config = NULL;

PRIVATE GtkWidget* container = NULL;
PRIVATE GtkWidget* webview = NULL;
static GSGrab* grab = NULL;

PRIVATE GSettings* dde_bg_g_settings = NULL;

JS_EXPORT_API
void shutdown_quit()
{
    g_key_file_free(shutdown_config);
    g_object_unref(dde_bg_g_settings);
    gtk_main_quit();
}

static gboolean
prevent_exit (GtkWidget* w, GdkEvent* e)
{
    return TRUE;
}


static void
focus_out_cb (GtkWidget* w, GdkEvent*e, gpointer user_data)
{
    gdk_window_focus (gtk_widget_get_window (container), 0);
}

static void
sigterm_cb (int signum)
{
    gtk_main_quit ();
}

static void
show_cb (GtkWindow* container, gpointer data)
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
xevent_filter (GdkXEvent *xevent, GdkEvent  *event, GdkWindow *window)
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


PRIVATE
void check_version()
{
    if (shutdown_config == NULL)
        shutdown_config = load_app_config(SHUTDOWN_CONF);

    GError* err = NULL;
    gchar* version = g_key_file_get_string(shutdown_config, "main", "version", &err);
    if (err != NULL) {
        g_warning("[%s] read version failed from config file: %s", __func__, err->message);
        g_error_free(err);
        g_key_file_set_string(shutdown_config, "main", "version", SHUTDOWN_VERSION);
        save_app_config(shutdown_config, SHUTDOWN_CONF);
    }

    if (version != NULL)
        g_free(version);
}


int main (int argc, char **argv)
{
    /* if (argc == 2 && 0 == g_strcmp0(argv[1], "-d")) */
    g_setenv("G_MESSAGES_DEBUG", "all", FALSE);
    if (is_application_running(SHUTDOWN_ID_NAME)) {
        g_warning("another instance of application shutdown is running...\n");
        return 0;
    }

    singleton(SHUTDOWN_ID_NAME);

    //remove  option -f
    parse_cmd_line (&argc, &argv);


    check_version();
    init_i18n ();
    gtk_init (&argc, &argv);


    gdk_window_set_cursor (gdk_get_default_root_window (), gdk_cursor_new (GDK_LEFT_PTR));

    container = create_web_container (FALSE, TRUE);
    ensure_fullscreen (container);

    gtk_window_set_decorated (GTK_WINDOW (container), FALSE);
    gtk_window_set_skip_taskbar_hint (GTK_WINDOW (container), TRUE);
    gtk_window_set_skip_pager_hint (GTK_WINDOW (container), TRUE);
    gtk_window_set_keep_above (GTK_WINDOW (container), TRUE);

    gtk_window_fullscreen (GTK_WINDOW (container));
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

    webview = d_webview_new_with_uri (SHUTDOWN_HTML_PATH);
    gtk_container_add (GTK_CONTAINER(container), GTK_WIDGET (webview));
    /*g_signal_connect (container, "delete-event", G_CALLBACK (prevent_exit), NULL);*/
    g_signal_connect (container, "show", G_CALLBACK (show_cb), NULL);
    g_signal_connect (webview, "focus-out-event", G_CALLBACK( focus_out_cb), NULL);

    gtk_widget_realize (container);
    gtk_widget_realize (webview);

    GdkWindow* gdkwindow = gtk_widget_get_window (container);
    GdkRGBA rgba = { 0, 0, 0, 0.0 };
    gdk_window_set_background_rgba (gdkwindow, &rgba);
    gdk_window_set_skip_taskbar_hint (gdkwindow, TRUE);
    gdk_window_set_cursor (gdkwindow, gdk_cursor_new(GDK_LEFT_PTR));


    gdk_window_set_override_redirect (gdkwindow, TRUE);
    select_popup_events ();
    gdk_window_add_filter (NULL, (GdkFilterFunc)xevent_filter, gdkwindow);

    dde_bg_g_settings = g_settings_new(SCHEMA_ID);
    set_background(gtk_widget_get_window(webview), dde_bg_g_settings,
                            gdk_screen_width(), gdk_screen_height());

    grab = gs_grab_new ();
    gtk_widget_show_all (container);

    gdk_window_focus (gtk_widget_get_window (container), 0);
    gdk_window_stick (gdkwindow);


    gtk_main ();

    return 0;
}

