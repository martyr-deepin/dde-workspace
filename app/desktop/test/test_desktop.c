#include "desktop_test.h"

void test_desktop()
{
	setup_fixture();


	Test({


	},"test_");

    JSObjectRef desktop_get_desktop_entries();
    Test({
        JSObjectRef desktop_get_desktop_entries();
    }, "desktop_get_desktop_entries");

    char* desktop_get_rich_dir_name(GFile* dir);
    Test({
        GFile *f = g_file_new_for_path(rich_dir);
        char *filename = desktop_get_rich_dir_name(f);
        g_free(filename);
        g_object_unref(f);
    }, "desktop_get_rich_dir_name");

    void desktop_set_rich_dir_name(GFile* dir, const char* name);
    Test({
        GFile *f = g_file_new_for_path(rich_dir);
        desktop_set_rich_dir_name(f, "test");
        g_object_unref(f);
    }, "desktop_set_rich_dir_name");

    char* desktop_get_rich_dir_icon(GFile* _dir);
    Test({
        GFile *f = g_file_new_for_path(rich_dir);
        char *filename = desktop_get_rich_dir_name(f);
        g_free(filename);
        g_object_unref(f);
    }, "desktop_get_rich_dir_icon");

    GFile* desktop_create_rich_dir(ArrayContainer fs);
    Test({
        ArrayContainer fs;
        GFile** _files = NULL;
        fs.data = _files;
        fs.num = 2;
        _files[0] = g_file_new_for_commandline_arg(app_0);
        _files[1] = g_file_new_for_commandline_arg(app_1);

        GPtrArray* array = g_ptr_array_new();

        for(size_t i=0; i<fs.num; i++) {
            if (G_IS_DESKTOP_APP_INFO(_files[i])) {
                g_ptr_array_add(array, g_file_new_for_commandline_arg(g_desktop_app_info_get_filename((GDesktopAppInfo*)_files[i])));
            } else {
                g_ptr_array_add(array, g_object_ref(_files[i]));
            }
        }
        ArrayContainer ret;
        ret.num = fs.num;
        ret.data = g_ptr_array_free(array, FALSE);

        GFile *f = desktop_create_rich_dir(ret);
        if (NULL != f)
            g_object_unref(f);
    }, "desktop_create_rich_dir");

    char* desktop_get_desktop_path();
    Test({
        char *path = desktop_get_desktop_path();
        g_free(path);
    }, "desktop_get_desktop_path");

    GFile* _get_useable_file(const char* basename);
    Test({
        GFile *f = _get_useable_file(file1);
        if(f != NULL)
            g_object_unref(f);
    }, "_get_useable_file");

    GFile* desktop_new_file();
    Test({
        GFile *f = desktop_new_file();
        if(NULL != f)
            g_object_unref(f);
    }, "desktop_new_file");

    GFile* desktop_new_directory();
    Test({
        GFile *f = desktop_new_directory();
        if (NULL != f)
            g_object_unref(f);
    }, "desktop_new_directory");


    void dock_config_changed(GSettings* settings, char* key, gpointer usr_data);
    Test({
        #define DOCK_SCHEMA_ID "com.deepin.dde.dock"
        GSettings *dock_gsettings = g_settings_new (DOCK_SCHEMA_ID);
        dock_config_changed(dock_gsettings, "changed::hide-mode", NULL);
        g_object_unref(dock_gsettings);
    }, "dock_config_changed");


    void desktop_config_changed(GSettings* settings, char* key, gpointer usr_data);
    Test({
        #define DESKTOP_SCHEMA_ID "com.deepin.dde.desktop"
        GSettings *desktop_gsettings = g_settings_new (DESKTOP_SCHEMA_ID);
        desktop_config_changed(desktop_gsettings, "changed::show-home-icon", NULL);
        g_object_unref(desktop_gsettings);
    }, "desktop_config_changed");

    gboolean desktop_get_config_boolean(const char* key_name);
    Test({
        desktop_get_config_boolean("changed::show-home-icon");
    }, "desktop_get_config_boolean");

    void screen_change_size(GdkScreen *screen, GdkWindow *w);
    Test({
        extern GtkWidget *container;
        GdkScreen *screen = gtk_window_get_screen(GTK_WINDOW(container));
        screen_change_size(screen, gtk_widget_get_window(container));
    }, "screen_change_size");

    void send_lost_focus();
    Test({
        send_lost_focus();
    }, "send_lost_focus");

    void send_get_focus();
    Test({
        send_get_focus();
    }, "send_lost_focus");

    void desktop_emit_webview_ok();
    Test({
        desktop_emit_webview_ok();
    }, "desktop_emit_webview_ok");

    // these functio used in other functions.
    /*void update_workarea_size(GSettings* dock_gsettings);*/
    /*GdkFilterReturn watch_workarea(GdkXEvent *gxevent, GdkEvent* event, gpointer user_data)*/
    /*void unwatch_workarea_changes(GtkWidget* widget)*/
    /*void watch_workarea_changes(GtkWidget* widget, GSettings* dock_gsettings)*/
	tear_down_fixture();

}