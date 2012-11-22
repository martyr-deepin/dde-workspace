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
#include <cairo.h>

#define HEIGHT (50)

void close_show_temp();
void show_temp_region(double x, double y, double width, double height);
cairo_rectangle_int_t base_rect = {0, 50, 0, 50/* the width will change*/};

gboolean leave_notify(GtkWidget* w, GdkEvent* e, gpointer u)
{
    js_post_message("leave-notify", NULL);
}

void set_dock_size(GdkScreen* screen, GtkWidget* container)
{
    int s_width = gdk_screen_get_width(screen);
    int s_height = gdk_screen_get_height(screen);

    base_rect.width = s_width;
    base_rect.y = s_height - HEIGHT;

    GdkWindow* gdkw = gtk_widget_get_window(container);

    gdk_window_move_resize(gdkw, 0, 0, s_width, s_height);

    GdkRectangle rect = {0, 0, s_width, s_height};
    gtk_widget_size_allocate(container, &rect);

    set_struct_partial(gdkw, ORIENTATION_BOTTOM, 55, 0, s_width);
    printf("%d %d\n", s_width, s_height);
    /*js_post_message("screen_size_changed", NULL);*/
}


GtkWidget* container = NULL;
int main(int argc, char* argv[])
{
    init_i18n();
    gtk_init(&argc, &argv);

    g_log_set_default_handler((GLogFunc)log_to_file, "dock");
    set_default_theme("Deepin");
    set_desktop_env_name("GNOME");

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
    g_signal_connect(screen, "size-changed", G_CALLBACK(set_dock_size), webview);

    gtk_widget_realize(container);
    gtk_widget_realize(webview);
    gtk_widget_show_all(container);

    set_dock_size(screen, webview);

    /*set_wmspec_dock_hint(gtk_widget_get_window(container));*/

    close_show_temp();


    // this should at the lastest because of use container's window
    tray_init(container);
    monitor_tasklist_and_activewindow();

    gtk_main();
    return 0;
}


void show_temp_region(double x, double y, double width, double height)
{
    cairo_region_t *region = cairo_region_create_rectangle(&base_rect);
    cairo_rectangle_int_t tmp = {(int)x, (int)y, (int)width, (int)height};
    cairo_region_union_rectangle(region, &tmp);
    gdk_window_shape_combine_region(gtk_widget_get_window(container), region, 0, 0);
    cairo_region_destroy(region);
}
void close_show_temp()
{
    cairo_region_t *region = cairo_region_create_rectangle(&base_rect);
    gdk_window_shape_combine_region(gtk_widget_get_window(container), region, 0, 0);
    cairo_region_destroy(region);
}
