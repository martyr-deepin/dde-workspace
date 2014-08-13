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
guint grab_timeout;
guint grab_remove_timeout;

#define HARDWARE_KEYCODE_SUPER 133
#define HARDWARE_KEYCODE_P 33

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

PRIVATE
gboolean keyboard_grab (){
    int status = gdk_keyboard_grab(gtk_widget_get_window(container), FALSE, GDK_CURRENT_TIME);
    g_debug("keyboard grab:%d===%d",status,GDK_GRAB_SUCCESS);
    if (status == GDK_GRAB_SUCCESS){
        g_source_remove(grab_remove_timeout);
        return FALSE;
    }else{
        return TRUE;
    }
}

JS_EXPORT_API
void osd_grab (){
    grab_timeout = g_timeout_add(50,(GSourceFunc)keyboard_grab,NULL);
    grab_remove_timeout = g_timeout_add(1000,(GSourceFunc)g_source_remove,(gpointer)grab_timeout);
}

JS_EXPORT_API
void osd_ungrab (){
    gdk_keyboard_ungrab(GDK_CURRENT_TIME);
}

JS_EXPORT_API
void osd_quit()
{
    g_warning("osd_quit");
    g_key_file_free(shutdown_config);
    if(option.is_SwitchMonitors){
        gdk_keyboard_ungrab(GDK_CURRENT_TIME);
    }
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
sigterm_cb (int signum G_GNUC_UNUSED)
{
    gtk_main_quit ();
}


static void
show_cb (GtkWindow* container G_GNUC_UNUSED, gpointer data G_GNUC_UNUSED)
{
    osd_grab();
}

static gboolean
key_release_cb (GtkWidget* w G_GNUC_UNUSED, GdkEventKey*e, gpointer user_data G_GNUC_UNUSED){
    guint16 keycode = e->hardware_keycode;
    g_message("event type:%d,keycode:%d",e->type,keycode);
    if(keycode == HARDWARE_KEYCODE_SUPER){
        js_post_signal("key-release-super");
    }else if(keycode == HARDWARE_KEYCODE_P){
        js_post_signal("key-release-p");
    }
    return FALSE;
}

JS_EXPORT_API
void osd_spawn_command(gchar* cmd){
    spawn_command_sync(cmd,FALSE);
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
    GdkWindow* gdkwindow = gtk_widget_get_window (container);
    gdk_window_set_accept_focus(gdkwindow,focus);
}

#define KEYBOARD_SCHEMA_ID "com.deepin.dde.keyboard"
gboolean osd_capslock_toggle()
{
    GSettings* gsettings = g_settings_new (KEYBOARD_SCHEMA_ID);
    gboolean capslock_toggle = g_settings_get_boolean(gsettings, "capslock-toggle");
    g_message("osd_capslock_toggle:%d",capslock_toggle);
    g_object_unref(gsettings);
    return capslock_toggle;
}


int main (int argc, char **argv)
{
    g_setenv("G_MESSAGES_DEBUG", "all", FALSE);
    
    signal (SIGTERM, sigterm_cb);
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

    if (argc == 1){
        g_warning("please input the option\n");
        const gchar * help = g_option_context_get_help(ctx,TRUE,gtk_get_option_group(TRUE));
        g_message("%s",help);
        return 0;
    }

    GError* error = NULL;
    if (!g_option_context_parse(ctx, &argc, &argv, &error)) {
        g_warning("%s", error->message);
        g_clear_error(&error);
        g_option_context_free(ctx);
        return 0;
    }
    if(option.is_CapsLockOn || option.is_CapsLockOff){
        if(!osd_capslock_toggle()){
            return 0;
        }
    }

    gtk_init (&argc, &argv);
    g_log_set_default_handler((GLogFunc)log_to_file, "dde-osd");

    container = create_web_container (FALSE, TRUE);

    gtk_window_set_position (GTK_WINDOW (container), GTK_WIN_POS_CENTER_ALWAYS);

    GtkWidget *webview = d_webview_new_with_uri (CHOICE_HTML_PATH);
    gtk_container_add (GTK_CONTAINER(container), GTK_WIDGET (webview));

    g_signal_connect(webview, "draw", G_CALLBACK(erase_background), NULL);
    if(option.is_SwitchMonitors){
        g_signal_connect (container, "show", G_CALLBACK (show_cb), NULL);
        g_signal_connect (webview, "key-release-event", G_CALLBACK(key_release_cb), NULL);
    }

    gtk_widget_realize (container);
    gtk_widget_realize (webview);

    GdkWindow* gdkwindow = gtk_widget_get_window (container);
    if(option.is_SwitchMonitors){
        gdk_window_set_events(gdkwindow,GDK_KEY_RELEASE_MASK);
    }
    gdk_window_set_opacity (gdkwindow, 0.5);
    gdk_window_set_keep_above (gdkwindow, TRUE);
    gdk_window_set_override_redirect(gdkwindow, TRUE);
    osd_set_focus(FALSE);

    gtk_widget_show_all (container);

    gtk_main ();
    return 0;
}

