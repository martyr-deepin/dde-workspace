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
#include <string.h>
#include <gtk/gtk.h>
#include <gdk/gdk.h>
#include <gdk/gdkx.h>
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
#include "jsextension.h"
#include "dwebview.h"
#include "i18n.h"
#include "account.h"
#include "utils.h"
#include "X_misc.h"
#include <X11/XKBlib.h>
#include "gs-grab.h"
#include "settings.h"
#include "connection.h"
#include "camera.h"

#define LOCK_HTML_PATH "file://"RESOURCE_DIR"/greeter/lock.html"

static GSGrab* grab = NULL;

static const gchar *username = NULL;
static GtkWidget* lock_container = NULL;
static gchar* lockpid_file = NULL;
static GDBusProxy *user_proxy = NULL;
GError *error = NULL;
static GPid pid = 0;

static void init_user();
static void sigterm_cb(int signum);
static void lock_report_pid();
int kill(pid_t, int);


JS_EXPORT_API
void lock_webview_ok()
{
    static gboolean inited = FALSE;
    if (!inited) {
        if (lock_use_face_recognition_login())
            js_post_message_simply("draw", NULL);

        inited = TRUE;
    }
}

static void init_user()
{
    username = g_get_user_name();

    GDBusProxy *account_proxy = g_dbus_proxy_new_for_bus_sync(G_BUS_TYPE_SYSTEM,
            G_DBUS_PROXY_FLAGS_NONE,
            NULL,
            "org.freedesktop.Accounts",
            "/org/freedesktop/Accounts",
            "org.freedesktop.Accounts",
            NULL,
            &error);

    g_assert (account_proxy != NULL);
    if(error != NULL){
        g_debug("connect org.freedesktop.Accounts failed");
        g_clear_error(&error);
    }

    GVariant* user_path_var = g_dbus_proxy_call_sync(account_proxy,
           "FindUserByName",
            g_variant_new("(s)", username),
            G_DBUS_CALL_FLAGS_NONE,
            -1,
            NULL,
            &error);

    g_assert(user_path_var != NULL);
    if(error != NULL){
        g_debug("find user by name failed");
        g_clear_error(&error);
    }

    g_object_unref(account_proxy);

    gchar * user_path = NULL;
    g_variant_get(user_path_var, "(o)", &user_path);
    g_assert(user_path != NULL);

    user_proxy = g_dbus_proxy_new_for_bus_sync(G_BUS_TYPE_SYSTEM,
            G_DBUS_PROXY_FLAGS_NONE,
            NULL,
            "org.freedesktop.Accounts",
            user_path,
            "org.freedesktop.Accounts.User",
            NULL,
            &error);

    g_assert(user_proxy != NULL);
    if(error != NULL){
        g_debug("connect org.freedesktop.Accounts failed");
        g_clear_error(&error);
    }

    g_free(user_path);
    g_variant_unref(user_path_var);
}

JS_EXPORT_API
const gchar* lock_get_username()
{
    return username;
}

JS_EXPORT_API
gchar* lock_get_icon()
{
    g_assert(user_proxy != NULL);
    GVariant* user_icon_var = g_dbus_proxy_get_cached_property(user_proxy, "IconFile");
    g_assert(user_icon_var != NULL);

    gchar* user_icon = g_variant_dup_string(user_icon_var, NULL);

    if(!g_file_test(user_icon, G_FILE_TEST_EXISTS)){
        user_icon = g_strdup("nonexists");
    }

    if(g_access(user_icon, R_OK) != 0){
        user_icon = g_strdup("nonexists");
    }

    g_variant_unref(user_icon_var);

    return user_icon;
}

gchar* lock_get_realname()
{
    g_assert(user_proxy != NULL);
    GVariant* user_realname_var = g_dbus_proxy_get_cached_property(user_proxy, "RealName");
    g_assert(user_realname_var != NULL);

    gchar* user_realname = g_variant_dup_string(user_realname_var, NULL);
    g_assert(user_realname != NULL);

    g_variant_unref(user_realname_var);

    return user_realname;
}

gboolean lock_is_guest()
{
    gboolean is_guest = FALSE;

    if(g_str_has_prefix(username, "guest")){
        gchar * name = lock_get_realname();

        if(g_ascii_strncasecmp("Guest", name, 5) == 0){
            g_warning("realname is guest, cann't lock");
            is_guest = TRUE;
        }
        g_free(name);
    }

    return is_guest;
}

gboolean lock_is_running()
{
    gboolean run_flag = FALSE;

    gchar *user_lock_path = g_strdup_printf("%s%s", username, ".dlock.app.deepin");
    if(app_is_running(user_lock_path)){
        g_warning("another instance of dlock is running by current user...\n");
        run_flag = TRUE;
    }
    g_free(user_lock_path);

    return run_flag;
}

