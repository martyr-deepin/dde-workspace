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
#include <stdlib.h>
#include <signal.h>
#include <errno.h>
#include <string.h>
#include <sys/resource.h>

#include <gtk/gtk.h>
#include <gio/gdesktopappinfo.h>

#include "launcher.h"
#include "xdg_misc.h"
#include "dwebview.h"
#include "dentry/entry.h"
#include "X_misc.h"
#include "i18n.h"
#include "category.h"
#include "background.h"
#include "test.h"
#include "DBUS_launcher.h"
#include "session_register.h"
#include "display_info.h"

#define LAUNCHER_CONF "launcher/config.ini"
#define HIDDEN_APP_GROUP_NAME "HiddenApps"
#define APPS_INI "launcher/apps.ini"

int kill(pid_t, int);  // avoid warning

static gboolean is_debug = FALSE;
static gboolean is_replace = FALSE;
static gboolean is_hidden = FALSE;
static gboolean is_quit = FALSE;

static GOptionEntry entries[] = {
    {"debug", 'd', 0, G_OPTION_ARG_NONE, &is_debug, "output debug message", NULL},
    {"replace", 'r', 0, G_OPTION_ARG_NONE, &is_replace, "replace launcher", NULL},
    {"hidden", 'h', 0, G_OPTION_ARG_NONE, &is_hidden, "start and hide launcher", NULL},
    {"quit", 'q', 0, G_OPTION_ARG_NONE, &is_quit, "start and hide launcher", NULL},
};


static GKeyFile* launcher_config = NULL;
PRIVATE GtkWidget* container = NULL;
PRIVATE GtkWidget* webview = NULL;
PRIVATE gboolean is_js_already = FALSE;
PRIVATE gboolean is_launcher_shown = FALSE;
PRIVATE gboolean force_show = FALSE;
struct DisplayInfo launcher;


PRIVATE
void _do_im_commit(GtkIMContext *context G_GNUC_UNUSED, gchar* str)
{
    JSObjectRef json = json_create();
    json_append_string(json, "Content", str);
    js_post_message("im_commit", json);
}


PRIVATE
gboolean set_size()
{
#ifndef NDEBUG
    int width = 0, height = 0;
    gtk_window_get_size(GTK_WINDOW(container), &width, &height);
    g_debug("[%s] change window size from %dx%d to %dx%d", __func__, width, height, launcher.width, launcher.height);
#endif

    g_warning("[%s] %dx%d(%d, %d)", __func__, launcher.width, launcher.height, launcher.x, launcher.y);
    GdkGeometry geo = {0};
    geo.min_height = 0;
    geo.min_width = 0;

    gtk_window_set_geometry_hints(GTK_WINDOW(container), NULL, &geo, GDK_HINT_MIN_SIZE);
    gtk_widget_set_size_request(container, launcher.width, launcher.height);
    gtk_window_move(GTK_WINDOW(container), launcher.x, launcher.y);

    if (gtk_widget_get_realized(webview)) {
        GdkWindow* gdk = gtk_widget_get_window(webview);
        gdk_window_set_geometry_hints(gdk, &geo, GDK_HINT_MIN_SIZE);
        gdk_window_move_resize(gdk, 0, 0, launcher.width, launcher.height);
        gdk_window_flush(gdk);
    }

#ifndef NDEBUG
    gtk_window_get_size(GTK_WINDOW(container), &width, &height);
    g_debug("[%s] the new size is %dx%d", __func__,  width, height);
#endif
    return TRUE;
}


void size_allocate_handler(GtkWidget* widget G_GNUC_UNUSED,
                           GdkRectangle* alloc G_GNUC_UNUSED,
                           gpointer user_data G_GNUC_UNUSED)
{
    if (alloc->x != 0 || alloc->y != 0 ||
        alloc->width != launcher.width || alloc->height != launcher.height) {
        GdkGeometry geo = {0};
        geo.min_width = 0;
        geo.min_height = 0;

        GdkWindow* gdk = gtk_widget_get_window(widget);
        gdk_window_set_geometry_hints(gdk, &geo, GDK_HINT_MIN_SIZE);
        gdk_window_resize(gdk, launcher.width, launcher.height);
        gdk_window_flush(gdk);
    }
}


PRIVATE
void _on_realize(GtkWidget* container G_GNUC_UNUSED)
{
    g_debug("[%s] realize signal", __func__);
    set_size();
    g_debug("[%s] realize signal end", __func__);
}


JS_EXPORT_API
void launcher_force_show(gboolean force)
{
    force_show = force;
}


static
void activate_window(Display *dsp, GdkWindow *w)
{
    static Atom activeWindowAtom = 0;
    if (activeWindowAtom == 0) {
        activeWindowAtom = gdk_x11_get_xatom_by_name("_NET_ACTIVE_WINDOW");
    }
    XClientMessageEvent event;
    event.type = ClientMessage;
    event.window = GDK_WINDOW_XID(w);
    event.message_type = activeWindowAtom;
    event.format = 32;
    event.data.l[0] = 1; // 1 for application, 2 for pager, 0 for old spec
    event.data.l[1] = gdk_x11_get_server_time(w);
    XSendEvent(dsp, GDK_ROOT_WINDOW(), False,
               StructureNotifyMask, (XEvent*)&event);
    XFlush(dsp);
}


