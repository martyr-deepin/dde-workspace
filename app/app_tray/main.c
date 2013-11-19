#include <gtk/gtk.h>

#include "na-tray.h"

#include "X_misc.h"


gboolean draw_background(GtkWidget* widget, cairo_t* cr, gpointer user_data)
{
    GtkWidget* container = GTK_WIDGET(widget);
    GdkWindow* gdk = gtk_widget_get_window(container);
    NaTray* tray = NA_TRAY(user_data);

    cairo_save(cr);
    cairo_set_operator(cr, CAIRO_OPERATOR_CLEAR);
    cairo_set_source_rgba(cr, 0, 0, 0, .8);
    GtkAllocation allocation;
    gtk_widget_get_allocation (container, &allocation);
    cairo_rectangle (cr, allocation.x, allocation.y, allocation.width, allocation.height);
    cairo_fill(cr);
    cairo_set_operator(cr, CAIRO_OPERATOR_OVER);
    cairo_paint(cr);
    cairo_restore(cr);

    GdkColor color = {0,0,0};
    na_tray_set_colors(tray, &color, &color, &color, &color);
    na_tray_force_redraw(tray);

    gtk_window_move(GTK_WINDOW(container), (gdk_screen_width() - allocation.width)/2.0, 0);

    return FALSE;
}


int main(int argc, char *argv[])
{
    gtk_init(&argc, &argv);

    GtkWidget* container = gtk_window_new(GTK_WINDOW_TOPLEVEL);
    NaTray* tray = na_tray_new_for_screen(gdk_screen_get_default(), GTK_ORIENTATION_HORIZONTAL);
    gtk_container_add(GTK_CONTAINER(container), GTK_WIDGET(tray));
    gtk_widget_show(GTK_WIDGET(tray));

    gtk_window_set_decorated(GTK_WINDOW(container), FALSE);
    gtk_window_set_resizable(GTK_WINDOW(container), FALSE);
    gtk_window_set_position(GTK_WINDOW(container), GTK_WIN_POS_CENTER);
    gtk_widget_realize(container);
    gtk_widget_realize(GTK_WIDGET(tray));

    g_signal_connect(container, "draw", G_CALLBACK(draw_background), (gpointer)tray);

    GdkWindow* window = gtk_widget_get_window(container);
    set_wmspec_dock_hint(window);

    /* GdkColor c = {0,0,0,0}; */
    /* na_tray_set_colors(tray, &c, &c, &c, &c); */
    gtk_widget_set_size_request(container, -1, 30);

    GtkAllocation allocation;
    gtk_widget_get_allocation (container, &allocation);
    gtk_window_move(GTK_WINDOW(container), (gdk_screen_width() - allocation.width)/2.0, gdk_screen_height());

    gtk_widget_show_all(container);

    gtk_main();
    return 0;
}

