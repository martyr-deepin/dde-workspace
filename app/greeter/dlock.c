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
#include <glib.h>
#include <glib/gstdio.h>
#include <gio/gio.h>
#include <stdio.h>
#include <errno.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <pwd.h>

#define LOCK_HTML_PATH "file://"RESOURCE_DIR"/greeter/lock.html"

GtkWidget* lock_container = NULL;
static const gchar *username = NULL;
static gchar* lockpid_file = NULL;

JS_EXPORT_API
const gchar* lock_get_username()
{
    return username;
}

JS_EXPORT_API
const gchar* lock_get_icon()
{
    GDBusProxy *account_proxy = NULL;
    GError * error = NULL;

    account_proxy = g_dbus_proxy_new_for_bus_sync(G_BUS_TYPE_SYSTEM,
            G_DBUS_PROXY_FLAGS_NONE,
            NULL,
            "org.freedesktop.Accounts",
            "/org/freedesktop/Accounts",
            "org.freedesktop.Accounts",
            NULL, 
            &error);

    if(error != NULL){
        g_debug("connect org.freedesktop.Accounts failed");
        g_error_free(error);
    }

    error = NULL;
    GVariant * user_path_var = NULL;
    user_path_var = g_dbus_proxy_call_sync(account_proxy, 
           "FindUserByName",
            g_variant_new("(s)", username),
            G_DBUS_CALL_FLAGS_NONE,
            -1, 
            NULL,
            &error);

    if(error != NULL){
        g_debug("find user by name failed");
        g_error_free(error);
    }

    error = NULL;
    char *user_path = NULL;
    g_variant_get(user_path_var, "(o)", &user_path);

    g_variant_unref(user_path_var);
    g_object_unref(account_proxy);

    GDBusProxy *user_proxy = NULL;
    user_proxy = g_dbus_proxy_new_for_bus_sync(G_BUS_TYPE_SYSTEM,
            G_DBUS_PROXY_FLAGS_NONE,
            NULL,
            "org.freedesktop.Accounts",
            user_path,
            "org.freedesktop.DBus.Properties",
            NULL,
            &error);

    if(error != NULL){
        g_debug("connect org.freedesktop.Accounts failed");
        g_error_free(error);
    }

    error = NULL;
    g_free(user_path);

    GVariant *user_icon_var = NULL;
    user_icon_var = g_dbus_proxy_call_sync(user_proxy,
            "Get",
            g_variant_new("(ss)", "org.freedesktop.Accounts.User", "IconFile"),
            G_DBUS_CALL_FLAGS_NONE,
            -1, 
            NULL,
            &error);

    if(error != NULL){
        g_debug("get user icon failed");
        g_error_free(error);
    }

    error = NULL;
    const gchar *user_icon = NULL;
    g_variant_get(user_icon_var, "(v)", &user_icon);

    g_variant_unref(user_icon_var);
    g_object_unref(user_proxy);

    if(g_file_test(user_icon, G_FILE_TEST_EXISTS)){
        return user_icon;
    }else{
        return "nonexists";
    }
}

JS_EXPORT_API
void lock_unlock_succeed()
{
    g_remove(lockpid_file);
    g_free(lockpid_file);
    gtk_main_quit();
}

/* return False if unlock succeed */
JS_EXPORT_API
gboolean lock_try_unlock(const gchar *password)
{
    gboolean is_locked;
    gint exit_status;

    gchar *command = g_strdup_printf("%s %s %s", "unlockcheck", username, password);

    g_spawn_command_line_sync(command, NULL, NULL, &exit_status, NULL);

    if(exit_status == 0){
        js_post_message_simply("unlock", "{\"status\":\"%s\"}", "succeed");
        is_locked = FALSE;
    }else{
        js_post_message_simply("unlock", "{\"status\":\"%s\"}", _("Invalid Password"));
        is_locked = TRUE;
    }

    g_free(command);
    command = NULL;

    return is_locked;
}

JS_EXPORT_API
void lock_switch_user()
{
    g_spawn_command_line_async("switchtogreeter", NULL);
}

JS_EXPORT_API
gchar * lock_get_date()
{
    char outstr[200];
    time_t t;
    struct tm *tmp;

    setlocale(LC_ALL, "");
    t = time(NULL);
    tmp = localtime(&t);
    if (tmp == NULL) {
        perror("localtime");
    }

    if (strftime(outstr, sizeof(outstr), _("%a,%b%d,%Y"), tmp) == 0) {
            fprintf(stderr, "strftime returned 0");
    }

    return g_strdup(outstr);
}

gboolean prevent_exit(GtkWidget* w, GdkEvent* e)
{
    return TRUE;
}

int main(int argc, char **argv)
{
    init_i18n();
    gtk_init(&argc, &argv);

    username = g_get_user_name();

    gchar *user_lock_path = g_strdup_printf("%s%s", username, ".dlock.app.deepin");

    if(is_application_running(user_lock_path)){
        g_warning("another instance of dlock is running by current user...\n");
        g_free(user_lock_path);
        return 0;
    }

    g_free(user_lock_path);

    lockpid_file = g_strdup_printf("%s%s%s", "/home/", username, "/dlockpid");
    if(g_file_test(lockpid_file, G_FILE_TEST_EXISTS)){
        g_warning("remove old pid info before lock"); 
        g_remove(lockpid_file);
    }

    if(g_creat(lockpid_file, O_RDWR) == -1){
        g_warning("touch lockpid_file failed\n");
    }
    
    gchar *contents = g_strdup_printf("%d", getpid());
    g_file_set_contents(lockpid_file, contents, -1, NULL);

    g_free(contents);

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
    //GRAB_DEVICE(NULL);

    //gdk_window_stick(gdkwindow);
    gtk_main();
    return 0;
}
