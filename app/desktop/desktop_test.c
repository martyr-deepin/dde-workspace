#ifdef __DUI_DEBUG

#include <X11/XKBlib.h>
#include <gtk/gtk.h>
#include <glib.h>
#include <X11/X.h>
#include <JavaScriptCore/JSObjectRef.h>
#include "jsextension.h"
#include "test.h"
#include "background_util.h"
#include "inotify_item.h"

int TEST_MAX_COUNT = 100000;
int TEST_MAX_MEMORY = 100000;

const gchar *file1 = "~/Desktop/bg.png";
const gchar *file2 = "~/Desktop/bg2.png";

void test_inotify()
{
    void trash_changed();
    Test({
        g_assert(FALSE == desktop_file_filter("snyh.txt"));
        g_assert(TRUE == desktop_file_filter(".snyh.txt"));
        g_assert(TRUE == desktop_file_filter("snyh.txt~"));
    }, "desktop_file_filter");
    Test({
        trash_changed();
    }, "trash_changed");

    void _add_monitor_directory(GFile *f);
    Test({
        GFile *f = g_file_new_for_path(file1);
        _add_monitor_directory(f);
        g_object_unref(f);
    }, " _add_monitor_directory");
    
    void install_monitor();
    Test({
        install_monitor();
    }, "install_monitor");


    GFile *old_f = g_file_new_for_path(file1);
    GFile *new_f = g_file_new_for_path(file2);

    void handle_rename(GFile *, GFile *);
    Test({
        handle_rename(old_f, new_f);
    }, "handle_rename");

    void handle_delete(GFile* f);
    Test({
        GFile *f = g_file_new_for_path(file1);
        handle_delete(f);
    }, "handle_delete");

    void handle_update(GFile* f);
    Test({
        GFile *f = g_file_new_for_path(file1);
        handle_update(f);
    }, "handle_update");

    void handle_new(GFile* f);
    Test({
        GFile *f = g_file_new_for_path(file1);
        handle_new(f);
    }, "handle_new");

    void _remove_monitor_directory(GFile* f);
    Test({
        _remove_monitor_directory(old_f);
    }, "_remove_monitor_directory");

    void _inotify_poll();
    Test({
        _inotify_poll();   
    }, "_inotify_poll");

    g_object_unref(old_f);
    g_object_unref(new_f);
}

void test_dbus()
{
     /*Test({ */
         /*call_dbus("com.deepin.dde.desktop", "FocusChanged", FALSE); */
     /*}, "desktop_dbus"); */
}

void test_background()
{
    //void setup_background_window();
    void set_wmspec_desktop_hint(GdkWindow *);
    GdkWindow* _background_window = NULL;
    Test({
        GdkWindowAttr attributes;
        attributes.width = 0;
        attributes.height = 0;
        attributes.window_type = GDK_WINDOW_CHILD;
        attributes.wclass = GDK_INPUT_OUTPUT;
        attributes.event_mask = GDK_EXPOSURE_MASK;

        _background_window = gdk_window_new(NULL, &attributes, 0);
        set_wmspec_desktop_hint(_background_window);

        bg_util_init (_background_window);
        bg_util_connect_screen_signals (_background_window);

        gdk_window_show_unraised (_background_window);

        gdk_window_destroy(_background_window);
    }, "setup_background_window");
}

