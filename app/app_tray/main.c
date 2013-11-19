#include <gtk/gtk.h>

#include "na-tray.h"

#include "X_misc.h"


gboolean draw_background(GtkWidget* widget, cairo_t* cr, gpointer user_data)
{
    cairo_save(cr);
    cairo_set_source_rgba(cr, 0,0,0,1);
    GtkWidget* container = GTK_WIDGET(widget);
    GdkWindow* gdk = gtk_widget_get_window(container);
    GtkAllocation allocation;
    gtk_widget_get_allocation (container, &allocation);
    cairo_rectangle (cr, allocation.x, allocation.y, allocation.width, allocation.height);
    /* int x, y, width, height; */
    /* gdk_window_get_geometry(gdk, &x, &y, &width, &height); */
    /* cairo_rectangle (cr, x, y, width, height); */
    cairo_paint(cr);
    cairo_restore(cr);
    NaTray* tray = NA_TRAY(user_data);
    GdkColor color = {0,0,0};
    na_tray_set_colors(tray, &color, &color, &color, &color);
    na_tray_force_redraw(tray);
    /* return TRUE; */
    return FALSE;
}


int main(int argc, char *argv[])
{
    gtk_init(&argc, &argv);
    GtkWidget* main = gtk_window_new(GTK_WINDOW_TOPLEVEL);
    gtk_window_set_decorated(GTK_WINDOW(main), FALSE);
    gtk_window_set_resizable(GTK_WINDOW(main), FALSE);
    gtk_window_set_position(GTK_WINDOW(main), GTK_WIN_POS_CENTER);
    gtk_widget_realize(main);

    NaTray* tray = na_tray_new_for_screen(gdk_screen_get_default(), GTK_ORIENTATION_HORIZONTAL);
    g_signal_connect(main, "draw", G_CALLBACK(draw_background), (gpointer)tray);

    GdkWindow* window = gtk_widget_get_window(main);
    set_wmspec_dock_hint(window);
    GdkRGBA rgba = {0,0,0,0.8};
    gdk_window_set_background_rgba(window, &rgba);

    gtk_container_add(GTK_CONTAINER(main), GTK_WIDGET(tray));
    gtk_widget_set_size_request(main, 20, 20);
    gtk_widget_show_all(main);

    gtk_main();
    return 0;
}

