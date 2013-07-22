#include "desktop_test.h"

void test_background_util()
{
	setup_fixture();


	Test({


	},"test_");
    typedef struct _xfade_data
    {
        //all in seconds.
        gdouble start_time;
        gdouble total_duration;
        gdouble interval;

        cairo_surface_t* fading_surface;
        GdkPixbuf* end_pixbuf;
        gdouble alpha;

        Pixmap pixmap;
    } xfade_data_t;


    GdkScreen *screen = NULL;
    Display *display = NULL;

    screen = gdk_screen_get_default();
    gint number = gdk_screen_get_number(screen);
    gint width = gdk_screen_get_width(screen);
    gint height = gdk_screen_get_height(screen);
    display = XOpenDisplay(gdk_display_get_name(gdk_screen_get_display(screen)));
    Pixmap pixmap = XCreatePixmap (display, RootWindow(display, number), width, height, DefaultDepth(display, number));

    cairo_surface_t *get_surface(Pixmap);
    xfade_data_t *data = g_new0(xfade_data_t, 1);
    data->pixmap = pixmap;
    data->fading_surface = get_surface(pixmap);
    data->end_pixbuf = gdk_pixbuf_new_from_file(file1, NULL);

    // _update_rootpmap Successful.
    /* extern void _update_rootpmap(); */
    /* Test({ */
    /*     _update_rootpmap(pixmap); */
    /* }, "_update_rootpmap"); */

    // on_tick Successful.
    /* extern void on_tick(xfade_data_t *data); */
    /* Test({ */
    /*     on_tick(data); */
    /* }, "on_tick"); */

    // draw_background Successful.
    /* extern void draw_background(xfade_data_t *data); */
    /* Test({ */
    /*     draw_background(data); */
    /* }, "draw_background"); */

    g_object_unref(data->end_pixbuf);
    cairo_surface_destroy(data->fading_surface);
    g_free(data);

    // remove_timers Successful.
    /* extern void remove_timers(); */
    /* Test({ */
    /*     remove_timers(); */
    /* }, "remove_timers"); */

    // get_current_picture_path Successful.
    /* extern const char *get_current_picture_path(); */
    /* Test({ */
    /*     get_current_picture_path(); */
    /* }, "get_current_picture_path"); */

    // get_next_picture_index Successful.
    /* extern guint get_next_picture_index(); */
    /* Test({ */
    /*     get_next_picture_index(); */
    /* }, "get_next_picture_index"); */

    // get_next_picture_path Successful.
    /* extern const char *get_next_picture_path(); */
    /* Test({ */
    /*     get_next_picture_path(); */
    /* }, "get_next_picture_path"); */

    // get_xformed_gdk_pixbuf  Succcessful.
    extern GdkPixbuf *get_xformed_gdk_pixbuf(const char *path);
    /* Test({ */
    /*     const gchar *path = get_current_picture_path(); */
    /*     GdkPixbuf *pixbuf = get_xformed_gdk_pixbuf(path); */
    /*     g_object_unref(pixbuf); */
    /* }, "get_xformed_gdk_pixbuf"); */

    // on_bg_duration_tick Successful.
    extern gboolean on_bg_duration_tick(gpointer data);
    Test({
        on_bg_duration_tick(NULL);
    }, "on_bg_duration_tick");

    // bg_settings_picture_uri_changed
    GSettings *setting = NULL;
    setting = g_settings_new(BG_SCHEMA_ID);

    // haven't test.
    /* Test({ */
    /*     initial_setup(setting); */
    /* }, "initial_setup"); */

    // This function have never used.
    /* extern void bg_settings_picture_uri_changed(GSettings *setting, const gchar *key, gpointer data); */
    /* Test({ */
    /*     bg_settings_picture_uri_changed(setting, BG_PICTURE_URI, NULL); */
    /* }, "bg_settings_picture_uri_changed"); */

    // Test bg_settings_picture_uris_changed Successful.
    /* extern void bg_settings_picture_uris_changed (GSettings *settings, gchar *key, gpointer user_data); */
    /* Test({ */
    /*     bg_settings_picture_uris_changed(setting, BG_PICTURE_URIS, NULL); */
    /* }, "bg_settings_picture_uris_changed"); */

    // Succeessful.
    /* extern void bg_settings_bg_duration_changed (GSettings *, const gchar *, gpointer); */
    /* Test({ */
    /*     bg_settings_bg_duration_changed (setting, BG_BG_DURATION, NULL); */
    /* }, "bg_settings_bg_duration_changed"); */

    // Successful.
    /* extern void bg_settings_xfade_manual_interval_changed (GSettings *, const gchar *, gpointer); */
    /* Test({ */
    /*     bg_settings_xfade_manual_interval_changed (setting, BG_XFADE_MANUAL_INTERVAL, NULL); */
    /* }, "bg_settings_xfade_manual_interval_changed "); */

    // Successful.
    /* extern void bg_settings_xfade_auto_interval_changed(GSettings *, const gchar *, gpointer); */
    /* Test({ */
    /*     bg_settings_xfade_auto_interval_changed(setting, BG_XFADE_AUTO_INTERVAL, NULL); */
    /* }, "bg_settings_xfade_auto_interval_changed"); */

    // Successful.
    /* extern void bg_settings_xfade_auto_mode_changed (GSettings *, const gchar *, gpointer); */
    /* Test({ */
    /*     bg_settings_xfade_auto_mode_changed (setting, BG_XFADE_AUTO_MODE, NULL); */
    /* }, "bg_settings_xfade_auto_mode_changed "); */

    // Successful.
    /* extern void bg_settings_draw_mode_changed (GSettings *, const gchar *, gpointer); */
    /* Test({ */
    /*     bg_settings_draw_mode_changed (setting, BG_DRAW_MODE, NULL); */
    /* }, "bg_settings_draw_mode_changed "); */

    // Successful.
    /* extern void register_account_service_background_path (const gchar *); */
    /* Test({ */
    /*     char* cur_pict = g_settings_get_string (setting, BG_CURRENT_PICT); */
    /*     register_account_service_background_path (cur_pict); */
    /*     g_free(cur_pict); */
    /* }, "register_account_service_background_path "); */

    // Successful.
    /* extern void bg_settings_current_picture_changed (GSettings *, const gchar *, gpointer); */
    /* Test({ */
    /*     bg_settings_current_picture_changed (setting, BG_CURRENT_PICT, NULL); */
    /* }, "bg_settings_current_picture_changed"); */

    GdkPixbuf *get_xformedgdk_pixbuf(const char *path);
    Test({
        GdkPixbuf *pixbuf = get_xformed_gdk_pixbuf(file1);
        g_assert(pixbuf != NULL);
        g_object_unref(pixbuf);
    }, "get_xformed_gdk_pixbuf");

    extern void screen_size_changed_cb(GdkScreen *, gpointer);
    Test({
        GdkScreen *screen = gdk_screen_get_default();
        screen_size_changed_cb(screen, NULL);
    }, "screen_size_changed_cb ");

    g_object_unref(setting);

    // setup_background_timer
    void setup_background_timer();
    Test({
        setup_background_timer();
    }, "setup_background_timer");

    // Error: trance trap!
    void setup_crossfade_timer();
    Test({
        setup_crossfade_timer();
    }, "setup_crossfade_timer");

    // Error: trance trap!
    void setup_timers();
    Test({
        setup_timers();
    }, "setup_timers");

    // parse_picture_uris (gchar * pic_uri)
    void parse_picture_uris (gchar * pic_uri);
    Test({
        parse_picture_uris(file1);
    }, "parse_picture_uris");

	tear_down_fixture();

}