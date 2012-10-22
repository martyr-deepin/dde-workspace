#include <gtk/gtk.h>
#include "na-tray.h"

int
main (int argc, char *argv[])
{
  gtk_init (&argc, &argv);
  GdkDisplay *display;
  GdkScreen *screen;
  GtkWidget *window;
  NaTray *tray;

  display = gdk_display_get_default ();
  screen = gdk_display_get_default_screen(display);

  window = gtk_window_new (GTK_WINDOW_TOPLEVEL);

  g_object_weak_ref (G_OBJECT (window), (GWeakNotify) gtk_main_quit, NULL);

  tray = na_tray_new_for_screen (screen, GTK_ORIENTATION_HORIZONTAL);
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(tray));

  gtk_widget_show_all (window);
  
  gtk_main ();

  return 0;
}
