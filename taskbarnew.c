#include <gtk/gtk.h>
#include <gdk/gdk.h>
#include <webkit/webkit.h>
#include "lib/taskbar.h"

int main(int argc, char* argv[])
{
    gtk_init(&argc, &argv);

    GtkWidget *w = create_web_container();
    //GtkWidget *w = gtk_window_new(GTK_WINDOW_TOPLEVEL);
    GtkWidget *tb = d_taskbar_new();

    gtk_container_add(GTK_CONTAINER(w), GTK_WIDGET(tb));
    gtk_widget_show_all(w);

    g_signal_connect (w , "destroy", G_CALLBACK (gtk_main_quit), NULL);
    gtk_main();
    return 0;
}
