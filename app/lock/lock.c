/**
 * Copyright (c) 2011 ~ 2012 Deepin, Inc.
 *               2011 ~ 2012 Long Wei
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
#include <gdk/gdk.h>
#include "jsextension.h"
#include "dwebview.h"
#include "i18n.h"
#include "utils.h"
#include "X_misc.h"

#include <stdio.h>
#include <errno.h>
#include <unistd.h>
#include <sys/types.h>
#include <pwd.h>
#include <glib.h>

#define LOCK_HTML_PATH "file://"RESOURCE_DIR"/greeter/lock.html"

GtkWidget* lock_container = NULL;
struct passwd *pw = NULL;

JS_EXPORT_API
const gchar* lock_get_username()
{
    const gchar *username = NULL;

    if(pw != NULL){
        pw = NULL;
    }

    pw = getpwuid(getuid());
    username = pw->pw_name;

    return username;
}

JS_EXPORT_API
void lock_unlock_succeed()
{
    gtk_main_quit();
}

/* return False if unlock succeed */
JS_EXPORT_API
gboolean lock_try_unlock(const gchar *password)
{
    gboolean is_locked;
    gint exit_status;

    gchar *username = g_strdup(lock_get_username());
    gchar *command = g_strdup_printf("%s %s %s", "unlockcheck", username, password);

    g_spawn_command_line_sync(command, NULL, NULL, &exit_status, NULL);

    if(exit_status == 0){
        js_post_message_simply("unlock", "{\"status\":\"%s\"}", "succeed");
        is_locked = FALSE;
    }else{
        js_post_message_simply("unlock", "{\"status\":\"%s\"}", _("Invalid Password"));
        is_locked = TRUE;
    }

    g_free(username);
    username = NULL;

    g_free(command);
    command = NULL;

    return is_locked;
}

gboolean prevent_exit(GtkWidget* w, GdkEvent* e)
{
    return TRUE;
}

int main(int argc, char **argv)
{
    init_i18n();
    gtk_init(&argc, &argv);

    lock_container = create_web_container(FALSE, TRUE);
    gtk_window_set_decorated(GTK_WINDOW(lock_container), FALSE);
    gtk_window_fullscreen(GTK_WINDOW(lock_container));
    gtk_window_set_keep_above(GTK_WINDOW(lock_container), TRUE);

    GtkWidget *webview = d_webview_new_with_uri(LOCK_HTML_PATH);
    gtk_container_add(GTK_CONTAINER(lock_container), GTK_WIDGET(webview));
    g_signal_connect(lock_container, "delete-event", G_CALLBACK(prevent_exit), NULL);
    
    gtk_widget_realize(lock_container);
    GdkWindow *gdkwindow = gtk_widget_get_window(lock_container);

    GdkRGBA rgba = { 0, 0, 0, 0.0 };
    gdk_window_set_background_rgba(gdkwindow, &rgba);

    gdk_window_set_skip_taskbar_hint(gdkwindow, TRUE);

    gdk_window_set_cursor(gdkwindow, gdk_cursor_new(GDK_LEFT_PTR));

    gtk_widget_show_all(lock_container);
    GRAB_DEVICE(NULL);

    gdk_window_stick(gdkwindow);
    gtk_main();
    return 0;
}
