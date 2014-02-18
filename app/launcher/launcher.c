/**
 * Copyright (c) 2011 ~ 2013 Deepin, Inc.
 *               2011 ~ 2012 snyh
 *               2013 ~ 2013 Liqiang Lee
 *
 * Author:      snyh <snyh@snyh.org>
 * Maintainer:  snyh <snyh@snyh.org>
 *              Liqiang Lee <liliqiang@linuxdeepin.com>
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

#include <fcntl.h>
#include <sys/stat.h>
#include <unistd.h>
#include <signal.h>
#include <errno.h>
#include <string.h>
#include <sys/resource.h>

#include <gtk/gtk.h>
#include <gio/gdesktopappinfo.h>
#include <dbus/dbus.h>
#include <dbus/dbus-glib.h>

#include "launcher.h"
#include "xdg_misc.h"
#include "dwebview.h"
#include "dentry/entry.h"
#include "X_misc.h"
#include "i18n.h"
#include "category.h"
#include "background.h"
#include "uninstall.h"
#include "test.h"
#include "DBUS_launcher.h"

#define LAUNCHER_CONF "launcher/config.ini"
#define HIDDEN_APP_GROUP_NAME "HiddenApps"
#define APPS_INI "launcher/apps.ini"

static GKeyFile* launcher_config = NULL;
PRIVATE GtkWidget* container = NULL;
PRIVATE GtkWidget* webview = NULL;
PRIVATE GSettings* background_gsettings = NULL;
PRIVATE gboolean is_js_already = FALSE;
PRIVATE gboolean is_launcher_shown = FALSE;
PRIVATE gboolean force_show = FALSE;
GdkRectangle launcher;
// TODO:: use curren_screen to reduce resize.
struct {
    GdkScreen* screen;
    int index;
} current_screen = {0};

#ifndef NDEBUG
PRIVATE gboolean is_daemonize = FALSE;
PRIVATE gboolean not_exit = FALSE;
#endif


PRIVATE
void _do_im_commit(GtkIMContext *context, gchar* str)
{
    NOUSED(context);
    JSObjectRef json = json_create();
    json_append_string(json, "Content", str);
    js_post_message("im_commit", json);
}


void update_display_info()
{
    if (current_screen.screen != NULL) {
        current_screen.screen = NULL;
    }

    GdkDisplay* display = gdk_display_get_default();
    GdkDeviceManager* device_manager = gdk_display_get_device_manager(display);
    GdkDevice* pointer = gdk_device_manager_get_client_pointer(device_manager);
    gint x = 0, y = 0;
    gdk_device_get_position(pointer, &current_screen.screen, &x, &y);
    if (current_screen.screen == NULL) {
        return;
    }
    current_screen.index = gdk_screen_get_monitor_at_point(current_screen.screen, x, y);
    g_debug("monitor:%d", current_screen.index);
    gdk_screen_get_monitor_geometry(current_screen.screen, current_screen.index, &launcher);
    g_debug("[%s] new geometry: %dx%d+%d+%d", __func__, launcher.width, launcher.height, launcher.x, launcher.y);
}


PRIVATE
void set_size()
{
#ifndef NDEBUG
    int width = 0, height = 0;
    gtk_window_get_size(GTK_WINDOW(container), &width, &height);
    g_debug("[%s] change window size from %dx%d to %dx%d", __func__, width, height, launcher.width, launcher.height);
#endif

    GdkGeometry geo = {0};
    geo.min_height = 0;
    geo.min_width = 0;
    gtk_window_set_geometry_hints(GTK_WINDOW(container), NULL, &geo, GDK_HINT_MIN_SIZE);
    gtk_widget_set_size_request(container, launcher.width, launcher.height);

    if (gtk_widget_get_realized(webview)) {
        GdkWindow* gdk = gtk_widget_get_window(webview);
        gdk_window_set_geometry_hints(gdk, &geo, GDK_HINT_MIN_SIZE);
        gdk_window_resize(gdk, launcher.width, launcher.height);
        gdk_window_flush(gdk);
    }

#ifndef NDEBUG
    gtk_window_get_size(GTK_WINDOW(container), &width, &height);
    g_debug("[%s] the new size is %dx%d", __func__,  width, height);
#endif
}


PRIVATE
void _update_size(GdkScreen* screen G_GNUC_UNUSED,
                  gpointer userdata G_GNUC_UNUSED)
{
    update_display_info();
    set_size();
}


void resize(GtkWidget* widget G_GNUC_UNUSED,
            GdkRectangle* allocation G_GNUC_UNUSED,
            gpointer user_data G_GNUC_UNUSED)
{
    g_debug("[%s] size-allocate signal", __func__);
    _update_size(NULL, NULL);
    g_debug("[%s] size-allocate signal end", __func__);
}



PRIVATE
G_GNUC_UNUSED
GdkFilterReturn launcher_ensure_fullscreen(GdkXEvent *xevent,
                                           GdkEvent *event G_GNUC_UNUSED,
                                           gpointer data G_GNUC_UNUSED)
{
    XEvent* xev = xevent;
    if (xev->type == ConfigureNotify) {
        _update_size(current_screen.screen, NULL);
    }
    return GDK_FILTER_CONTINUE;
}


PRIVATE
void _on_realize(GtkWidget* container)
{
    g_debug("[%s] realize signal", __func__);
    _update_size(current_screen.screen, container);
    if (is_js_already)
        background_changed(background_gsettings, CURRENT_PCITURE, NULL);
    g_debug("[%s] realize signal end", __func__);
}


JS_EXPORT_API
void launcher_force_show(gboolean force)
{
    force_show = force;
}


DBUS_EXPORT_API
void launcher_show()
{
    gtk_widget_show_all(container);
    is_launcher_shown = TRUE;
}


DBUS_EXPORT_API
void launcher_hide()
{
    if (force_show)
        return;
    is_launcher_shown = FALSE;
    gtk_widget_hide(container);
    js_post_signal("exit_launcher");
}


DBUS_EXPORT_API
void launcher_toggle()
{
    if (is_launcher_shown) {
        launcher_hide();
    } else {
        launcher_show();
    }
}


DBUS_EXPORT_API
void launcher_quit()
{
    g_debug("#%d# quit", getpid());
    g_key_file_free(launcher_config);
    g_object_unref(background_gsettings);
    gtk_main_quit();
}


#ifndef NDEBUG
void empty()
{ }
#endif


JS_EXPORT_API
void launcher_exit_gui()
{
#ifndef NDEBUG
    if (is_daemonize || not_exit) {
#endif

        launcher_hide();

#ifndef NDEBUG
    } else {
        launcher_quit();
    }
#endif
}


JS_EXPORT_API
void launcher_notify_workarea_size()
{
    // update_display_info(&launcher);
    JSObjectRef workarea_info = json_create();
    json_append_number(workarea_info, "x", 0);
    json_append_number(workarea_info, "y", 0);
    json_append_number(workarea_info, "width", launcher.width);
    json_append_number(workarea_info, "height", launcher.height);
    js_post_message("workarea_changed", workarea_info);
}


JS_EXPORT_API
GFile* launcher_get_desktop_entry()
{
    return g_file_new_for_path(DESKTOP_DIR());
}


JS_EXPORT_API
void launcher_webview_ok()
{
    background_changed(background_gsettings, CURRENT_PCITURE, NULL);
    is_js_already = TRUE;
}


PRIVATE
void daemonize()
{
    g_debug("daemonize");

#ifdef NDEBUG
    close_std_stream();
#endif

    pid_t pid = 0;
    if ((pid = fork()) == -1) {
        g_warning("fork error");
        exit(0);
    } else if (pid != 0){
        exit(0);
    }

    setsid();

    if ((pid = fork()) == -1) {
        g_warning("fork error");
        exit(0);
    } else if (pid != 0){
        exit(0);
    }
}


JS_EXPORT_API
void launcher_clear()
{
    webkit_web_view_reload_bypass_cache((WebKitWebView*)webview);
}


void check_version()
{
    if (launcher_config == NULL)
        launcher_config = load_app_config(LAUNCHER_CONF);

    GError* err = NULL;
    gchar* version = g_key_file_get_string(launcher_config, "main", "version", &err);
    if (err != NULL) {
        g_warning("[%s] read version failed from config file: %s", __func__, err->message);
        g_error_free(err);
        g_key_file_set_string(launcher_config, "main", "version", LAUNCHER_VERSION);
        save_app_config(launcher_config, LAUNCHER_CONF);
    }

    if (g_strcmp0(LAUNCHER_VERSION, version) != 0) {
        g_key_file_set_string(launcher_config, "main", "version", LAUNCHER_VERSION);
        save_app_config(launcher_config, LAUNCHER_CONF);

        int noused G_GNUC_UNUSED = system("sed -i 's/__Config__/"HIDDEN_APP_GROUP_NAME"/g' $HOME/.config/"APPS_INI);
    }

    if (version != NULL)
        g_free(version);
}


static
gboolean can_be_restart()
{
    return !is_launcher_shown && !is_launcher_uninstalling();
}


gboolean _launcher_size_monitor(gpointer user_data)
{
    NOUSED(user_data);
    struct rusage usg;
    getrusage(RUSAGE_SELF, &usg);
    if (usg.ru_maxrss > RES_IN_MB(180) && can_be_restart()) {
        g_spawn_command_line_async("launcher -r", NULL);
        return FALSE;
    }

    return TRUE;
}


gboolean save_pid()
{
    char* path = g_build_filename(g_get_user_config_dir(), "launcher", "pid", NULL);
    FILE* f = fopen(path, "w");
    g_free(path);

    if (f == NULL) {
        g_warning("[%s] save pid error: %s", __func__, strerror(errno));
        return FALSE;
    }

    fprintf(f, "%d", getpid());
    fflush(f);

    fclose(f);
    return TRUE;
}


pid_t read_pid()
{
    char* path = g_build_filename(g_get_user_config_dir(), "launcher", "pid", NULL);
    gsize length = 0;
    GError* err = NULL;
    char* content = NULL;
    g_file_get_contents(path, &content, &length, &err);
    g_free(path);
    if (err != NULL) {
        g_warning("[%s] read pid failed: %s", __func__, err->message);
        g_error_free(err);
        return -1;
    }
    g_warning("[%s] %s", __func__, content);
    pid_t pid = atoi(content);
    g_free(content);
    return pid;
}


void exit_signal_handler(int signum)
{
    switch (signum)
    {
    case SIGKILL:
    case SIGTERM:
        launcher_quit();
    }
}


int main(int argc, char* argv[])
{
    gboolean not_shows_launcher = FALSE;

    if (argc == 2 && 0 == g_strcmp0("-d", argv[1]))
        g_setenv("G_MESSAGES_DEBUG", "all", FALSE);

#ifndef NDEBUG
    if (argc == 2 && 0 == g_strcmp0("-D", argv[1]))
        is_daemonize = TRUE;

    if (argc == 2 && 0 == g_strcmp0("-f", argv[1])) {
        not_shows_launcher = TRUE;
        not_exit = TRUE;
    }
#endif

    if (argc == 2 && 0 == g_strcmp0("-r", argv[1])) {
        pid_t pid = read_pid();
#ifndef NDEBUG
        g_warning("kill previous launcher");
        g_warning("[%s] launcher's pid: #%d#", __func__, pid);
#endif
        int kill(pid_t, int);  // avoid warning
        if (pid != -1)
            kill(pid, SIGKILL);
        not_shows_launcher = TRUE;
#ifndef NDEBUG
        is_daemonize = TRUE;
#endif
    }

    if (argc == 2 && 0 == g_strcmp0("-H", argv[1])) {
        if (is_application_running(LAUNCHER_ID_NAME)) {
            g_warning(_("another instance of launcher is running...\n"));
            return 0;
        }

        not_shows_launcher = TRUE;
#ifndef NDEBUG
        is_daemonize = TRUE;
#endif
    }

#ifndef NDEBUG
    if (argc == 2 && 0 == g_strcmp0("-l", argv[1])) {
        if (fork() == 0) {
            // child process
            int res G_GNUC_UNUSED = system("killall launcher-daemon");
            res = execl(DATA_DIR"/../build/launcher-daemon", DATA_DIR"/../build/launcher-daemon", NULL);
        } else {
            sleep(1);
        }
    }
#endif

    if (is_application_running(LAUNCHER_ID_NAME)) {
        g_warning(_("another instance of launcher is running...\n"));

        if (!not_shows_launcher) {
            dbus_launcher_toggle();
            return 0;
        }
    }

#ifndef NDEBUG
    if (is_daemonize)
#endif
        daemonize();

    singleton(LAUNCHER_ID_NAME);
    check_version();

    signal(SIGKILL, exit_signal_handler);
    signal(SIGTERM, exit_signal_handler);

    pid_t p G_GNUC_UNUSED = getpid();
#ifndef NDEBUG
    g_debug("No. #%d#", p);
#endif
    save_pid();

    g_timeout_add_seconds(3, _launcher_size_monitor, NULL);

    init_i18n();
    gtk_init(&argc, &argv);
    container = create_web_container(FALSE, TRUE);
    gtk_window_set_decorated(GTK_WINDOW(container), FALSE);
    gtk_window_set_wmclass(GTK_WINDOW(container), "dde-launcher", "DDELauncher");

#ifdef NDEBUG
    g_setenv("G_MESSAGES_DEBUG", "all", FALSE);
    g_log_set_default_handler((GLogFunc)log_to_file, "launcher");
#endif
    set_default_theme("Deepin");
    set_desktop_env_name("Deepin");

    webview = d_webview_new_with_uri(GET_HTML_PATH("launcher"));

    gtk_container_add(GTK_CONTAINER(container), GTK_WIDGET(webview));

    g_signal_connect(container, "realize", G_CALLBACK(_on_realize), NULL);
    g_signal_connect (container, "destroy", G_CALLBACK(gtk_main_quit), NULL);
    g_signal_connect(container, "size-allocate", G_CALLBACK(resize), NULL);
#ifndef NDEBUG
    g_signal_connect(container, "delete-event", G_CALLBACK(empty), NULL);
#endif
    background_gsettings = get_background_gsettings();
    g_signal_connect(background_gsettings, "changed::"CURRENT_PCITURE,
                     G_CALLBACK(background_changed), NULL);

    gtk_widget_realize(container);
    gtk_widget_realize(webview);

    GdkWindow* gdkwindow = gtk_widget_get_window(container);
    gdk_window_add_filter(gdkwindow, launcher_ensure_fullscreen, NULL);
    GdkRGBA rgba = {0, 0, 0, 0.0 };
    gdk_window_set_background_rgba(gdkwindow, &rgba);
    set_background(gtk_widget_get_window(webview), background_gsettings,
                            launcher.width, launcher.height);

    gdk_window_set_skip_taskbar_hint(gdkwindow, TRUE);
    gdk_window_set_skip_pager_hint(gdkwindow, TRUE);

    GtkIMContext* im_context = gtk_im_multicontext_new();
    gtk_im_context_set_client_window(im_context, gdkwindow);
    GdkRectangle area = {0, 60, 0, 0};
    area.x = launcher.width * .5 - 150;
    gtk_im_context_set_cursor_location(im_context, &area);
    gtk_im_context_focus_in(im_context);
    g_signal_connect(im_context, "commit", G_CALLBACK(_do_im_commit), NULL);

    setup_launcher_dbus_service();

#ifndef NDEBUG
    // monitor_resource_file("launcher", webview);
    g_debug("xid: 0x%lx", gdk_x11_window_get_xid(gtk_widget_get_window(container)));
#endif

    gtk_widget_show_all(webview);
    if (!not_shows_launcher) {
        launcher_show();
    }
    gtk_main();
    return 0;
}