DBUS_EXPORT_API
void launcher_show()
{
    gtk_window_deiconify(GTK_WINDOW(container)); /* ensure launcher is not minimized */
    gtk_widget_show_all(container);
    is_launcher_shown = TRUE;

    // activate launcher manually
    activate_window(GDK_DISPLAY_XDISPLAY(gdk_display_get_default()), gtk_widget_get_window(container));

    GError* err = NULL;
    GDBusConnection* conn = g_bus_get_sync(G_BUS_TYPE_SESSION, NULL, &err);
    if (err != NULL) {
        g_warning("%s", err->message);
        g_error_free(err);
        return;
    }
    g_dbus_connection_emit_signal(conn,
                                  NULL,
                                  "/com/deepin/dde/launcher",
                                  "com.deepin.dde.launcher",
                                  "Shown",
                                  NULL,
                                  &err
                                  );
    g_object_unref(conn);
    if (err != NULL) {
        g_warning("launcher emit Shown signal failed: %s", err->message);
        g_error_free(err);
    }
    if (is_js_already) {
        js_post_signal("launcher_shown");
    }
}


DBUS_EXPORT_API
void launcher_hide()
{
    if (force_show)
        return;
    is_launcher_shown = FALSE;
    gtk_widget_hide(container);
    js_post_signal("exit_launcher");
    GError* err = NULL;
    GDBusConnection* conn = g_bus_get_sync(G_BUS_TYPE_SESSION, NULL, &err);
    if (err != NULL) {
        g_warning("%s", err->message);
        g_error_free(err);
        return;
    }
    g_dbus_connection_emit_signal(conn,
                                  NULL,
                                  "/com/deepin/dde/launcher",
                                  "com.deepin.dde.launcher",
                                  "Closed",
                                  NULL,
                                  &err
                                  );
    g_object_unref(conn);
    if (err != NULL) {
        g_warning("launcher emit Closed signal failed: %s", err->message);
        g_error_free(err);
    }
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
JS_EXPORT_API
void launcher_quit()
{
    g_debug("#%d# quit", getpid());
    g_key_file_free(launcher_config);
    gtk_main_quit();
}


#ifndef NDEBUG
void empty()
{ }
#endif


JS_EXPORT_API
void launcher_exit_gui()
{
    if (is_quit) {
        launcher_quit();
    } else {
        launcher_hide();
    }
}


JS_EXPORT_API
void launcher_notify_workarea_size()
{
    // update_primary_info(&launcher);
    JSObjectRef workarea_info = json_create();
    json_append_number(workarea_info, "x", launcher.x);
    json_append_number(workarea_info, "y", launcher.y);
    json_append_number(workarea_info, "width", launcher.width);
    json_append_number(workarea_info, "height", launcher.height);
    js_post_message("workarea_changed", workarea_info);
}


JS_EXPORT_API
GFile* launcher_get_desktop_entry()
{
    return g_file_new_for_path(DESKTOP_DIR());
}


void primary_changed_handler(GDBusConnection* conn G_GNUC_UNUSED,
                             const gchar* sender_name G_GNUC_UNUSED,
                             const gchar* object_path G_GNUC_UNUSED,
                             const gchar* interface_name G_GNUC_UNUSED,
                             const gchar* signal_name G_GNUC_UNUSED,
                             GVariant* parameters G_GNUC_UNUSED,
                             gpointer data G_GNUC_UNUSED
                             )
{
    struct DisplayInfo* rect = (struct DisplayInfo*)data;
    g_variant_get(parameters, "((nnqq))", &rect->x, &rect->y, &rect->width, &rect->height);
    set_size();
}


JS_EXPORT_API
void launcher_webview_ok()
{
    dde_session_register();
    is_js_already = TRUE;
    listen_primary_changed_signal(primary_changed_handler, &launcher, NULL);
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
    return !is_launcher_shown;
}


static
void restart_launcher()
{
    g_spawn_command_line_async("dde-launcher -rh", NULL);
}


gboolean _launcher_size_monitor(gpointer user_data G_GNUC_UNUSED)
{
    struct rusage usg;
    getrusage(RUSAGE_SELF, &usg);
    if (usg.ru_maxrss > RES_IN_MB(180) && can_be_restart()) {
        restart_launcher();
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
    g_message("[%s] %s", __func__, content);
    pid_t pid = atoi(content);
    g_free(content);
    return pid;
}


void signal_handler(int signum)
{
    switch (signum)
    {
    case SIGKILL:
    case SIGTERM:
        launcher_quit();
        break;
    case SIGUSR1:
        launcher_show();
        break;
    }
}

void move_launcher(GtkWidget* widget, gpointer data G_GNUC_UNUSED)
{
    gtk_window_move(GTK_WINDOW(widget), launcher.x, launcher.y);
}


void notify_icon_theme_changed(GtkIconTheme* theme G_GNUC_UNUSED, gpointer data G_GNUC_UNUSED)
{
    js_post_signal("icon_theme_changed");
}


int main(int argc, char* argv[])
{
    gtk_init(&argc, &argv);
    g_log_set_default_handler((GLogFunc)log_to_file, "dde-launcher");

    GOptionContext* ctx = g_option_context_new("launcher");
    g_option_context_add_main_entries(ctx, entries, NULL);
    g_option_context_add_group(ctx, gtk_get_option_group(TRUE));
    GError* error = NULL;
    if (!g_option_context_parse(ctx, &argc, &argv, &error)) {
        g_print("option parsing failed: %s\n", error->message);
        g_error_free(error);
        return 1;
    }
    g_option_context_free(ctx);

    g_debug("is_debug:%d", is_debug);
    g_debug("is_replace:%d", is_replace);
    g_debug("is_hidden:%d", is_hidden);
    g_debug("is_quit:%d", is_quit);

    if (is_replace) {
        pid_t pid = read_pid();

#ifndef NDEBUG
        g_message("kill previous launcher");
        g_message("[%s] launcher's pid: #%d#", __func__, pid);
#endif

        if (pid != -1) {
            kill(pid, SIGKILL);
            sleep(1);
        }
    }

    if (is_application_running(LAUNCHER_ID_NAME)) {
        g_message("another instance of launcher is running...");

        if (!is_hidden) {
            dbus_launcher_toggle();
            // pid_t pid = read_pid();
            // kill(pid, SIGUSR1);
        }
        return 0;
    }

    g_message("gtk init done");

    if (is_debug) {
        g_setenv("G_MESSAGES_DEBUG", "all", FALSE);
    }
#ifdef NDEBUG
        g_setenv("G_MESSAGES_DEBUG", "all", FALSE);
#endif

    singleton(LAUNCHER_ID_NAME);
    g_message("singleton done");
    check_version();
    g_message("check version done");

    signal(SIGUSR1, signal_handler);
    signal(SIGKILL, signal_handler);
    signal(SIGTERM, signal_handler);

#ifndef NDEBUG
    g_debug("No. #%d#", getpid());
#endif
    save_pid();
    g_message("save pid done");

    init_i18n();
    g_message("init i18n done");

    g_timeout_add_seconds(3, _launcher_size_monitor, NULL);

    container = create_web_container(FALSE, TRUE);
    gtk_window_set_decorated(GTK_WINDOW(container), FALSE);
    gtk_window_set_wmclass(GTK_WINDOW(container), "dde-launcher", "DDELauncher");
#ifdef NDEBUG
    gtk_window_set_title(GTK_WINDOW(container), "launcher");
#endif
    set_desktop_env_name("Deepin");
    GtkIconTheme* theme = gtk_icon_theme_get_default();
    g_signal_connect(theme, "changed", G_CALLBACK(notify_icon_theme_changed), NULL);

    webview = d_webview_new_with_uri(GET_HTML_PATH("launcher"));

    gtk_container_add(GTK_CONTAINER(container), GTK_WIDGET(webview));

    update_primary_info(&launcher);
    g_signal_connect(container, "realize", G_CALLBACK(_on_realize), NULL);
    g_signal_connect (container, "destroy", G_CALLBACK(gtk_main_quit), NULL);
    g_signal_connect(container, "map", G_CALLBACK(move_launcher), NULL);
#ifndef NDEBUG
    g_signal_connect(container, "delete-event", G_CALLBACK(empty), NULL);
#endif

    gtk_widget_realize(container);
    gtk_widget_realize(webview);

    g_signal_connect(container, "size-allocate", G_CALLBACK(size_allocate_handler), NULL);
    g_signal_connect(webview, "size-allocate", G_CALLBACK(size_allocate_handler), NULL);

    setup_background(container, webview, "_DDE_BACKGROUND_PIXMAP_BLURRED");

    GdkWindow* gdkwindow = gtk_widget_get_window(container);

    gdk_window_set_skip_taskbar_hint(gdkwindow, TRUE);
    gdk_window_set_skip_pager_hint(gdkwindow, TRUE);

    GtkIMContext* im_context = gtk_im_multicontext_new();
    gtk_im_context_set_client_window(im_context, gdkwindow);
    GdkRectangle area = {0, 60, 0, 0};
    area.x = launcher.width * .5 - 150;
    gtk_im_context_set_cursor_location(im_context, &area);
    gtk_im_context_focus_in(im_context);
    g_signal_connect(im_context, "commit", G_CALLBACK(_do_im_commit), NULL);
    g_message("set im done");

    setup_launcher_dbus_service();
    g_message("start launcher dbus service done");

#ifndef NDEBUG
    // monitor_resource_file("launcher", webview);
    g_debug("xid: 0x%lx", gdk_x11_window_get_xid(gtk_widget_get_window(container)));
#endif

    gtk_widget_show_all(webview);
    if (!is_hidden) {
        launcher_show();
        g_message("show launcher done");
    }
    gtk_main();
    return 0;
}

