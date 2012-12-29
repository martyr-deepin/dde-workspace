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

#include <stdio.h>
#include <errno.h>
#include <unistd.h>
#include <sys/types.h>
#include <pwd.h>
#include <glib.h>

#define LOCK_HTML_PATH "file://"RESOURCE_DIR"/lock/lock.html"

GtkWidget* lock_container = NULL;
struct passwd *pw = NULL;
gboolean is_locked = FALSE;

JS_EXPORT_API
const gchar* lock_get_username()
{
    const gchar *username = NULL;

    pw = getpwuid(getuid());
    username = g_strdup(pw->pw_name);

    return username;
}

JS_EXPORT_API
gboolean lock_is_locked()
{
    return is_locked;
}

JS_EXPORT_API
void lock_unlock_succeed()
{
    gtk_main_quit();
}

JS_EXPORT_API
void lock_try_lock()
{
    if(is_locked){
        return;
    }
    
    lock_container = create_web_container(FALSE, TRUE);
    gtk_window_set_decorated(GTK_WINDOW(lock_container), FALSE);
    gtk_window_fullscreen(GTK_WINDOW(lock_container));

    g_signal_connect(lock_container, "destroy", G_CALLBACK(gtk_main_quit), NULL);

    GtkWidget *webview = d_webview_new_with_uri(LOCK_HTML_PATH);
    gtk_container_add(GTK_CONTAINER(lock_container), GTK_WIDGET(webview));
    
    gtk_widget_realize(lock_container);

    GdkScreen *screen = gtk_window_get_screen(GTK_WINDOW(lock_container));
    gint width = gdk_screen_get_width(screen);
    gint height = gdk_screen_get_height(screen);     

    GdkWindow *gdk_window = gdk_get_default_root_window();

    gtk_window_set_default_size(GTK_WINDOW(lock_container), width, height);

    gdk_window_set_cursor(gdk_window, gdk_cursor_new(GDK_LEFT_PTR));

    gdk_keyboard_grab(gdk_window, TRUE, GDK_CURRENT_TIME);
    /* GdkDevice *device = gtk_get_current_event_device(); */
    /* gdk_device_grab(device, gdk_window, GDK_OWNERSHIP_WINDOW, TRUE, GDK_ALL_EVENTS_MASK, NULL, GDK_CURRENT_TIME); */

    gtk_widget_show_all(lock_container);

    is_locked = TRUE;

    return ;
}

/* return False if unlock succeed */
JS_EXPORT_API
gboolean lock_try_unlock(const gchar *password)
{
    gint exit_status;

    if(!is_locked){
        return FALSE;
    }

    const gchar *username = g_strdup(lock_get_username());
    const gchar *command = g_strdup_printf("%s %s %s", "unlockcheck", username, g_strdup(password));

    g_spawn_command_line_sync(command, NULL, NULL, &exit_status, NULL);

    if(exit_status == 0){
        js_post_message_simply("unlock", "{\"status\":\"%s\"}", "succeed");
        is_locked = FALSE;
    }else{
        js_post_message_simply("unlock", "{\"status\":\"%s\"}", "failed");
        is_locked = TRUE;
    }

    return is_locked;
}

int main(int argc, char **argv)
{
    init_i18n();
    gtk_init(&argc, &argv);

    lock_try_lock();

    gtk_main();
    return 0;
}
