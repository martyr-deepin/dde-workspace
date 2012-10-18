#include "xdg_misc.h"
#include <gtk/gtk.h>

#define FLAG_NAME
#define FLAG_GENRICNAME
#define FLAG_COMMENT
#define FLAG_ICON
#define FLAG_EXEC
#define FLAG_EXEC_FLAG
#define FLAG_CATEGORY

const char* path = "/usr/share/applications;/usr/local/share/applications;";

char* get_items()
{
    return get_entries_by_func("/usr/share/applications;/usr/local/share/applications;/home/snyh/.local/share/applications", only_desktop);
}

gboolean prevent_exit(GtkWidget* w, GdkEvent* e)
{
    return TRUE;
}

int main(int argc, char* argv[])
{
    gtk_init(&argc, &argv);
    set_default_theme("Deepin");

    GtkWidget *w = create_web_container(TRUE, FALSE);
    gtk_window_set_decorated(w, FALSE);
    /*gdk_window_set_decorations(w, GdkWMDecoration(0));*/

    char* path = get_html_path("launcher");
    GtkWidget *webview = d_webview_new_with_uri(path);
    g_free(path);

    gtk_window_set_skip_pager_hint(GTK_WINDOW(w), TRUE);
    gtk_container_add(GTK_CONTAINER(w), GTK_WIDGET(webview));

    /*gtk_widget_realize(w);*/
    /*gtk_widget_realize(webview);*/

    GdkScreen* screen = gtk_window_get_screen(GTK_WINDOW(w));
    gtk_widget_set_size_request(w, gdk_screen_get_width(screen), gdk_screen_get_height(screen));
    printf("set_size_request: %d %d\n", gdk_screen_get_width(screen), gdk_screen_get_height(screen));

    gtk_widget_show_all(w);

    g_signal_connect (w , "destroy", G_CALLBACK (gtk_main_quit), NULL);
    gtk_main();
    return 0;
}