gchar* lock_get_background()
{
    g_assert(user_proxy != NULL);
    GVariant* user_background_var = g_dbus_proxy_get_cached_property(user_proxy, "BackgroundFile");
    g_assert(user_background_var != NULL);

    gchar* background_image  = g_variant_dup_string(user_background_var, NULL);

    if(!g_file_test(background_image, G_FILE_TEST_EXISTS)){
        background_image = g_strdup("/usr/share/backgrounds/default_background.jpg");
    }

    if(g_access(background_image, R_OK) != 0){
        background_image = g_strdup("/usr/share/backgrounds/default_background.jpg");
    }

    g_variant_unref(user_background_var);

    return background_image;
}

void lock_set_background(const gchar *path)
{
    ;
}

JS_EXPORT_API
void lock_draw_background(JSValueRef canvas, JSData* data)
{
    gchar* image_path = lock_get_background();
    gint height = gdk_screen_get_height(gdk_screen_get_default());
    gint width = gdk_screen_get_width(gdk_screen_get_default());

    if(!g_file_test(image_path, G_FILE_TEST_EXISTS) || g_access(image_path, R_OK) != 0){
        g_warning("background file not exists or can't read");

    }else{

        cairo_t* cr =  fetch_cairo_from_html_canvas(data->ctx, canvas);
        GdkPixbuf *image_pixbuf = gdk_pixbuf_new_from_file_at_scale(image_path, width, height, False, &error);

        if (error != NULL) {
            g_warning("get lockfile pixbuf failed");
            g_clear_error(&error);
            cairo_set_source_rgba(cr, 0.3, 0.3, 0.3, 0.5);
            cairo_paint(cr);

        } else {
            gdk_cairo_set_source_pixbuf(cr, image_pixbuf, 0, 0);
            cairo_paint(cr);
        }

        canvas_custom_draw_did(cr, NULL);
        g_object_unref(image_pixbuf);
    }
    g_free(image_path);
}

JS_EXPORT_API
void lock_switch_user()
{
    g_spawn_command_line_async("switchtogreeter", NULL);
}

JS_EXPORT_API
gchar * lock_get_date()
{
    return get_date_string();
}

JS_EXPORT_API
void lock_unlock_succeed ()
{
    if(g_file_test(lockpid_file, G_FILE_TEST_EXISTS)){
        g_remove(lockpid_file);
    }
    g_free(lockpid_file);

    g_object_unref(user_proxy);
    g_spawn_close_pid(pid);
    gtk_main_quit();
}


JS_EXPORT_API
gboolean lock_need_pwd ()
{
    return is_need_pwd (username);
}

/* return False if unlock succeed */
JS_EXPORT_API
gboolean lock_try_unlock (const gchar *password)
{
    gboolean succeed = FALSE;
    GVariant *lock_succeed = NULL;

    GDBusProxy *lock_proxy = g_dbus_proxy_new_for_bus_sync (G_BUS_TYPE_SYSTEM,
            G_DBUS_PROXY_FLAGS_NONE,
            NULL,
            "com.deepin.dde.lock",
            "/com/deepin/dde/lock",
            "com.deepin.dde.lock",
            NULL,
            &error);

    g_assert(lock_proxy != NULL);
    if (error != NULL) {
        g_warning("connect com.deepin.dde.lock failed");
        g_clear_error(&error);
     }

    lock_succeed  = g_dbus_proxy_call_sync(lock_proxy,
                    "UnlockCheck",
                    g_variant_new ("(ss)", username, password),
                    G_DBUS_CALL_FLAGS_NONE,
                    -1,
                    NULL,
                    &error);

    g_assert(lock_succeed != NULL);
    if(error != NULL){
        g_clear_error (&error);
    }

    g_variant_get(lock_succeed, "(b)", &succeed);

    if(succeed){
        js_post_message_simply("unlock", "{\"status\":\"%s\"}", "succeed");

    } else {
        js_post_message_simply("unlock", "{\"status\":\"%s\"}", _("Invalid Password"));
    }

    g_variant_unref(lock_succeed);
    g_object_unref(lock_proxy);

    return succeed;
}


gboolean prevent_exit(GtkWidget* w, GdkEvent* e)
{
    return TRUE;
}

void focus_out_cb(GtkWidget* w, GdkEvent*e, gpointer user_data)
{
    gdk_window_focus(gtk_widget_get_window(lock_container), 0);
}

