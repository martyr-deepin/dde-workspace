#include "dwebview.h"
#include "X_misc.h"
#include "xdg_misc.h"
#include "utils.h"
#include "tray.h"
#include "tasklist.h"

GtkWidget* container = NULL;
int main(int argc, char* argv[])
{
    gtk_init(&argc, &argv);
    set_default_theme("Deepin");
    set_desktop_env_name("GNOME");

    container = create_web_container(FALSE, TRUE);
    gtk_window_set_decorated(GTK_WINDOW(container), FALSE);

    char* path = get_html_path("dock");
    GtkWidget *webview = d_webview_new_with_uri(path);
    g_free(path);
    g_signal_connect_after(webview, "draw", G_CALLBACK(draw_tray_icons), NULL);

    gtk_container_add(GTK_CONTAINER(container), GTK_WIDGET(webview));


    g_signal_connect (container , "destroy", G_CALLBACK (gtk_main_quit), NULL);


    tray_init(container);
    monitor_tasklist_and_activewindow();


    gtk_widget_realize(container);
    /*set_wmspec_dock_hint(gtk_widget_get_window(container));*/
    gtk_window_move(GTK_WINDOW(container), 0, 900-50);
    gtk_window_resize(GTK_WINDOW(container), 1440, 50);
    set_struct_partial(gtk_widget_get_window(container), ORIENTATION_BOTTOM, 60, 0, 1440);
    gtk_window_set_skip_pager_hint(GTK_WINDOW(container), TRUE);
    gtk_window_set_keep_above(GTK_WINDOW(container), TRUE);

    gtk_widget_show_all(container);
    gtk_main();
    return 0;
}

