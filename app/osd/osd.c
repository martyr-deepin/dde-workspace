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
#include <cairo.h>
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
#include "jsextension.h"
#include "dwebview.h"
#include "i18n.h"
#include "utils.h"
/*#include "DBUS_shutdown.h"*/


#define SHUTDOWN_ID_NAME "desktop.app.osd"

#define CHOICE_HTML_PATH "file://"RESOURCE_DIR"/osd/osd.html"

#define SHUTDOWN_MAJOR_VERSION 2
#define SHUTDOWN_MINOR_VERSION 0
#define SHUTDOWN_SUBMINOR_VERSION 0
#define SHUTDOWN_VERSION G_STRINGIFY(SHUTDOWN_MAJOR_VERSION)"."G_STRINGIFY(SHUTDOWN_MINOR_VERSION)"."G_STRINGIFY(SHUTDOWN_SUBMINOR_VERSION)
#define SHUTDOWN_CONF "osd/config.ini"
static GKeyFile* shutdown_config = NULL;
/*static int radius = 18;*/
static int width = 160;
static int height = 160;

PRIVATE GtkWidget* container = NULL;
/*PRIVATE GtkStyleContext *style_context;*/

PRIVATE GSettings* dde_bg_g_settings = NULL;
PRIVATE char **input_argv = NULL;

JS_EXPORT_API
void osd_quit()
{
    g_key_file_free(shutdown_config);
    g_object_unref(dde_bg_g_settings);
    gtk_main_quit();
}

JS_EXPORT_API
void osd_hide()
{
    gtk_widget_hide(container);
}

JS_EXPORT_API
void osd_show()
{
    gtk_widget_show_all(container);
}

G_GNUC_UNUSED
static gboolean
prevent_exit (GtkWidget* w G_GNUC_UNUSED, GdkEvent* e G_GNUC_UNUSED)
{
    return TRUE;
}

static void
G_GNUC_UNUSED sigterm_cb (int signum G_GNUC_UNUSED)
{
    gtk_main_quit ();
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

JS_EXPORT_API
const char* osd_get_argv()
{
    return input_argv[1];
}


JS_EXPORT_API
void osd_set_focus(gboolean focus)
{
    gtk_window_set_focus_on_map (GTK_WINDOW (container), focus);
    gtk_window_set_accept_focus (GTK_WINDOW (container), focus);
    gtk_window_set_focus_visible (GTK_WINDOW (container), focus);

    GdkWindow* gdkwindow = gtk_widget_get_window (container);
    gdk_window_set_focus_on_map (gdkwindow, focus);
    gdk_window_set_accept_focus (gdkwindow, focus);

    gdk_window_set_override_redirect(gdkwindow, !focus);
 }


int main (int argc, char **argv)
{
    if (argc == 2 && 0 == g_strcmp0(argv[1], "-d"))
        g_setenv("G_MESSAGES_DEBUG", "all", FALSE);
    if (is_application_running(SHUTDOWN_ID_NAME)) {
        g_warning("another instance of application dosd is running...\n");
        return 0;
    }

    singleton(SHUTDOWN_ID_NAME);


    check_version();
    init_i18n ();

    gtk_init (&argc, &argv);
    input_argv = argv;
    gdk_window_set_cursor (gdk_get_default_root_window (), gdk_cursor_new (GDK_LEFT_PTR));

    container = create_web_container (FALSE, TRUE);

    gtk_window_set_decorated (GTK_WINDOW (container), FALSE);
    gtk_window_set_skip_taskbar_hint (GTK_WINDOW (container), TRUE);
    gtk_window_set_skip_pager_hint (GTK_WINDOW (container), TRUE);
    gtk_window_set_keep_above (GTK_WINDOW (container), TRUE);
    gtk_window_set_position (GTK_WINDOW (container), GTK_WIN_POS_CENTER_ALWAYS);
    gtk_window_resize (GTK_WINDOW (container), width,height);


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
                           | GDK_LEAVE_NOTIFY_MASK
                           );



    GtkWidget *webview = d_webview_new_with_uri (CHOICE_HTML_PATH);
    gtk_container_add (GTK_CONTAINER(container), GTK_WIDGET (webview));
    gtk_widget_realize (container);
    gtk_widget_realize (webview);

/*    style_context = gtk_widget_get_style_context(webview);*/
    /*gtk_style_context_add_class(style_context,GTK_STYLE_CLASS_OSD);*/
    /*gtk_style_context_add_class(style_context,GTK_STYLE_PROPERTY_BORDER_RADIUS);*/
    /*cairo_t *cr;*/
    /*cairo_surface_t *surface;*/
    /*surface = cairo_image_surface_create(CAIRO_FORMAT_ARGB32, width, height);*/
    /*cr = cairo_create(surface);*/
    /*[>cairo_set_source_rgba (cr, 1, 0, 0, 0.80);<]*/
    /*[>cairo_fill (cr);<]*/
    /*gtk_render_background(style_context,cr,radius,radius,width,height);*/
    /*[>gtk_style_context_set_background(style_context,gdkwindow);<]*/
    /*gtk_style_context_restore(style_context);*/
    /*[>cairo_destory(cr);<]*/
    /*[>cairo_surface_write_to_png(surface,"gtkbackground.png");<]*/
    /*[>cairo_surface_destory(surface);<]*/


    GdkWindow* gdkwindow = gtk_widget_get_window (container);

    GdkRGBA rgba = { 0, 0, 0, 0.0 };
    gdk_window_set_background_rgba (gdkwindow, &rgba);
    gdk_window_set_opacity (gdkwindow, 0.7);
    gdk_window_set_keep_above (gdkwindow, TRUE);

    osd_set_focus(FALSE);

    /*gdk_window_show(gdkwindow);*/
    /*gtk_widget_show_all (container);*/

    gtk_main ();

    return 0;
}

