#include <gtk/gtk.h>
#include <gdk/gdk.h>
#include "tray_manager.h"

GtkWidget *w ;
GtkWidget* icons[100];
int count1 = 0;

void do_size_allocate(GtkWidget *w, GdkRectangle *allocation, gpointer user_data)
{
    printf("child:%d\n", count1);

    for (int i=0; i<3; i++) {
        GtkAllocation allocation1 = {60 * i, 0, 50, 50};
        gtk_widget_size_allocate(icons[i], &allocation1);
        //gtk_widget_show_all(icons[i]);
    }
}

void tray_added1(TrayManager *manager, GtkWidget* icon, gpointer data)
{
    puts("add new\n");
    icons[count1++] = icon;
    GtkRequisition req;
    gtk_widget_set_parent(icon, w);

    //GtkAllocation allocation1 = {0, 0, 50, 50};
    //gtk_widget_size_allocate(icon, &allocation1);
    //gtk_widget_set_size_request(icons[0], 40, 40);
    //gtk_widget_size_request(icon, &req);
    //gtk_widget_queue_resize(w);
    //printf("child :%p  w:%d, h:%d\n", icon, req.width, req.height);
}
void tray_removed1(TrayManager *manager, GtkWidget* icon, gpointer data)
{
    puts("add new\n");
}

int main(int argc, char* argv[])
{
    gtk_init(&argc, &argv);

    GdkDisplay *display = gdk_display_get_default();
    GdkScreen *screen = gdk_display_get_screen(display, 0);
    if (tray_manager_check_running(screen)) {
        puts("aleray running an tray manager\n");
        return -1;
    }
    TrayManager *tray_manager = tray_manager_new();
    tray_manager_manage_screen(tray_manager, screen);

    g_signal_connect (tray_manager, "tray_icon_added", G_CALLBACK (tray_added1), NULL);
    g_signal_connect (tray_manager, "tray_icon_removed", G_CALLBACK (tray_removed1), NULL);

    w = gtk_window_new(GTK_WINDOW_TOPLEVEL);
    g_signal_connect (w , "destroy", G_CALLBACK (gtk_main_quit), NULL);
    g_signal_connect(w, "size-allocate", G_CALLBACK(do_size_allocate), NULL);

    gtk_widget_show_all(w);
    gtk_main();
    return 0;
}
