#include <gtk/gtk.h>
#include "calc.h"

cairo_surface_t* img = NULL;

char* path;
gboolean tt(GtkWidget* w, cairo_t* cr)
{
    if (img) {
        double r, g, b;
        calc_dominant_color_by_path(path, &r, &g, &b);
        cairo_set_source_rgb(cr, r, g, b);
        cairo_paint(cr);
        /*cairo_set_operator(cr, CAIRO_OPERATOR_SOURCE);*/
        cairo_set_source_surface(cr, img, 0, 0);
        cairo_paint(cr);
        return TRUE;
    } else
        return FALSE;
}

gboolean load_color(GtkWidget* w, GdkEvent* event)
{
    printf("sdd\n");
    img = cairo_image_surface_create_from_png("board.png");
    gtk_widget_queue_draw(w);
    return TRUE;
}

int main(int a, char* argv[])
{
    path = argv[1];
    gtk_init(NULL, NULL);
    GtkWidget* w = gtk_window_new(GTK_WINDOW_TOPLEVEL);
    gtk_widget_set_size_request(w, 500, 500);
    g_signal_connect(w, "button-press-event", G_CALLBACK(load_color), NULL);
    gtk_widget_add_events(w, GDK_ALL_EVENTS_MASK);
    g_signal_connect(w, "draw", G_CALLBACK(tt), NULL);
    gtk_widget_show(w);
    gtk_main();
}
