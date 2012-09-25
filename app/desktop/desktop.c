#include <dwebview.h>
#include <utils.h>
#include <gtk/gtk.h>
#include <gdk/gdkx.h>
#include <X11/X.h>
#include <X11/Xatom.h>
#include "xdg_misc.h"


static void set_wmspec_desktop_hint (GdkWindow *window)
{
    GdkAtom atom = gdk_atom_intern ("_NET_WM_WINDOW_TYPE_DESKTOP", FALSE);

    gdk_property_change (window,
            gdk_atom_intern ("_NET_WM_WINDOW_TYPE", FALSE),
            gdk_x11_xatom_to_atom (XA_ATOM), 32,
            GDK_PROP_MODE_REPLACE, (guchar *) &atom, 1);
}

void change_size(GdkScreen *screen, GtkWidget *w)
{
    gtk_widget_set_size_request(w, gdk_screen_get_width(screen),
            gdk_screen_get_height(screen));
}

gboolean prevent_exit(GtkWidget* w, GdkEvent* e)
{
    return true;
}

int main(int argc, char* argv[])
{
    gtk_init(&argc, &argv);
    set_default_theme("Deepin");

    GtkWidget *w = create_web_container(FALSE, FALSE);
    g_signal_connect(w, "delete-event", G_CALLBACK(prevent_exit), NULL);

    char* path = get_html_path("desktop");
    GtkWidget *webview = d_webview_new_with_uri(path);
    g_free(path);

    gtk_window_set_skip_pager_hint(GTK_WINDOW(w), TRUE);
    gtk_container_add(GTK_CONTAINER(w), GTK_WIDGET(webview));

    gtk_widget_realize(w);
    gtk_widget_realize(webview);

    GdkScreen* screen = gtk_window_get_screen(GTK_WINDOW(w));
    gtk_widget_set_size_request(w, gdk_screen_get_width(screen),
            gdk_screen_get_height(screen));

    g_signal_connect(screen, "size-changed", G_CALLBACK(change_size), w);

    set_wmspec_desktop_hint(gtk_widget_get_window(w));

    GdkWindow* webkit_web_view_get_forward_window(GtkWidget*);
    GdkWindow* fw = webkit_web_view_get_forward_window(webview);
    gdk_window_stick(fw);


    gtk_widget_show_all(w);


    g_signal_connect (w , "destroy", G_CALLBACK (gtk_main_quit), NULL);
    gtk_main();
    return 0;
}
