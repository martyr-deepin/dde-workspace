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
#include "user.h"
#include "session.h"
#include "jsextension.h"
#include "dwebview.h"
#include "i18n.h"
#include "utils.h"
#include "mutils.h"
#include "DBUS_shutdown.h"
#include "background.h"

#define shutdown_HTML_PATH "file://"RESOURCE_DIR"/shutdown/shutdown.html"

#define SHUTDOWN_MAJOR_VERSION 0
#define SHUTDOWN_MINOR_VERSION 0
#define SHUTDOWN_SUBMINOR_VERSION 0
#define SHUTDOWN_VERSION STR(SHUTDOWN_MAJOR_VERSION)"."STR(SHUTDOWN_MINOR_VERSION)"."STR(SHUTDOWN_SUBMINOR_VERSION)
#define SHUTDOWN_CONF "shutdown/config.ini"
static GKeyFile* shutdown_config = NULL;

PRIVATE GtkWidget* container = NULL;
PRIVATE GtkWidget* webview = NULL;

PRIVATE GSettings* dde_bg_g_settings = NULL;
PRIVATE gboolean is_js_already = FALSE;


PRIVATE
void _update_size(GdkScreen *screen, GtkWidget* container)
{
    gtk_widget_set_size_request(container, gdk_screen_width(), gdk_screen_height());
}


PRIVATE
void _on_realize(GtkWidget* container)
{
    GdkScreen* screen =  gdk_screen_get_default();
    _update_size(screen, container);
    g_signal_connect(screen, "size-changed", G_CALLBACK(_update_size), container);
    if (is_js_already)
        background_changed(dde_bg_g_settings, CURRENT_PCITURE, NULL);
}


JS_EXPORT_API
void shutdown_quit()
{
    g_key_file_free(shutdown_config);
    g_object_unref(dde_bg_g_settings);
    gtk_main_quit();
}


PRIVATE
void shutdown_notify_workarea_size()
{
    JSObjectRef workarea_info = json_create();
    json_append_number(workarea_info, "x", 0);
    json_append_number(workarea_info, "y", 0);
    json_append_number(workarea_info, "width", gdk_screen_width());
    json_append_number(workarea_info, "height", gdk_screen_height());
    js_post_message("workarea_changed", workarea_info);
}


PRIVATE
void shutdown_webview_ok()
{
    background_changed(dde_bg_g_settings, CURRENT_PCITURE, NULL);
    is_js_already = TRUE;
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

    GdkScreen *screen;
    GdkRectangle geometry;
    check_version();
    init_i18n ();
    gtk_init (&argc, &argv);

    gdk_window_set_cursor (gdk_get_default_root_window (), gdk_cursor_new (GDK_LEFT_PTR));

    container = create_web_container (FALSE, TRUE);
    gtk_window_set_decorated (GTK_WINDOW (container), FALSE);

    screen = gtk_window_get_screen (GTK_WINDOW (container));
    gdk_screen_get_monitor_geometry (screen, gdk_screen_get_primary_monitor (screen), &geometry);
    gtk_window_set_default_size (GTK_WINDOW (container), geometry.width, geometry.height);
    gtk_window_move (GTK_WINDOW (container), geometry.x, geometry.y);

    webview = d_webview_new_with_uri (shutdown_HTML_PATH);
    gtk_container_add (GTK_CONTAINER(container), GTK_WIDGET (webview));


    g_signal_connect(container, "realize", G_CALLBACK(_on_realize), NULL);
    g_signal_connect (container, "destroy", G_CALLBACK(gtk_main_quit), NULL);
    dde_bg_g_settings = g_settings_new(SCHEMA_ID);
    g_signal_connect(dde_bg_g_settings, "changed::"CURRENT_PCITURE,
                     G_CALLBACK(background_changed), NULL);


    gtk_widget_realize (container);
    gtk_widget_realize (webview);

    GdkWindow* gdkwindow = gtk_widget_get_window (container);
    GdkRGBA rgba = { 0, 0, 0, 0.0 };
    gdk_window_set_background_rgba (gdkwindow, &rgba);
    set_background(gtk_widget_get_window(webview), dde_bg_g_settings,
                            gdk_screen_width(), gdk_screen_height());

    gtk_widget_show_all (container);


    gtk_main ();

    return 0;
}

