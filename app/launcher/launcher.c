#include "xdg_misc.h"
#include <gtk/gtk.h>
#include "dwebview.h"
#include "utils.h"
#include "X_misc.h"

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
    set_desktop_env_name("GNOME");

    GtkWidget *w = create_web_container(TRUE, FALSE);
    gtk_window_set_decorated(GTK_WINDOW(w), FALSE);

    char* path = get_html_path("launcher");
    GtkWidget *webview = d_webview_new_with_uri(path);
    g_free(path);

    gtk_window_set_skip_pager_hint(GTK_WINDOW(w), TRUE);
    gtk_container_add(GTK_CONTAINER(w), GTK_WIDGET(webview));

    gtk_widget_realize(w);


    GdkScreen* screen = gtk_window_get_screen(GTK_WINDOW(w));
    gtk_window_resize(GTK_WINDOW(w), gdk_screen_get_width(screen), gdk_screen_get_height(screen));
    printf("set_size_request: %d %d\n", gdk_screen_get_width(screen), gdk_screen_get_height(screen));

    gtk_widget_show_all(w);

    g_signal_connect (w , "destroy", G_CALLBACK (gtk_main_quit), NULL);

    watch_workarea_changes(w);
    gtk_main();
    unwatch_workarea_changes(w);
    return 0;
}

void exit()
{
    gtk_main_quit();
}
