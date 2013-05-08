#ifdef __DUI_DEBUG

#include <X11/XKBlib.h>
#include <gtk/gtk.h>
#include <glib.h>
#include <X11/X.h>
#include "test.h"
#include "background_util.h"
#include "inotify_item.h"

int TEST_MAX_COUNT = 100000;
int TEST_MAX_MEMORY = 100000;

void test_inotify()
{
    Test({
        g_assert(FALSE == desktop_file_filter("snyh.txt"));
        g_assert(TRUE == desktop_file_filter(".snyh.txt"));
        g_assert(TRUE == desktop_file_filter("snyh.txt~"));
    }, "desktop_file_filter");
    Test({
        trash_changed();
    }, "trash_changed");

    Test({
        GFile *f = g_file_new_for_path("~/deepin/test/desktop_test/bg.png");
        _add_monitor_directory(f);
        g_free(f);
    }, " _add_monitor_directory");

    Test({
        GFile *old_f = g_file_new_for_path("~/deepin/test/desktop_test/bg.png");
        GFile *new_f = g_file_new_for_path("~/deepin/test/desktop_test/bg.png");
        handle_rename(old_f, new_f);
    }, "handle_rename");
    
}

void test_dbus()
{
     /*Test({ */
         /*call_dbus("com.deepin.dde.desktop", "FocusChanged", FALSE); */
     /*}, "desktop_dbus"); */
}

void test_background()
{
    Test({
        setup_background_window();
    }, "setup_background_window");
}

void test_background_util()
{
    // _update_rootpmap
    GdkScreen *screen = NULL;
    GdkDisplay *display = NULL;
    
    screen = gdk_screen_get_default();
    gint number = gdk_screen_get_number(screen);
    gint width = gdk_screen_get_width(screen);
    gint height = gdk_screen_get_display(screen);
    display = XOpenDisplay(gdk_display_get_name(gdk_screen_get_display(screen)));
    Pixmap pixmap = XCreatePixmap (display, RootWindow(display, number), width, height, DefaultDepth(display, number)); 
    Test({
        _update_rootpmap(pixmap);
    }, "_update_rootpmap");

    gdk_display_close(display);
    XCloseDisplay(display);

    // on_tick
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

    xfade_data_t *data = g_new0(xfade_data_t, 1);
    Test({
        on_tick(data);
    }, "on_tick");
    g_free(data);

    // get_xformed_gdk_pixbuf 
    gchar *path = "/home/yjq/deepin/test/desktop_test/bg.png";
    Test({
        get_xformed_gdk_pixbuf(path);
    }, "get_xformed_gdk_pixbuf");
    g_free(path);

    // on_bg_duration_tick 
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
        const char* cur_pict = g_settings_get_string (setting, BG_CURRENT_PICT);
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
}

void test_other()
{
}

void desktop_test()
{
    /* test inotify successful.*/
    //test_inotify();
    test_dbus();
    test_background();
    test_background_util();
    test_other();
}

#endif
