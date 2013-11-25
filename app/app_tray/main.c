#include <gtk/gtk.h>

#include "na-tray.h"

#include "main.h"
#include "tray_hide.h"
#include "tray_guard_window.h"
#include "X_misc.h"


static GtkWidget* container = NULL;


GdkWindow* TRAY_GDK_WINDOW()
{
    return gtk_widget_get_window(container);
}


static
gboolean draw_background(GtkWidget* widget, cairo_t* cr, gpointer user_data)
{
    GtkWidget* container = GTK_WIDGET(widget);
    GdkWindow* gdk = gtk_widget_get_window(container);
    NaTray* tray = NA_TRAY(user_data);

    cairo_save(cr);
    cairo_set_operator(cr, CAIRO_OPERATOR_SOURCE);
    cairo_set_source_rgba(cr, 0, 0, 0, .6);
    cairo_fill(cr);
    cairo_paint(cr);
    cairo_set_operator(cr, CAIRO_OPERATOR_OVER);
    cairo_restore(cr);


    return FALSE;
    return TRUE;
}


static
gboolean leave_notify(GtkWidget* widget, GdkEvent* event, gpointer user_data)
{
    g_debug("[%s]", __func__);
    if (!is_mouse_in_tray())
        tray_delay_hide(100);
    return FALSE;
}


static
gboolean enter_notify(GtkWidget* widget, GdkEvent* event, gpointer user_data)
{
    g_debug("[%s]", __func__);
    tray_show_now();
}


int main(int argc, char *argv[])
{
    gtk_init(&argc, &argv);

    if (argc == 2 && g_strcmp0(argv[1], "-d") == 0)
        g_setenv("G_MESSAGES_DEBUG", "all", FALSE);

    container = gtk_window_new(GTK_WINDOW_TOPLEVEL);
    NaTray* tray = na_tray_new_for_screen(gdk_screen_get_default(), GTK_ORIENTATION_HORIZONTAL);
    gtk_container_add(GTK_CONTAINER(container), GTK_WIDGET(tray));
    gtk_widget_show(GTK_WIDGET(tray));
    GdkVisual* v = gdk_screen_get_rgba_visual(gdk_screen_get_default());
    if (v != NULL && gdk_screen_is_composited(gdk_screen_get_default())) {
        gtk_widget_set_visual(container, v);
        g_debug("support composition");
    }

    GdkWindow* tray_window = gtk_widget_get_window(GTK_WIDGET(tray));
    /* gdk_window_set_composited(tray_window, TRUE); */

    gtk_window_set_decorated(GTK_WINDOW(container), FALSE);
    gtk_window_set_resizable(GTK_WINDOW(container), FALSE);
    gtk_window_set_position(GTK_WINDOW(container), GTK_WIN_POS_CENTER);
    gtk_widget_realize(container);
    gtk_widget_realize(GTK_WIDGET(tray));

    /* g_signal_connect(container, "draw", G_CALLBACK(draw_background), (gpointer)tray); */
    g_signal_connect(container, "leave-notify-event", G_CALLBACK(leave_notify), NULL);
    g_signal_connect(container, "enter-notify-event", G_CALLBACK(enter_notify), NULL);

    GdkWindow* window = gtk_widget_get_window(container);
    set_wmspec_dock_hint(window);
    GdkRGBA rgba = {0, 0, 0, 0.6};
    cairo_pattern_t* pattern = cairo_pattern_create_rgba(0, 0, 0, 1);
    gdk_window_set_background_pattern(window, pattern);

    GdkColor c = {0,0,0,0};
    na_tray_set_colors(tray, &c, &c, &c, &c);
    gtk_widget_set_size_request(container, -1, TRAY_HEIGHT);

    GtkAllocation allocation;
    gtk_widget_get_allocation (container, &allocation);
    gtk_window_move(GTK_WINDOW(container), (gdk_screen_width() - allocation.width)/2.0, gdk_screen_height());
    /* init_tray_guard_window(allocation.width); */
    /* update_tray_guard_window_position(allocation.width); */

    GdkColor color = {0,0,0};
    na_tray_set_colors(tray, &color, &color, &color, &color);
    na_tray_force_redraw(tray);
    gtk_widget_show_all(container);
    /* tray_delay_hide(3000);  // ms */

    gtk_main();
    return 0;
}

