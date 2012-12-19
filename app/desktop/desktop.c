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
#include "i18n.h"
#include <cairo/cairo-xlib.h>

void install_monitor();

JS_EXPORT_API
char* desktop_get_desktop_items()
{
    return get_desktop_entries();
}

JS_EXPORT_API
char* desktop_get_items_by_dir(const char* path)
{
    return get_entries_by_func(path, no_dot_hidden_file);
}

JS_EXPORT_API
void desktop_notify_workarea_size()
{
    int x, y, width, height;
    get_workarea_size(0, 0, &x, &y, &width, &height);
    char* tmp = g_strdup_printf("{\"x\":%d, \"y\":%d, \"width\":%d, \"height\":%d}", x, y, width, height);
    js_post_message_simply("workarea_changed", tmp);
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

Pixmap ROOT_PIXMAP = 0;
Atom ATOM_ROOT_PIXMAP = 0;

GtkWidget* container = NULL;
void update_root_pixmap()
{
    Display *_dsp = GDK_DISPLAY_XDISPLAY(gdk_display_get_default());
    long items = 0;
    void* data = get_window_property(_dsp, GDK_ROOT_WINDOW(), ATOM_ROOT_PIXMAP,
            &items);
    if (data != NULL) {
        ROOT_PIXMAP = X_FETCH_32(data, 0);
        gtk_widget_queue_draw(container);
    }
    else
        ROOT_PIXMAP = 0;
}

GdkFilterReturn monitor_root_change(GdkXEvent *xevent, GdkEvent *event, gpointer data)
{
    if (((XEvent*)xevent)->type == PropertyNotify) {
        XPropertyEvent* ev = xevent;
        if (ev->atom == ATOM_ROOT_PIXMAP) {
            update_root_pixmap();
        } 
    } 
    return GDK_FILTER_CONTINUE;
}

gboolean draw_back(GtkWidget* widget, cairo_t* cr, gpointer user_data)
{

    if (ROOT_PIXMAP == 0)
        return FALSE;

    Display *_dsp = GDK_DISPLAY_XDISPLAY(gdk_display_get_default());
    GdkScreen *screen = gdk_screen_get_default();
    int s_width = gdk_screen_get_width(screen);
    int s_height = gdk_screen_get_height(screen);
    GdkVisual *visual = gdk_screen_get_system_visual (screen);
    cairo_surface_t* surface = cairo_xlib_surface_create(_dsp, ROOT_PIXMAP, GDK_VISUAL_XVISUAL(visual), s_width, s_height);

    cairo_set_source_surface(cr, surface, 0, 0);
    cairo_paint(cr);

    cairo_surface_destroy(surface);
    return FALSE;
}

int main(int argc, char* argv[])
{
    init_i18n();
    gtk_init(&argc, &argv);
    set_default_theme("Deepin");
    set_desktop_env_name("GNOME");

    /*GtkWidget *w = create_web_container(FALSE, FALSE);*/
    container = create_web_container(FALSE, FALSE);
    g_signal_connect(container, "delete-event", G_CALLBACK(prevent_exit), NULL);

    GtkWidget *webview = d_webview_new_with_uri(GET_HTML_PATH("desktop"));
    gdk_error_trap_push();

    gtk_window_set_skip_pager_hint(GTK_WINDOW(container), TRUE);
    gtk_container_add(GTK_CONTAINER(container), GTK_WIDGET(webview));
    /*g_signal_connect(webview, "realize", G_CALLBACK(watch_workarea_changes), NULL); */
    /*g_signal_connect(webview, "unrealize", G_CALLBACK(unwatch_workarea_changes), NULL);*/

    gtk_widget_realize(container);
    gtk_widget_realize(webview);
    g_signal_connect (webview, "draw", G_CALLBACK(draw_back), NULL);

    GdkScreen* screen = gtk_window_get_screen(GTK_WINDOW(container));
    gtk_widget_set_size_request(container, gdk_screen_get_width(screen),
            gdk_screen_get_height(screen));

    g_signal_connect(screen, "size-changed", G_CALLBACK(screen_change_size), container);

    set_wmspec_desktop_hint(gtk_widget_get_window(container));
    watch_workarea_changes(container);

    GdkWindow* fw = webkit_web_view_get_forward_window(webview);
    gdk_window_stick(fw);

    install_monitor();

    ATOM_ROOT_PIXMAP = gdk_x11_get_xatom_by_name("_XROOTPMAP_ID");
    GdkWindow* root = gdk_get_default_root_window();
    gdk_window_set_events(root, GDK_PROPERTY_CHANGE_MASK | gdk_window_get_events(root));
    gdk_window_add_filter(root, monitor_root_change, NULL);
    update_root_pixmap();

    gtk_widget_show_all(container);
    g_signal_connect (container , "destroy", G_CALLBACK (gtk_main_quit), NULL);
    gtk_main();
    unwatch_workarea_changes(container);
    return 0;
}
