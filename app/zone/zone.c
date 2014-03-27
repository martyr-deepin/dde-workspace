/**
 * Copyright (c) 2011 ~ 2014 Deepin, Inc.
 *               2011 ~ 2014 bluth
 *
 * Author:      bluth <yuanchenglu001@gmail.com>
 * Maintainer:  bluth <yuanchenglu001@gmail.com>
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
#include <unistd.h>
#include <glib.h>
#include <stdlib.h>
#include <string.h>
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
/*#include "DBUS_shutdown.h"*/

#define ZONE_SCHEMA_ID "com.deepin.dde.zone"
#define SHUTDOWN_ID_NAME "desktop.app.zone"

#define CHOICE_HTML_PATH "file://"RESOURCE_DIR"/zone/zone.html"

#define SHUTDOWN_MAJOR_VERSION 2
#define SHUTDOWN_MINOR_VERSION 0
#define SHUTDOWN_SUBMINOR_VERSION 0
#define SHUTDOWN_VERSION G_STRINGIFY(SHUTDOWN_MAJOR_VERSION)"."G_STRINGIFY(SHUTDOWN_MINOR_VERSION)"."G_STRINGIFY(SHUTDOWN_SUBMINOR_VERSION)
#define SHUTDOWN_CONF "zone/config.ini"
static GKeyFile* shutdown_config = NULL;

PRIVATE GtkWidget* container = NULL;
static GSGrab* grab = NULL;

PRIVATE
GSettings* zone_gsettings = NULL;

static gint _NONE_ = 0;
static gint _LAUNCHER_ = 1;//left-up
static gint _WORKSPACE_ = 2;//right-up
static gint _DESKTOP_ = 3;//left-down
static gint _SYSTEMSETTINGS_ = 4;//right-down

JS_EXPORT_API
void zone_quit()
{
    g_key_file_free(shutdown_config);
    gtk_main_quit();
}

JS_EXPORT_API
gint zone_get_config(const char* key_name)
{
    gint retval = g_settings_get_boolean(zone_gsettings, key_name);
    return retval;
}
JS_EXPORT_API
gboolean zone_set_config(const char* key_name,gint value)
{
    gboolean retval = g_settings_set_boolean(zone_gsettings, key_name,value);
    return retval;
}

G_GNUC_UNUSED
static gboolean
prevent_exit (GtkWidget* w, GdkEvent* e)
{
    NOUSED(w);
    NOUSED(e);
    return TRUE;
}

static void
G_GNUC_UNUSED sigterm_cb (int signum)
{
    NOUSED(signum);
    gtk_main_quit ();
}


#ifndef NDEBUG
static void
focus_out_cb (GtkWidget* w, GdkEvent*e, gpointer user_data)
{
    NOUSED(w);
    NOUSED(e);
    NOUSED(user_data);
    gdk_window_focus (gtk_widget_get_window (container), 0);
}


static void
show_cb (GtkWindow* container, gpointer data)
{
    NOUSED(data);
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
    NOUSED(event);
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
    if (argc == 2 && 0 == g_strcmp0(argv[1], "-d"))
        g_setenv("G_MESSAGES_DEBUG", "all", FALSE);
    if (is_application_running(SHUTDOWN_ID_NAME)) {
        g_warning("another instance of application dzone is running...\n");
        return 0;
    }

    singleton(SHUTDOWN_ID_NAME);


    check_version();
    init_i18n ();
    zone_gsettings = g_settings_new (ZONE_SCHEMA_ID);

    gtk_init (&argc, &argv);
    gdk_window_set_cursor (gdk_get_default_root_window (), gdk_cursor_new (GDK_LEFT_PTR));

    container = create_web_container (FALSE, TRUE);
    ensure_fullscreen (container);

    gtk_window_set_decorated (GTK_WINDOW (container), FALSE);
    gtk_window_set_skip_taskbar_hint (GTK_WINDOW (container), TRUE);
    gtk_window_set_skip_pager_hint (GTK_WINDOW (container), TRUE);

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

    GtkWidget *webview = d_webview_new_with_uri (CHOICE_HTML_PATH);
    gtk_container_add (GTK_CONTAINER(container), GTK_WIDGET (webview));

#ifndef NDEBUG
    gtk_window_set_keep_above (GTK_WINDOW (container), TRUE);
    g_signal_connect (container, "show", G_CALLBACK (show_cb), NULL);
    g_signal_connect (webview, "focus-out-event", G_CALLBACK( focus_out_cb), NULL);
#endif
    gtk_widget_realize (container);
    gtk_widget_realize (webview);

    GdkWindow* gdkwindow = gtk_widget_get_window (container);
    GdkRGBA rgba = { 0, 0, 0, 0.85 };
    gdk_window_set_background_rgba (gdkwindow, &rgba);
    gdk_window_set_skip_taskbar_hint (gdkwindow, TRUE);
    gdk_window_set_cursor (gdkwindow, gdk_cursor_new(GDK_LEFT_PTR));

#ifndef NDEBUG
    gdk_window_set_keep_above (gdkwindow, TRUE);
    gdk_window_set_override_redirect (gdkwindow, TRUE);
    select_popup_events ();
    gdk_window_add_filter (NULL, (GdkFilterFunc)xevent_filter, gdkwindow);
#endif

    grab = gs_grab_new ();
    gtk_widget_show_all (container);
    gtk_widget_set_opacity (container,0.9);

    gdk_window_focus (gtk_widget_get_window (container), 0);
    gdk_window_stick (gdkwindow);


    gtk_main ();

    return 0;
}

