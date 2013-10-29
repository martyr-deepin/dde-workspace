#include <gtk/gtk.h>
#include "launcher_test.h"
#include "../file_monitor.h"


#ifdef __DUI_DEBUG
void append_monitor(GPtrArray* monitors, const GPtrArray* paths, GCallback monitor_callback);
GPtrArray* _get_all_applications_dirs();
struct DesktopInfo* desktop_info_create(const char* path, enum DesktopStatus status);
void desktop_info_destroy(struct DesktopInfo* di);
gboolean _update_items(gpointer user_data);
void desktop_monitor_callback(GFileMonitor* monitor, GFile* file, GFile* other_file,
                              GFileMonitorEvent event_type, gpointer data);
void _monitor_desktop_files();
gboolean _update_autostart(gpointer user_data);
void autostart_monitor_callback(GFileMonitor* monitor, GFile* file, GFile* other_file,
                                GFileMonitorEvent event_type, gpointer data);
void _monitor_autostart_files();

void test_get_all_applications_dirs()
{
    Test({
         GPtrArray* dirs = _get_all_applications_dirs();
         g_ptr_array_unref(dirs);
         }, "_get_all_applications_dirs");
}


void monitor_callback(GFileMonitor* monitor, GFile* file, GFile* other_file,
                              GFileMonitorEvent event_type, gpointer data)
{
}


void test_append_monitor()
{
    Test({
         GPtrArray* desktop_monitors = g_ptr_array_new_with_free_func(g_object_unref);
         GPtrArray* dirs = _get_all_applications_dirs();
         append_monitor(desktop_monitors, dirs, G_CALLBACK(monitor_callback));
         g_ptr_array_unref(dirs);
         g_ptr_array_unref(desktop_monitors);
         }, "append_monitor");
}


void test_desktop_info()
{
    // also testing _update_items
    Test({
         struct DesktopInfo* i = desktop_info_create("test", ADDED);
         desktop_info_destroy(i);
         }, "desktop info create and destroy");
}


void test__update_autostart()
{
    // not use the original _update_autostart, just skip the
    // js_post_message_simply function.
    char* data = g_strdup("test");
    Test({
         _update_autostart(data);
    }, "_update_autostart");
    g_free(data);
}


void test_desktop_monitor_callback()
{
    Test({
         GFile* f = g_file_new_for_path("/usr/share/applications/firefox.desktop");
         desktop_monitor_callback(NULL, NULL, f, G_FILE_MONITOR_EVENT_MOVED, NULL);
         desktop_monitor_callback(NULL, f, NULL, G_FILE_MONITOR_EVENT_DELETED, NULL);
         desktop_monitor_callback(NULL, f, NULL, G_FILE_MONITOR_EVENT_CHANGES_DONE_HINT, NULL);
         g_object_unref(f);
         }, "desktop_monitor_callback");
}


void test_autostart_monitor_callback()
{
    Test({
         GFile* f = g_file_new_for_path("/usr/share/applications/firefox.desktop");
         autostart_monitor_callback(NULL, NULL, f, G_FILE_MONITOR_EVENT_MOVED, NULL);
         autostart_monitor_callback(NULL, f, NULL, G_FILE_MONITOR_EVENT_DELETED, NULL);
         autostart_monitor_callback(NULL, f, NULL, G_FILE_MONITOR_EVENT_CHANGES_DONE_HINT, NULL);
         g_object_unref(f);
         }, "autostart_monitor_callback");
}

void monitor_test()
{
    // comment js_post_message_simply or something like that before testing
    // backend memory is convenient.

    /* test_get_all_applications_dirs(); */
    /* test_append_monitor(); */
    test_desktop_info();
    /* test__update_autostart(); */
    /* test_desktop_monitor_callback(); */
    /* test_autostart_monitor_callback(); */
}
#endif