void test_background_util()
{   
    typedef struct _xfade_data
    {
        //all in seconds.
        gdouble	start_time;
        gdouble	total_duration;
        gdouble	interval;

        cairo_surface_t*	fading_surface;
        GdkPixbuf*		end_pixbuf;
        gdouble		alpha;

        Pixmap		pixmap;
    } xfade_data_t;
   
    // _update_rootpmap
    void _update_rootpmap();

    GdkScreen *screen = NULL;
    Display *display = NULL;
    
    screen = gdk_screen_get_default();
    gint number = gdk_screen_get_number(screen);
    gint width = gdk_screen_get_width(screen);
    gint height = gdk_screen_get_height(screen);
    display = XOpenDisplay(gdk_display_get_name(gdk_screen_get_display(screen)));
    Pixmap pixmap = XCreatePixmap (display, RootWindow(display, number), width, height, DefaultDepth(display, number)); 
    Test({
        _update_rootpmap(pixmap);
    }, "_update_rootpmap");

    //gdk_display_close(display);
    //XCloseDisplay(display);

    // on_tick
    void on_tick(xfade_data_t *data);
    cairo_surface_t *get_surface(Pixmap);
    
    xfade_data_t *data = g_new0(xfade_data_t, 1);
    data->pixmap = pixmap;
    data->fading_surface = get_surface(pixmap);
    data->end_pixbuf = gdk_pixbuf_new_from_file(file1, NULL);
    Test({
        on_tick(data);
    }, "on_tick");
    
    // draw_background
    void draw_background(xfade_data_t *data);
    draw_background(data);

    g_object_unref(data->end_pixbuf);
    cairo_surface_destroy(data->fading_surface);
    g_free(data);

    // remove_timers
    void remove_timers();
    remove_timers();

    // get_current_picture_path
    const char *get_current_picture_path();
    get_current_picture_path();

    // get_next_picture_index
    guint get_next_picture_index();
    get_next_picture_index();

    // get_next_picture_path
    const char *get_next_picture_path();
    get_next_picture_path();

    // get_xformed_gdk_pixbuf 
    GdkPixbuf *get_xformed_gdk_pixbuf(const char *path);

    Test({
        const gchar *path = file1;
        get_xformed_gdk_pixbuf(path);
    }, "get_xformed_gdk_pixbuf");

    // on_bg_duration_tick 
    gboolean on_bg_duration_tick(const gchar *path);
    void bg_settings_picture_uri_changed(GSettings *setting, const gchar *key, gpointer data);
    void bg_settings_bg_duration_changed (GSettings *, const gchar *, gpointer);
    void bg_settings_xfade_manual_interval_changed (GSettings *, const gchar *, gpointer);
    void bg_settings_xfade_auto_interval_changed(GSettings *, const gchar *, gpointer);
    void bg_settings_xfade_auto_mode_changed (GSettings *, const gchar *, gpointer);
    void bg_settings_draw_mode_changed (GSettings *, const gchar *, gpointer);
    void bg_settings_current_picture_changed (GSettings *, const gchar *, gpointer);
    void register_account_service_background_path (const gchar *);
    void bg_settings_current_picture_changed (GSettings *, const gchar *, gpointer);
    void screen_size_changed_cb(GdkScreen *, gpointer);
    void initial_setup(GSettings *);
    void bg_util_init(GdkWindow *);
    void bg_settings_picture_uris_changed (GSettings *settings, gchar *key, gpointer user_data);

    Test({
        gpointer data = NULL;
        on_bg_duration_tick(data);
    }, "on_bg_duration_tick");

    // bg_settings_picture_uri_changed 
    GSettings *setting = NULL;
    setting = g_settings_new(BG_SCHEMA_ID);
    Test({
        gpointer data = NULL;
        bg_settings_picture_uri_changed(setting, BG_PICTURE_URI, data);
    }, "bg_settings_picture_uri_changed");

    // bg_settings_picture_uris_changed 
    Test({
        gpointer data = NULL;
        bg_settings_picture_uris_changed(setting, BG_PICTURE_URIS, data);
    }, "bg_settings_picture_uris_changed");

    Test({
        gpointer data = NULL;
        bg_settings_bg_duration_changed (setting, BG_BG_DURATION, data);
    }, "bg_settings_bg_duration_changed");

    Test({
        gpointer data = NULL;
        bg_settings_xfade_manual_interval_changed (setting, BG_XFADE_MANUAL_INTERVAL, data);
    }, "bg_settings_xfade_manual_interval_changed ");
    
    Test({
        gpointer data = NULL;
        bg_settings_xfade_auto_interval_changed(setting, BG_XFADE_AUTO_INTERVAL, data);
    }, "bg_settings_xfade_auto_interval_changed");

    Test({
        gpointer data = NULL;
        bg_settings_xfade_auto_mode_changed (setting, BG_XFADE_AUTO_MODE, data);
    }, "bg_settings_xfade_auto_mode_changed ");

    Test({
        gpointer data = NULL;
        bg_settings_draw_mode_changed (setting, BG_DRAW_MODE, data);
    }, "bg_settings_draw_mode_changed ");

    Test({
        char* cur_pict = g_settings_get_string (setting, BG_CURRENT_PICT);
        register_account_service_background_path (cur_pict);
        g_free(cur_pict);
    }, "register_account_service_background_path ");

    Test({
        gpointer data = NULL;
        bg_settings_current_picture_changed (setting, BG_CURRENT_PICT, data);
    }, "bg_settings_current_picture_changed");
    
    Test({
        GdkScreen *screen = gdk_screen_get_default();
        gpointer data = NULL;
        screen_size_changed_cb(screen, data);
        g_object_unref(screen);
    }, "screen_size_changed_cb ");

    Test({
        initial_setup(setting);
    }, "initial_setup");

    Test({
        GdkWindowAttr attributes;
        gint attributes_mask;

        attributes.x = 0;
        attributes.y = 0;
        attributes.width = 100;
        attributes.height = 100;
        attributes.wclass = GDK_INPUT_OUTPUT;
        attributes.window_type = GDK_WINDOW_CHILD;
        attributes.event_mask =  GDK_EXPOSURE_MASK | GDK_BUTTON_PRESS_MASK | 
        GDK_BUTTON_RELEASE_MASK | GDK_POINTER_MOTION_MASK | GDK_POINTER_MOTION_HINT_MASK;

        attributes_mask = GDK_WA_X | GDK_WA_Y | GDK_WA_VISUAL;
        GdkWindow *window = gdk_window_new (NULL, &attributes, attributes_mask);

        bg_util_init(window);
    }, "bg_util_init ");

    g_object_unref(setting);

    // setup_background_timer
    void setup_background_timer();
    Test({
        setup_background_timer();
    }, "setup_background_timer");

    // setup_crossfade_timer
    void setup_crossfade_timer();
    Test({
        setup_crossfade_timer();
    }, "setup_crossfade_timer");

    // setup_timers
    void setup_timers();
    Test({
        setup_timers();
    }, "setup_timers");

    // parse_picture_uris (gchar * pic_uri)
    void parse_picture_uris (gchar * pic_uri);
    Test({
        gchar *uri = "~/Desktop/bg.png";
        parse_picture_uris(uri);
    }, "parse_picture_uris");

    GdkPixbuf *get_xformedgdk_pixbuf(const char *path);
    Test({
        GdkPixbuf *pixbuf = get_xformed_gdk_pixbuf(file1);
        g_object_unref(pixbuf);
    }, "get_xformed_gdk_pixbuf");
 
}

