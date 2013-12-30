#include <stdlib.h>

#include <gtk/gtk.h>

#include "main.h"
#include "tray.h"
#include "tray_hide.h"
#include "region.h"
#include "X_misc.h"
#include "i18n.h"
#include "DBUS_dapptray.h"


#define TRAY_ID_NAME "apptray.app.deepin"


static GtkWidget* container = NULL;


GdkWindow* TRAY_GDK_WINDOW()
{
    return gtk_widget_get_window(container);
}


static
gboolean leave_notify(GtkWidget* widget, GdkEvent* event, gpointer user_data)
{
    g_debug("[%s]", __func__);
    if (!is_mouse_in_tray())
        tray_delay_hide(100);
    return FALSE;
}


static
gboolean enter_notify(GtkWidget* widget, GdkEvent* event, gpointer user_data)
{
    g_debug("[%s]", __func__);
    tray_show_now();
}


static
gboolean motion_notify(GtkWidget* widget, GdkEvent* event, gpointer user_data)
{
    tray_show_real_now();
}


void parse_cmd(int argc, char* argv[])
{
    gboolean reparent_to_init = TRUE;
    if (argc == 2 && g_strcmp0(argv[1], "-d") == 0) {
        g_setenv("G_MESSAGES_DEBUG", "all", FALSE);
        reparent_to_init = FALSE;
    }

    if (argc == 2 && g_strcmp0(argv[1], "-f") == 0) {
        reparent_to_init = FALSE;
    }

    if (reparent_to_init && fork() != 0) {
        // exit on parent process
        exit(0);
    }
}


int main(int argc, char *argv[])
{
    init_i18n();
    gtk_init(&argc, &argv);
    parse_cmd(argc, argv);

    container = gtk_window_new(GTK_WINDOW_TOPLEVEL);

    GdkVisual* v = gdk_screen_get_rgba_visual(gdk_screen_get_default());
    if (v != NULL && gdk_screen_is_composited(gdk_screen_get_default())) {
        gtk_widget_set_visual(container, v);
        g_debug("support composition");
    }

    gtk_window_set_decorated(GTK_WINDOW(container), FALSE);
    gtk_window_set_resizable(GTK_WINDOW(container), FALSE);
    gtk_window_set_position(GTK_WINDOW(container), GTK_WIN_POS_CENTER);

    gtk_widget_set_events(container, GDK_ALL_EVENTS_MASK);
    gtk_widget_realize(container);

    g_signal_connect(container, "leave-notify-event", G_CALLBACK(leave_notify), NULL);
    g_signal_connect(container, "enter-notify-event", G_CALLBACK(enter_notify), NULL);
    g_signal_connect(container, "motion-notify-event", G_CALLBACK(motion_notify), NULL);

    GdkWindow* window = gtk_widget_get_window(container);
    set_wmspec_dock_hint(window);

    gtk_widget_set_size_request(container, gdk_screen_width(), TRAY_HEIGHT);

    gdk_error_trap_push();
    tray_init(container);

    gtk_widget_show_all(container);
    gtk_window_move(GTK_WINDOW(container), 0, 0);

    tray_delay_hide(1000/*ms*/);

    setup_apptray_dbus_service();
    gtk_main();
    return 0;
}

