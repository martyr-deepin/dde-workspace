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
#include "background.h"



#define ID_NAME "desktop.app.lowpower"

#define CHOICE_HTML_PATH "file://"RESOURCE_DIR"/lowpower/lowpower.html"

#define MAJOR_VERSION 2
#define MINOR_VERSION 0
#define SUBMINOR_VERSION 0
#define VERSION G_STRINGIFY(MAJOR_VERSION)"."G_STRINGIFY(MINOR_VERSION)"."G_STRINGIFY(SUBMINOR_VERSION)
#define CONF "lowpower/config.ini"
static GKeyFile* config = NULL;

PRIVATE GtkWidget* container = NULL;
#ifdef NDEBUG
static GSGrab* grab = NULL;
#endif


JS_EXPORT_API
void lowpower_quit()
{
    g_key_file_free(config);
    gtk_main_quit();
}

JS_EXPORT_API
void lowpower_restack()
{
    gdk_window_restack(gtk_widget_get_window(container), NULL, TRUE);
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
    gs_grab_move_to_window (grab,
                            gtk_widget_get_window (GTK_WIDGET(container)),
                            gtk_window_get_screen (container),
                            FALSE);
}

#endif


PRIVATE
void check_version()
{
    if (config == NULL)
        config = load_app_config(CONF);

    GError* err = NULL;
    gchar* version = g_key_file_get_string(config, "main", "version", &err);
    if (err != NULL) {
        g_warning("[%s] read version failed from config file: %s", __func__, err->message);
        g_error_free(err);
        g_key_file_set_string(config, "main", "version", VERSION);
        save_app_config(config, CONF);
    }

    if (version != NULL)
        g_free(version);
}

int main (int argc, char **argv)
{
    if (argc == 2 && 0 == g_strcmp0(argv[1], "-d"))
        g_setenv("G_MESSAGES_DEBUG", "all", FALSE);
    if (is_application_running(ID_NAME)) {
        g_warning("another instance of application dlowpower is running...\n");
        return 0;
    }

    singleton(ID_NAME);


    check_version();
    init_i18n ();
    gtk_init (&argc, &argv);

    container = create_web_container (FALSE, TRUE);

    GtkWidget *webview = d_webview_new_with_uri (CHOICE_HTML_PATH);
    gtk_container_add (GTK_CONTAINER(container), GTK_WIDGET (webview));
    monitors_adaptive(container,webview);

#ifdef NDEBUG
    grab = gs_grab_new ();
    g_message("lowpower Not DEBUG");
    g_signal_connect(webview, "draw", G_CALLBACK(erase_background), NULL);
    g_signal_connect (container, "show", G_CALLBACK (show_cb), NULL);
    g_signal_connect (webview, "focus-out-event", G_CALLBACK( focus_out_cb), NULL);
#endif
    gtk_widget_realize (container);
    gtk_widget_realize (webview);

    GdkWindow* gdkwindow = gtk_widget_get_window (container);
    gdk_window_move_resize(gdkwindow, 0, 0, gdk_screen_width(), gdk_screen_height());
    GdkCursor* cursor;
    cursor = gdk_cursor_new(GDK_BLANK_CURSOR);
    gdk_window_set_cursor (gdkwindow, cursor);

#ifdef NDEBUG
    gdk_window_set_keep_above (gdkwindow, TRUE);
    gdk_window_set_override_redirect (gdkwindow, TRUE);
#endif

    gtk_widget_show_all (container);

    gtk_main ();

    return 0;
}

