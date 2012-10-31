#include "dwebview.h"
#include "xdg_misc.h"
#include <gio/gio.h>

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

void monitor_dir_cb(GFileMonitor *m, 
        GFile *file, GFile *other, GFileMonitorEvent t, 
        gpointer path)
{
    switch (t) {
        case G_FILE_MONITOR_EVENT_MOVED:
            {
                char* new_path = g_file_get_path(other);
                if (g_strcmp0(new_path, get_desktop_dir(FALSE)) == 0) {
                    char* info = get_entry_info(new_path);
                    js_post_message("item_update", info);
                    g_free(info);
                    break;
                }
                g_free(new_path);
            }
        case G_FILE_MONITOR_EVENT_DELETED:
        case G_FILE_MONITOR_EVENT_CREATED:
        /*case G_FILE_MONITOR_EVENT_ATTRIBUTE_CHANGED:*/
            {
                char* tmp = g_strdup_printf("{\"id\":\"%s\"}", (char*)path);
                js_post_message("dir_changed", tmp);
                break;
            }
    }
}


GHashTable *monitor_table = NULL;

void begin_monitor_dir(const char* path, GCallback cb)
{
    if (!g_hash_table_contains(monitor_table, path)) {
        GFile* dir = g_file_new_for_path(path);
        GFileMonitor* monitor = g_file_monitor_directory(dir, G_FILE_MONITOR_NONE, NULL, NULL);
        char* key = g_strdup(path);
        g_hash_table_insert(monitor_table, key, monitor);
        g_signal_connect(monitor, "changed", cb, key);
    } else {
        g_warning("The %s has aleardy monitored! You many forget call the function of end_monitor_dir", path);
    }
}

void end_monitor_dir(const char* path)
{
    g_hash_table_remove(monitor_table, path);
}


void install_monitor()
{
    if (monitor_table == NULL) {
        monitor_table = g_hash_table_new_full(g_str_hash, g_str_equal, g_free, (GDestroyNotify)g_file_monitor_cancel);

        begin_monitor_dir(get_desktop_dir(TRUE), G_CALLBACK(monitor_desktop_dir_cb));
    }
}



//JS_EXPORT
void monitor_dir(const char* path)
{
    begin_monitor_dir(path, G_CALLBACK(monitor_dir_cb));
}
//JS_EXPORT
void cancel_monitor_dir(const char* path)
{
    end_monitor_dir(path);
}

