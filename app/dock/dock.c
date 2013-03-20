/**
 * Copyright (c) 2011 ~ 2012 Deepin, Inc.
 *               2011 ~ 2012 snyh
 *
 * Author:      snyh <snyh@snyh.org>
 * Maintainer:  snyh <snyh@snyh.org>
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
#include <dwebview.h>
#include "X_misc.h"
#include "xdg_misc.h"
#include "utils.h"
#include "tray.h"
#include "tasklist.h"
#include "i18n.h"
#include "dock_config.h"
#include "launcher.h"
#include "region.h"
#include "dbus.h"
#include "dock_hide.h"
#include <cairo.h>

void dock_change_workarea_height(double height);
int _dock_height = 60;
int screen_width = 0;
int screen_height = 0;
GdkWindow* get_dock_guard_window();

gboolean leave_notify(GtkWidget* w, GdkEventCrossing* e, gpointer u)
{
    if (e->detail == GDK_NOTIFY_NONLINEAR_VIRTUAL) {
        if (GD.config.hide_mode == ALWAYS_HIDE_MODE)
            dock_delay_hide(500);
        else if (GD.config.hide_mode == INTELLIGENT_HIDE_MODE)
            dock_update_hide_mode();
        else if (GD.config.hide_mode == AUTO_HIDE_MODE && dock_has_maximize_client())
            dock_hide_real_now();
        js_post_message_simply("leave-notify", NULL);
    }
    return FALSE;
}
gboolean enter_notify(GtkWidget* w, GdkEvent* e, gpointer u)
{
    if (GD.config.hide_mode == AUTO_HIDE_MODE) {
        dock_show_real_now();
    } else if (GD.config.hide_mode != NO_HIDE_MODE) {
        dock_delay_show(300);
    }
    return FALSE;
}

GtkWidget* container = NULL;
GdkWindow* DOCK_GDK_WINDOW() { return gtk_widget_get_window(container);}
Window get_dock_window()
{
    g_assert(container != NULL);
    return GDK_WINDOW_XID(DOCK_GDK_WINDOW());
}
void update_dock_size(GdkScreen* screen, GtkWidget* webview)
{
    screen_width = gdk_screen_get_width(screen);
    screen_height = gdk_screen_get_height(screen);

    GdkGeometry geo = {0};
    geo.min_width = screen_width;
    geo.min_height = screen_height;

    gdk_window_set_geometry_hints(gtk_widget_get_window(container), &geo, GDK_HINT_MIN_SIZE);
    gdk_window_move_resize(gtk_widget_get_window(container), 0, 0, screen_width, screen_height);

    dock_change_workarea_height(_dock_height);

    init_region(DOCK_GDK_WINDOW(), 0, screen_height - _dock_height, screen_width, _dock_height);

    webkit_web_view_reload_bypass_cache(WEBKIT_WEB_VIEW(webview));
    tray_icon_do_screen_size_change();
}

//TODO: REMOVE
gboolean remove_me_run_tray_icon()
{
    GAppInfo* app = g_app_info_create_from_commandline("python /usr/share/deepin-system-tray/src/trayicon.py", "DeepinTrayIcon", G_APP_INFO_CREATE_NONE, NULL);
    g_app_info_launch(app, NULL, NULL, NULL);
    g_object_unref(app);
    return FALSE;
}

int main(int argc, char* argv[])
{
    //remove  option -f 
    parse_cmd_line (&argc, &argv);
    init_i18n();
    gtk_init(&argc, &argv);


    g_log_set_default_handler((GLogFunc)log_to_file, "dock");
    set_desktop_env_name("Deepin");
    set_default_theme("Deepin");

    container = create_web_container(FALSE, TRUE);
    gtk_window_set_decorated(GTK_WINDOW(container), FALSE);

    gdk_error_trap_push(); //we need remove this, but now it can ignore all X error so we would'nt crash.

    GtkWidget *webview = d_webview_new_with_uri(GET_HTML_PATH("dock"));

    g_signal_connect_after(webview, "draw", G_CALLBACK(draw_tray_icons), NULL);

    gtk_container_add(GTK_CONTAINER(container), GTK_WIDGET(webview));


    g_signal_connect(container , "destroy", G_CALLBACK (gtk_main_quit), NULL);
    g_signal_connect(webview, "draw", G_CALLBACK(erase_background), NULL);
    g_signal_connect(container, "enter-notify-event", G_CALLBACK(enter_notify), NULL);
    g_signal_connect(container, "leave-notify-event", G_CALLBACK(leave_notify), NULL);


    GdkScreen* screen = gdk_screen_get_default();
    g_signal_connect(screen, "size-changed", G_CALLBACK(update_dock_size), webview);

    gtk_widget_realize(container);
    gtk_widget_realize(webview);
    gtk_window_move(GTK_WINDOW(container), 0, 0);
    gtk_widget_show_all(container);
    update_dock_size(screen, webview);

    gdk_window_set_accept_focus(gtk_widget_get_window(webview), FALSE);
    set_wmspec_dock_hint(DOCK_GDK_WINDOW());

    monitor_resource_file("dock", webview);
    /*gdk_window_set_debug_updates(TRUE);*/

    GdkRGBA rgba = { 0, 0, 0, 0.0 };
    gdk_window_set_background_rgba(DOCK_GDK_WINDOW(), &rgba);

    dock_setup_dbus_service();
    gtk_main();
    return 0;
}

void update_dock_color()
{
    /*if (GD.is_webview_loaded)*/
        js_post_message_simply("dock_color_changed", NULL);
}

void update_dock_size_mode()
{
    if (GD.config.mini_mode) {
        js_post_message_simply("in_mini_mode", NULL);
    } else {
        js_post_message_simply("in_normal_mode", NULL);
    }
}

JS_EXPORT_API
void dock_emit_webview_ok()
{
    static gboolean inited = FALSE;
    if (!inited) {
        inited = TRUE;
        init_config();
        init_launchers();
        init_task_list();
        tray_init(container);
        update_dock_size_mode();
        init_dock_guard_window();
        g_timeout_add(1000, remove_me_run_tray_icon, NULL);
    } else {
        update_dock_apps();
        update_task_list();
        update_dock_size_mode();
        tray_icon_do_screen_size_change();
    }
    GD.is_webview_loaded = TRUE;
    if (GD.config.hide_mode == ALWAYS_HIDE_MODE) {
        dock_hide_now();
    } else {
    }
}

void _change_workarea_height(int height)
{
    if (GD.is_webview_loaded && GD.config.hide_mode == NO_HIDE_MODE ) {
        set_struct_partial(DOCK_GDK_WINDOW(), ORIENTATION_BOTTOM, height, 0, screen_width);
    } else {
        set_struct_partial(DOCK_GDK_WINDOW(), ORIENTATION_BOTTOM, 0, 0, screen_width);
    }
}

JS_EXPORT_API
void dock_change_workarea_height(double height)
{
    if ((int)height == _dock_height)
        return;

    if (height < 30)
        _dock_height = 30;
    else
        _dock_height = height;
    _change_workarea_height(height);
    init_region(DOCK_GDK_WINDOW(), 0, screen_height - _dock_height, screen_width, _dock_height);
}

JS_EXPORT_API
void dock_toggle_launcher(gboolean show)
{
    if (show) {
        dcore_run_command("launcher");
    } else {
        close_launcher_window();
    }
}
