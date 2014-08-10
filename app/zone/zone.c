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
#include "zone.h"

#define ZONE_SCHEMA_ID "com.deepin.dde.zone"
#define ZONE_ID_NAME "desktop.app.zone"

#define HTML_PATH "file://"RESOURCE_DIR"/zone/zone.html"

#define ZONE_MAJOR_VERSION 2
#define ZONE_MINOR_VERSION 0
#define ZONE_SUBMINOR_VERSION 0
#define ZONE_VERSION G_STRINGIFY(ZONE_MAJOR_VERSION)"."G_STRINGIFY(ZONE_MINOR_VERSION)"."G_STRINGIFY(ZONE_SUBMINOR_VERSION)
#define ZONE_CONF "zone/config.ini"
static GKeyFile* zone_config = NULL;

#ifdef NDEBUG
static GSGrab* grab = NULL;
#endif
PRIVATE GtkWidget* container = NULL;

PRIVATE
GSettings* zone_gsettings = NULL;

#ifdef NDEBUG
PRIVATE
gint t_id;
#endif

JS_EXPORT_API
void zone_quit()
{
    g_key_file_free(zone_config);
    gtk_main_quit();
}

JS_EXPORT_API
const gchar* zone_get_config(const gchar* key_name)
{
    const gchar* retval = g_settings_get_string(zone_gsettings, key_name);
    return retval;
}
JS_EXPORT_API
gboolean zone_set_config(const gchar* key_name,const gchar* value)
{
    gboolean retval = g_settings_set_string(zone_gsettings, key_name,value);
    return retval;
}

#ifdef NDEBUG
static void
focus_out_cb (GtkWidget* w G_GNUC_UNUSED, GdkEvent* e G_GNUC_UNUSED, gpointer user_data G_GNUC_UNUSED)
{
    gdk_window_focus (gtk_widget_get_window (container), 0);
}

gboolean gs_grab_move ()
{
    g_message("timeout grab==============");
    gs_grab_move_to_window (grab,
                            gtk_widget_get_window (container),
                            gtk_window_get_screen (container),
                            FALSE);
    /*gtk_timeout_remove(t_id);*/
    return FALSE;
}

static void
show_cb ()
{
    t_id = g_timeout_add(6000,(GSourceFunc)gs_grab_move,NULL);
}

#endif


PRIVATE
void check_version()
{
    if (zone_config == NULL)
        zone_config = load_app_config(ZONE_CONF);

    GError* err = NULL;
    gchar* version = g_key_file_get_string(zone_config, "main", "version", &err);
    if (err != NULL) {
        g_warning("[%s] read version failed from config file: %s", __func__, err->message);
        g_error_free(err);
        g_key_file_set_string(zone_config, "main", "version", ZONE_VERSION);
        save_app_config(zone_config, ZONE_CONF);
    }

    if (version != NULL)
        g_free(version);
}

int main (int argc, char **argv)
{
    if (argc == 2 && 0 == g_strcmp0(argv[1], "-d")){
        g_message("dde-zone -d");
        g_setenv("G_MESSAGES_DEBUG", "all", FALSE);
    }

    if (is_application_running(ZONE_ID_NAME)) {
        g_warning("another instance of application dzone is running...\n");
        return 0;
    }

    singleton(ZONE_ID_NAME);


    check_version();
    init_i18n ();
    zone_gsettings = g_settings_new (ZONE_SCHEMA_ID);

    gtk_init (&argc, &argv);
    g_log_set_default_handler((GLogFunc)log_to_file, "dde-zone");

    container = create_web_container (FALSE, TRUE);

    GtkWidget *webview = d_webview_new_with_uri (HTML_PATH);
    gtk_container_add (GTK_CONTAINER(container), GTK_WIDGET (webview));
    monitors_adaptive(container,webview);

#ifdef NDEBUG
    grab = gs_grab_new ();
    g_message("Zone Not DEBUG");
    g_signal_connect(webview, "draw", G_CALLBACK(erase_background), NULL);
    if (!(argc == 2 && 0 == g_strcmp0(argv[1], "-d")))
        g_signal_connect (container, "show", G_CALLBACK (show_cb), NULL);
    g_signal_connect (webview, "focus-out-event", G_CALLBACK( focus_out_cb), NULL);
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
    gtk_widget_set_opacity (container,0.9);

    gtk_main ();

    return 0;
}

