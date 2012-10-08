#include "dwebview.h"
#include "xdg_misc.h"
#include <gio/gio.h>

void install_monitor();
GFileMonitor *monitor = NULL;

void monitor_desktop_dir_cb(GFileMonitor *m, 
        GFile *file, GFile *other, GFileMonitorEvent t, 
        gpointer user_data)
{
    switch (t) {
        case G_FILE_MONITOR_EVENT_MOVED:
            {
                char* old_path = g_file_get_path(file);
                char* new_path = g_file_get_path(other);
                char* info = get_entry_info(new_path);

                char* tmp = g_strdup_printf("{\"old_id\":\"%s\", \"info\":%s}", old_path, info);
                js_post_message("item_rename", tmp);
                g_free(tmp);

                g_free(info);
                g_free(old_path);
                g_free(new_path);
                break;
            }
        case G_FILE_MONITOR_EVENT_DELETED:
            {
                char* path = g_file_get_path(file);
                if (g_strcmp0(path, get_desktop_dir(FALSE)) == 0) {
                    /*g_file_monitor_cancel(m);*/
                    /*install_monitor();*/
                } else {
                    /*item_notify(ITEM_DELETE, path, NULL);*/
                    char* tmp = g_strdup_printf("\"%s\"", path);
                    js_post_message("item_delete", tmp);
                    g_free(tmp);
                }
                g_free(path);
                break;
            }
        case G_FILE_MONITOR_EVENT_CREATED:
        /*case G_FILE_MONITOR_EVENT_ATTRIBUTE_CHANGED:*/
            {
                char* path = g_file_get_path(file);
                char* info = get_entry_info(path);
                js_post_message("item_update", info);

                g_free(info);
                g_free(path);
                break;
            }
    }

}

void install_monitor()
{
    if (monitor == NULL) {
        GFile *dir = g_file_new_for_path(get_desktop_dir(TRUE));
        monitor = g_file_monitor_directory(dir,
                G_FILE_MONITOR_SEND_MOVED, NULL, NULL);
        g_signal_connect(monitor, "changed", 
                G_CALLBACK(monitor_desktop_dir_cb), NULL);
    }
}

