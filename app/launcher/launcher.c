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
    return get_entries_by_func("/usr/share/applications;/usr/local/share/applications;~/.local/share/applications", only_desktop);
}

gboolean prevent_exit(GtkWidget* w, GdkEvent* e)
{
    return TRUE;
}

GtkWidget* container = NULL;
int main(int argc, char* argv[])
{
    gtk_init(&argc, &argv);
    set_default_theme("Deepin");
    set_desktop_env_name("GNOME");

    container = create_web_container(FALSE, TRUE);
    gtk_window_set_decorated(GTK_WINDOW(container), FALSE);

    char* path = get_html_path("launcher");
    GtkWidget *webview = d_webview_new_with_uri(path);
    g_free(path);

    gtk_window_set_skip_pager_hint(GTK_WINDOW(container), TRUE);
    gtk_container_add(GTK_CONTAINER(container), GTK_WIDGET(webview));

    gtk_widget_realize(container);


    g_signal_connect (container , "destroy", G_CALLBACK (gtk_main_quit), NULL);

    gtk_window_maximize(GTK_WINDOW(container));

    watch_workarea_changes(container);
    gtk_widget_show_all(container);
    gtk_main();
    /*unwatch_workarea_changes(w);*/
    return 0;
}

void exit_gui()
{
    gtk_main_quit();
}

void notify_workarea_size()
{
    int x, y, width, height;
    get_workarea_size(0, 0, &x, &y, &width, &height);
    char* tmp = g_strdup_printf("{\"x\":%d, \"y\":%d, \"width\":%d, \"height\":%d}", x, y, width, height);
    js_post_message("workarea_changed", tmp);
    GtkAllocation alloc = {x, y, width, height};
    gtk_widget_size_allocate(container, &alloc);
    /*gtk_window_resize(GTK_WINDOW(container), width, height);*/
}