void test_desktop()
{
    JSObjectRef desktop_get_desktop_entries();
    Test({
        desktop_get_desktop_entries();
    }, "desktop_get_desktop_entries");

    char* desktop_get_rich_dir_name(GFile* dir);
    Test({
        GFile *f = g_file_new_for_path("~/Desktop/.deepin_rich_dir_desktop_test");
        char *filename = desktop_get_rich_dir_name(f);
        g_free(filename);
    }, "desktop_get_rich_dir_name");

    void desktop_set_rich_dir_name(GFile* dir, const char* name);
    Test({
        GFile *f = g_file_new_for_path("~/Desktop/.deepin_rich_dir_desktop_test");
        desktop_set_rich_dir_name(f, "test");
    }, "desktop_set_rich_dir_name");

    char* desktop_get_rich_dir_icon(GFile* _dir);
    Test({
        GFile *f = g_file_new_for_path("~/Desktop/.deepin_rich_dir_desktop_test");
        char *filename = desktop_get_rich_dir_name(f);
        g_free(filename);
        g_object_unref(f);
    }, "desktop_get_rich_dir_icon");

    GFile* desktop_create_rich_dir(ArrayContainer fs);
    Test({
        ArrayContainer fs;
        desktop_create_rich_dir(fs);
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
        g_object_unref(screen);
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
}

void test_utils()
{
    typedef void Entry;

    void desktop_run_terminal();
    Test({
        desktop_run_terminal();
    }, "desktop_run_terminal");

    void desktop_run_deepin_settings(const char* mod);
    Test({
        desktop_run_deepin_settings("display");
    }, "desktop_run_deepin_settings");

    void desktop_run_deepin_software_center();
    Test({
        desktop_run_deepin_software_center();
    }, "desktop_run_deepin_software_center");

    void desktop_open_trash_can();
    Test({
        desktop_open_trash_can();
    }, "desktop_open_trash_can");

    Entry* desktop_get_home_entry();
    Test({
        Entry *entry = desktop_get_home_entry();
        g_object_unref(entry);
    }, "desktop_get_home_entry");

    Entry* desktop_get_computer_entry();
    Test({
        Entry *entry = desktop_get_computer_entry();
        g_object_unref(entry);
    }, "desktop_get_computer_entry");

    char* desktop_get_transient_icon (Entry* p1);
    Test({
        GFile *f = g_file_new_for_path(file1); 
        desktop_get_transient_icon((Entry *)f);
        g_object_unref(f);
    }, "desktop_get_transient_icon");
}

void test_other()
{
}

void desktop_test()
{
    /* test inotify successful.*/
    //test_inotify();
    
    //test_dbus();

    test_background();

    test_background_util();

    test_desktop();

    test_utils();
    
    test_other();
}

#endif
