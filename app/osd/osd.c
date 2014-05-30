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


#define ID_NAME "desktop.app.osd"

#define CHOICE_HTML_PATH "file://"RESOURCE_DIR"/osd/osd.html"

#define SHUTDOWN_MAJOR_VERSION 2
#define SHUTDOWN_MINOR_VERSION 0
#define SHUTDOWN_SUBMINOR_VERSION 0
#define SHUTDOWN_VERSION G_STRINGIFY(SHUTDOWN_MAJOR_VERSION)"."G_STRINGIFY(SHUTDOWN_MINOR_VERSION)"."G_STRINGIFY(SHUTDOWN_SUBMINOR_VERSION)
#define SHUTDOWN_CONF "osd/config.ini"
static GKeyFile* shutdown_config = NULL;

PRIVATE GtkWidget* container = NULL;
/*PRIVATE GtkStyleContext *style_context;*/

PRIVATE GSettings* dde_bg_g_settings = NULL;

static struct {
    gboolean is_AudioUp;
    gboolean is_AudioDown;
    gboolean is_AudioMute;
    gboolean is_BrightnessDown;
    gboolean is_BrightnessUp;
    gboolean is_SwitchMonitors;
    gboolean is_SwitchLayout;
    gboolean is_CapsLockOn;
    gboolean is_CapsLockOff;
    gboolean is_NumLockOn;
    gboolean is_NumLockOff;
    gboolean is_TouchPadOn;
    gboolean is_TouchPadOff;
} option = {FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE};
static GOptionEntry entries[] = {
    {"AudioUp", 0, 0, G_OPTION_ARG_NONE, &option.is_AudioUp, "OSD AudioUp", NULL},
    {"AudioDown", 0, 0, G_OPTION_ARG_NONE, &option.is_AudioDown, "OSD AudioDown", NULL},
    {"AudioMute", 0, 0, G_OPTION_ARG_NONE, &option.is_AudioMute, "OSD AudioMute", NULL},
    {"BrightnessDown", 0, 0, G_OPTION_ARG_NONE, &option.is_BrightnessDown, "OSD BrightnessDown", NULL},
    {"BrightnessUp", 0, 0, G_OPTION_ARG_NONE, &option.is_BrightnessUp, "OSD BrightnessUp", NULL},
    {"SwitchMonitors", 0, 0, G_OPTION_ARG_NONE, &option.is_SwitchMonitors, "OSD SwitchMonitors", NULL},
    {"SwitchLayout", 0, 0, G_OPTION_ARG_NONE, &option.is_SwitchLayout, "OSD SwitchLayout", NULL},
    {"CapsLockOn", 0, 0, G_OPTION_ARG_NONE, &option.is_CapsLockOn, "OSD CapsLockOn", NULL},
    {"CapsLockOff", 0, 0, G_OPTION_ARG_NONE, &option.is_CapsLockOff, "OSD CapsLockOff", NULL},
    {"NumLockOn", 0, 0, G_OPTION_ARG_NONE, &option.is_NumLockOn, "OSD NumLockOn", NULL},
    {"NumLockOff", 0, 0, G_OPTION_ARG_NONE, &option.is_NumLockOff, "OSD NumLockOff", NULL},
    {"TouchPadOn", 0, 0, G_OPTION_ARG_NONE, &option.is_TouchPadOn, "OSD TouchPadOn", NULL},
    {"TouchPadOff", 0, 0, G_OPTION_ARG_NONE, &option.is_TouchPadOff, "OSD TouchPadOff", NULL},
    {NULL}
};

JS_EXPORT_API
const char* osd_get_argv()
{
    const char *input = NULL;
    if (option.is_AudioUp) {
        input = "AudioUp";
    } else if (option.is_AudioDown) {
        input = "AudioDown";
    } else if (option.is_AudioMute) {
        input = "AudioMute";
    } else if (option.is_BrightnessDown) {
        input = "BrightnessDown";
    } else if (option.is_BrightnessUp) {
        input = "BrightnessUp";
    } else if (option.is_SwitchMonitors) {
        input = "SwitchMonitors";
    } else if (option.is_SwitchLayout) {
        input = "SwitchLayout";
    } else if (option.is_CapsLockOn) {
        input = "CapsLockOn";
    } else if (option.is_CapsLockOff) {
        input = "CapsLockOff";
    } else if (option.is_NumLockOn) {
        input = "NumLockOn";
    } else if (option.is_NumLockOff) {
        input = "NumLockOff";
    } else if (option.is_TouchPadOn) {
        input = "TouchPadOn";
    } else if (option.is_TouchPadOff) {
        input = "TouchPadOff";
    }
    g_message("osd_get_argv :%s\n",input);
    return input;
}

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
    if (is_application_running(ID_NAME)) {
        g_warning("another instance of application dde-osd is running...\n");
        return 0;
    }

    singleton(ID_NAME);

    check_version();
    init_i18n ();
    
    GOptionContext* ctx = g_option_context_new(NULL);
    g_option_context_add_main_entries(ctx, entries, NULL);
    g_option_context_add_group(ctx, gtk_get_option_group(TRUE));

    GError* error = NULL;
    if (!g_option_context_parse(ctx, &argc, &argv, &error)) {
        g_warning("%s", error->message);
        g_clear_error(&error);
        g_option_context_free(ctx);
        return 0;
    }

    gtk_init (&argc, &argv);
    
    container = create_web_container (FALSE, TRUE);

    gtk_window_set_position (GTK_WINDOW (container), GTK_WIN_POS_CENTER_ALWAYS);

    GtkWidget *webview = d_webview_new_with_uri (CHOICE_HTML_PATH);
    gtk_container_add (GTK_CONTAINER(container), GTK_WIDGET (webview));
    g_signal_connect(webview, "draw", G_CALLBACK(erase_background), NULL);
    
    gtk_widget_realize (container);
    gtk_widget_realize (webview);

    GdkWindow* gdkwindow = gtk_widget_get_window (container);
    gdk_window_set_opacity (gdkwindow, 0.5);
    gdk_window_set_keep_above (gdkwindow, TRUE);
    osd_set_focus(FALSE);

    gtk_widget_show_all (container);

    gtk_main ();

    return 0;
}

