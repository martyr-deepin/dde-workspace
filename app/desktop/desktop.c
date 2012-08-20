#include <dwebview.h>
#include <utils.h>
#include <gtk/gtk.h>
#include <gdk/gdk.h>
#include <X11/X.h>
#include <X11/Xatom.h>


static void set_wmspec_desktop_hint (GdkWindow *window)
{
    GdkAtom atom = gdk_atom_intern ("_NET_WM_WINDOW_TYPE_DESKTOP", FALSE);

    gdk_property_change (window,
            gdk_atom_intern ("_NET_WM_WINDOW_TYPE", FALSE),
            gdk_x11_xatom_to_atom (XA_ATOM), 32,
            GDK_PROP_MODE_REPLACE, (guchar *) &atom, 1);
}


int main(int argc, char* argv[])
{
    gtk_init(&argc, &argv);

    GtkWidget *w = create_web_container(FALSE, FALSE);
    char* path = get_html_path("desktop");
    GtkWidget *webview = d_webview_new_with_uri(path);
    g_free(path);

    gtk_widget_realize(w);
    /*set_wmspec_desktop_hint(gtk_widget_get_window(w));*/

    gtk_container_add(GTK_CONTAINER(w), GTK_WIDGET(webview));
    gtk_widget_show_all(w);

    g_signal_connect (w , "destroy", G_CALLBACK (gtk_main_quit), NULL);
    gtk_main();
    return 0;
}
