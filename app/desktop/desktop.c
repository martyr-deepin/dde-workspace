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

void change_size(GdkScreen *screen, GtkWidget *w)
{
    gtk_widget_set_size_request(w, gdk_screen_get_width(screen),
            gdk_screen_get_height(screen));
}


int main(int argc, char* argv[])
{
    gtk_init(&argc, &argv);

    GtkWidget *w = create_web_container(FALSE, FALSE);
    char* path = get_html_path("desktop");
    GtkWidget *webview = d_webview_new_with_uri(path);
    g_free(path);

    gtk_widget_realize(w);

    GdkScreen* screen = gtk_window_get_screen(GTK_WINDOW(w));
    gtk_widget_set_size_request(w, gdk_screen_get_width(screen),
            gdk_screen_get_height(screen));

    g_signal_connect(screen, "size-changed", G_CALLBACK(change_size), w);

    set_wmspec_desktop_hint(gtk_widget_get_window(w));


    gtk_window_set_skip_pager_hint(GTK_WINDOW(w), TRUE);

    gtk_container_add(GTK_CONTAINER(w), GTK_WIDGET(webview));
    gtk_widget_show_all(w);

    GtkSettings *s = gtk_settings_get_default();
    GValue name = G_VALUE_INIT;
    g_value_init(&name, G_TYPE_STRING);
    g_value_set_string(&name, "Deepin");
    g_object_set_property(s, "gtk-icon-theme-name", &name);

    g_signal_connect (w , "destroy", G_CALLBACK (gtk_main_quit), NULL);
    gtk_main();
    return 0;
}
