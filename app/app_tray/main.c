#include <stdlib.h>

#include <gtk/gtk.h>
#include <dbus/dbus.h>
#include <dbus/dbus-glib.h>

#include "main.h"
#include "tray.h"
#include "tray_hide.h"
#include "region.h"
#include "X_misc.h"
#include "i18n.h"
#include "DBUS_dapptray.h"


#define TRAY_ID_NAME "apptray.app.deepin"


void log_to_file(const gchar* log_domain, GLogLevelFlags log_level, const gchar* message, char* app_name)
{
    char* log_file_path = g_strdup_printf("/tmp/%s.log", app_name);
    FILE *logfile = fopen(log_file_path, "a");
    g_free(log_file_path);
    if (logfile != NULL) {
        fprintf(logfile, "%s\n", message);
        fclose(logfile);
    }
    g_log_default_handler(log_domain, log_level, message, NULL);
}


static GtkWidget* container = NULL;
struct DisplayInfo apptray;


GdkWindow* TRAY_GDK_WINDOW()
{
    return gtk_widget_get_window(container);
}


static
gboolean leave_notify(GtkWidget* widget, GdkEvent* event, gpointer user_data)
{
    // g_debug("[%s]", __func__);
    if (!is_mouse_in_tray()) {
        if (!tray_is_always_shown()) {
            g_warning("levae notify");
            tray_delay_hide(100);
        }
    }
    return FALSE;
}


static
gboolean enter_notify(GtkWidget* widget, GdkEvent* event, gpointer user_data)
{
    // g_debug("[%s]", __func__);
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


static
gboolean primary_changed_handler(gpointer data)
{
    DBusConnection* conn = (DBusConnection*)data;
    dbus_connection_read_write(conn, 0);
    DBusMessage* message = dbus_connection_pop_message(conn);

    if (message == NULL) {
        return G_SOURCE_CONTINUE;
    }

    g_debug("[%s] loop for signal", __func__);
    if (dbus_message_is_signal(message,
                               DISPLAY_INTERFACE,
                               PRIMARY_CHANGED_SIGNAL)) {
        DBusMessageIter args;
        if (!dbus_message_iter_init(message, &args)) {
            dbus_message_unref(message);
            g_warning("init signal iter failed");
            return G_SOURCE_CONTINUE;
        }

        DBusMessageIter element_iter;
        dbus_message_iter_recurse(&args, &element_iter);

        g_debug("[%s] get signal", __func__);
        // iterate_container_message(conn, &array_iter, iter_array, info);
        int count = 0;
        while (dbus_message_iter_get_arg_type(&element_iter) != DBUS_TYPE_INVALID) {
            switch (count) {
            case 0: {
                DBusBasicValue value;
                dbus_message_iter_get_basic(&element_iter, &value);
                apptray.x = value.i16;
                break;
            }
            case 1: {
                DBusBasicValue value;
                dbus_message_iter_get_basic(&element_iter, &value);
                apptray.y = value.i16;
                break;
            }
            case 2: {
                DBusBasicValue value;
                dbus_message_iter_get_basic(&element_iter, &value);
                apptray.width = value.u16;
                break;
            }
            case 3: {
                DBusBasicValue value;
                dbus_message_iter_get_basic(&element_iter, &value);
                apptray.height = value.u16;
                break;
            }
            }
            ++count;
            dbus_message_iter_next(&element_iter);
        }
    }
    dbus_message_unref(message);

    return G_SOURCE_CONTINUE;
}


int main(int argc, char *argv[])
{
    parse_cmd(argc, argv);
    init_i18n();
    gtk_init(&argc, &argv);

    container = gtk_window_new(GTK_WINDOW_TOPLEVEL);

    GdkVisual* v = gdk_screen_get_rgba_visual(gdk_screen_get_default());
    if (v != NULL && gdk_screen_is_composited(gdk_screen_get_default())) {
        gtk_widget_set_visual(container, v);
        // g_debug("support composition");
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

#ifdef NDEBUG
    g_setenv("G_MESSAGES_DEBUG", "all", FALSE);
    g_log_set_default_handler((GLogFunc)log_to_file, "dapptray");
#endif

    gdk_error_trap_push();
    tray_init(container);
    setup_apptray_dbus_service();

    update_display_info(&apptray);
    listen_primary_changed_signal(primary_changed_handler);
    gtk_widget_set_size_request(container, apptray.width, TRAY_HEIGHT);
    gtk_window_move(GTK_WINDOW(container), 0, 0);
    gtk_widget_show_all(container);

    if (!tray_is_always_shown()) {
        tray_delay_hide(1000/*ms*/);
    }

    gtk_main();
    return 0;
}

