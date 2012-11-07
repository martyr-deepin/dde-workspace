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
#include <utils.h>
#include <gtk/gtk.h>
#include "xdg_misc.h"
#include "X_misc.h"

void install_monitor();


char* get_desktop_items()
{
    return get_desktop_entries();
}

char* get_items_by_dir(const char* path)
{
    return get_entries_by_func(path, no_dot_hidden_file);
}

void notify_workarea_size()
{
    int x, y, width, height;
    get_workarea_size(0, 0, &x, &y, &width, &height);
    char* tmp = g_strdup_printf("{\"x\":%d, \"y\":%d, \"width\":%d, \"height\":%d}", x, y, width, height);
    js_post_message("workarea_changed", tmp);
}


//TODO: connect gtk_icon_theme changed.

static
void screen_change_size(GdkScreen *screen, GtkWidget *w)
{
    gtk_widget_set_size_request(w, gdk_screen_get_width(screen),
            gdk_screen_get_height(screen));
}




gboolean prevent_exit(GtkWidget* w, GdkEvent* e)
{
    return true;
}

int main(int argc, char* argv[])
{
    gtk_init(&argc, &argv);
    set_default_theme("Deepin");

    GtkWidget *w = create_web_container(FALSE, FALSE);
    g_signal_connect(w, "delete-event", G_CALLBACK(prevent_exit), NULL);

    char* path = get_html_path("desktop");
    GtkWidget *webview = d_webview_new_with_uri(path);
    g_free(path);

    gtk_window_set_skip_pager_hint(GTK_WINDOW(w), TRUE);
    gtk_container_add(GTK_CONTAINER(w), GTK_WIDGET(webview));
    /*g_signal_connect(webview, "realize", G_CALLBACK(watch_workarea_changes), NULL); */
    /*g_signal_connect(webview, "unrealize", G_CALLBACK(unwatch_workarea_changes), NULL);*/

    gtk_widget_realize(w);
    gtk_widget_realize(webview);

    GdkScreen* screen = gtk_window_get_screen(GTK_WINDOW(w));
    gtk_widget_set_size_request(w, gdk_screen_get_width(screen),
            gdk_screen_get_height(screen));

    g_signal_connect(screen, "size-changed", G_CALLBACK(screen_change_size), w);

    set_wmspec_desktop_hint(gtk_widget_get_window(w));
    watch_workarea_changes(w);

    GdkWindow* webkit_web_view_get_forward_window(GtkWidget*);
    GdkWindow* fw = webkit_web_view_get_forward_window(webview);
    gdk_window_stick(fw);


    gtk_widget_show_all(w);

    install_monitor();

    g_signal_connect (w , "destroy", G_CALLBACK (gtk_main_quit), NULL);
    gtk_main();
    unwatch_workarea_changes(w);
    return 0;
}
