#include <gtk/gtk.h>

#include "na-tray.h"

#include "X_misc.h"

int main(int argc, char *argv[])
{
    gtk_init(&argc, &argv);
    GtkWidget* main = gtk_window_new(GTK_WINDOW_TOPLEVEL);
    gtk_window_set_decorated(GTK_WINDOW(main), FALSE);
    gtk_window_set_resizable(GTK_WINDOW(main), FALSE);
    gtk_window_set_position(GTK_WINDOW(main), GTK_WIN_POS_CENTER);
    gtk_widget_realize(main);

    GdkWindow* window = gtk_widget_get_window(main);
    set_wmspec_dock_hint(window);

    NaTray* tray = na_tray_new_for_screen(gdk_screen_get_default(), GTK_ORIENTATION_HORIZONTAL);
    na_tray_set_padding(tray, 100);

    gtk_container_add(GTK_CONTAINER(main), GTK_WIDGET(tray));
    gtk_widget_show_all(main);

    /* int x, width; */
    /* gdk_window_get_geometry(window, &x, NULL, &width, NULL); */
    /* gtk_window_move(GTK_WINDOW(main), x - width /2, 0); */
    gtk_main();
    return 0;
}

