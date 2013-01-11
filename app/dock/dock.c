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
#include <cairo.h>

#define DOCK_HEIGHT (60)
int _screen_width = 0;
int _screen_height = 0;

gboolean leave_notify(GtkWidget* w, GdkEvent* e, gpointer u)
{
    js_post_message_simply("leave-notify", NULL);
    return FALSE;
}

GtkWidget* container = NULL;
void update_dock_size(GdkScreen* screen, GtkWidget* webview)
{
    _screen_width = gdk_screen_get_width(screen);
    _screen_height = gdk_screen_get_height(screen);
    gtk_window_move(GTK_WINDOW(container), 0, 0);
    gtk_window_resize(GTK_WINDOW(container), _screen_width, _screen_height);

    gdk_window_move_resize(gtk_widget_get_window(webview), 0 ,0, _screen_width, _screen_height);
    /*gtk_widget_set_size_request(webview, s_width, s_height);*/

    set_struct_partial(gtk_widget_get_window(container),
            ORIENTATION_BOTTOM, DOCK_HEIGHT, 0, _screen_width
            );

    init_region(gtk_widget_get_window(container), 0, _screen_height - 60, _screen_width, 60);

    webkit_web_view_reload_bypass_cache(WEBKIT_WEB_VIEW(webview));
}

int main(int argc, char* argv[])
{
    init_i18n();
    gtk_init(&argc, &argv);

    g_log_set_default_handler((GLogFunc)log_to_file, "dock");
    set_desktop_env_name("GNOME");
    set_default_theme("GoodIcons");

    container = create_web_container(FALSE, TRUE);
    gtk_window_set_decorated(GTK_WINDOW(container), FALSE);

    gdk_error_trap_push(); //we need remove this, but now it can ignore all X error so we would'nt crash.

    GtkWidget *webview = d_webview_new_with_uri(GET_HTML_PATH("dock"));

    g_signal_connect_after(webview, "draw", G_CALLBACK(draw_tray_icons), NULL);

    gtk_container_add(GTK_CONTAINER(container), GTK_WIDGET(webview));


    g_signal_connect(container , "destroy", G_CALLBACK (gtk_main_quit), NULL);
    g_signal_connect(webview, "draw", G_CALLBACK(erase_background), NULL);
    g_signal_connect(container, "leave-notify-event", G_CALLBACK(leave_notify), NULL);


    GdkScreen* screen = gdk_screen_get_default();
    g_signal_connect(screen, "size-changed", G_CALLBACK(update_dock_size), webview);

    gtk_widget_realize(container);
    gtk_widget_realize(webview);
    gtk_window_move(GTK_WINDOW(container), 0, 0);
    gtk_widget_show_all(container);
    update_dock_size(screen, webview);

    gdk_window_set_accept_focus(gtk_widget_get_window(webview), FALSE);
    set_wmspec_dock_hint(gtk_widget_get_window(container));

    monitor_resource_file("dock", webview);
    /*gdk_window_set_debug_updates(TRUE);*/


    dock_setup_dbus_service ();
    gtk_main();
    return 0;
}

void update_dock_color()
{
    /*if (GD.is_webview_loaded)*/
        js_post_message_simply("dock_color_changed", NULL);
}

void update_dock_show()
{
    GdkWindow* w = gtk_widget_get_window(container);
    if (GD.config.show) {
        set_struct_partial(w, ORIENTATION_BOTTOM, DOCK_HEIGHT, 0, _screen_width); 
        js_post_message_simply("in_normal_mode", NULL);
    } else {
        set_struct_partial(w, ORIENTATION_BOTTOM, 30, 0, _screen_width);
        js_post_message_simply("in_mini_mode", NULL);
        dock_release_region(0, 0, _screen_width, 30);
    }
}

JS_EXPORT_API
void dock_emit_webview_ok()
{
    static gboolean inited = FALSE;
    if (!inited) {
        tray_init(container);
        inited = TRUE;
        init_config();
        init_launchers();
        init_task_list();
    } else {
        update_dock_apps();
        update_task_list();
    }
}

JS_EXPORT_API
void dock_change_workarea_height(double height)
{
    if (height < 30) height = 30;
    set_struct_partial(gtk_widget_get_window(container), ORIENTATION_BOTTOM, height, 0, _screen_width); 
}