static void sigterm_cb(int signum)
{
    kill(0, 9);
    if(g_file_test(lockpid_file, G_FILE_TEST_EXISTS)){
        g_remove(lockpid_file);
    }

    g_free(lockpid_file);
    g_object_unref(user_proxy);
    g_spawn_close_pid(pid);
    gtk_main_quit();
}

static void lock_report_pid()
{
    lockpid_file = g_strdup_printf("%s%s%s", "/home/", username, "/dlockpid");
    if(g_file_test(lockpid_file, G_FILE_TEST_EXISTS)){
        g_debug("remove old pid info before lock");
        g_remove(lockpid_file);
    }

    if(g_creat(lockpid_file, O_RDWR) == -1){
        g_warning("touch lockpid_file failed\n");
    }

    gchar *contents = g_strdup_printf("%d", getpid());
    g_file_set_contents(lockpid_file, contents, -1, NULL);

    g_free(contents);
}

JS_EXPORT_API
gboolean lock_detect_capslock()
{
    return is_capslock_on();
}

static void lock_show_cb (GtkWindow* lock_container, gpointer data)
{
#ifdef NDEBUG
    gs_grab_move_to_window (grab,
                            gtk_widget_get_window (GTK_WIDGET(lock_container)),
                            gtk_window_get_screen (lock_container),
                            FALSE);
#endif
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
    XEvent *ev = xevent;

    switch (ev->type)
    {
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

int main(int argc, char **argv)
{
    init_i18n();
    gtk_init(&argc, &argv);
    signal(SIGTERM, sigterm_cb);

    init_user();

    if(lock_is_running()){
        g_object_unref(user_proxy);
        exit(0);
    }

    if(lock_is_guest()){
        g_object_unref(user_proxy);
        exit(0);
    }

    lock_report_pid();

    lock_container = create_web_container(FALSE, TRUE);
    ensure_fullscreen(lock_container);
    gtk_window_set_decorated(GTK_WINDOW(lock_container), FALSE);
    gtk_window_set_skip_taskbar_hint (GTK_WINDOW (lock_container), TRUE);
#ifdef NDEBUG
    gtk_window_set_skip_pager_hint (GTK_WINDOW (lock_container), TRUE);
#endif
    gtk_window_fullscreen(GTK_WINDOW(lock_container));
#ifdef NDEBUG
    gtk_window_set_keep_above(GTK_WINDOW(lock_container), TRUE);
    gtk_widget_set_events (GTK_WIDGET (lock_container),
                           gtk_widget_get_events (GTK_WIDGET (lock_container))
                           | GDK_POINTER_MOTION_MASK
                           | GDK_BUTTON_PRESS_MASK
                           | GDK_BUTTON_RELEASE_MASK
                           | GDK_KEY_PRESS_MASK
                           | GDK_KEY_RELEASE_MASK
                           | GDK_EXPOSURE_MASK
                           | GDK_VISIBILITY_NOTIFY_MASK
                           | GDK_ENTER_NOTIFY_MASK
                           | GDK_LEAVE_NOTIFY_MASK);
#endif

    GtkWidget *webview = d_webview_new_with_uri(LOCK_HTML_PATH);
    gtk_container_add(GTK_CONTAINER(lock_container), GTK_WIDGET(webview));

    g_signal_connect(lock_container, "delete-event", G_CALLBACK(prevent_exit), NULL);
    g_signal_connect(lock_container, "show", G_CALLBACK (lock_show_cb), NULL);
    g_signal_connect(webview, "focus-out-event", G_CALLBACK(focus_out_cb), NULL);

    gtk_widget_realize(lock_container);

    GdkWindow *gdkwindow = gtk_widget_get_window(lock_container);
    GdkRGBA rgba = { 0, 0, 0, 0.0 };

    gdk_window_set_background_rgba(gdkwindow, &rgba);
    gdk_window_set_skip_taskbar_hint(gdkwindow, TRUE);
    gdk_window_set_cursor(gdkwindow, gdk_cursor_new(GDK_LEFT_PTR));

#ifdef NDEBUG
    gdk_window_set_override_redirect (gdkwindow, TRUE);
    select_popup_events ();
    gdk_window_add_filter (NULL, (GdkFilterFunc)xevent_filter, gdkwindow);

    grab = gs_grab_new ();
#endif
    gtk_widget_show_all(lock_container);

    /*gint height = gdk_screen_get_height(gdk_screen_get_default());*/
    /*gint width = gdk_screen_get_width(gdk_screen_get_default());*/
    /*gdk_window_move_resize (gdkwindow, 0, 0, width, height);*/

    gdk_window_focus(gtk_widget_get_window(lock_container), 0);
#ifdef NDEBUG
    gdk_window_stick(gdkwindow);
#endif

    init_camera(argc, argv);
    gtk_main();
    destroy_camera();

    return 0;
}
