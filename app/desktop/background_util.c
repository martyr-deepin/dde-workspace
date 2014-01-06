/**
 * Copyright (c) 2011 ~ 2013 Deepin, Inc.
 *               2011 ~ 2013 jouyouyun
 *
 * Author:      jouyouyun <jouyouwen717@gmail.com>
 * Maintainer:  jouyouyun <jouyouwen717@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, see <http://www.gnu.org/licenses/>.
 **/

#include <X11/X.h>
#include <gdk/gdk.h>
#include <gdk/gdkx.h>
#include <gdk-pixbuf/gdk-pixbuf.h>
#include <cairo.h>
#include <cairo-xlib.h>
#include <gtk/gtk.h>
#include <gio/gio.h>

#include "background_util.h"
#include "jsextension.h"
#include "utils.h"

#define USEC_PER_SEC 1000000.0 // microseconds per second
#define MSEC_PER_SEC 1000.0    // milliseconds per second
#define TIME_PER_FRAME  (1.0/BG_FPS)  // the interval between contingent frames
#define ALPHA_THRESHOLD 0.9  //if alpah > this_value, the fading process is deemed to be completed.

PRIVATE GSettings *Settings;

PRIVATE gulong gsettings_xfade_interval;
PRIVATE BgDrawMode gsettings_draw_mode;

/*PRIVATE gchar *cur_pict_uri;*/

//PRIVATE const gchar* bg_props[2] = {"_XROOTPMAP_ID","ESETROOT_PMAP_ID"};
PRIVATE const gchar *bg_props[1] = {"_XROOTPMAP_ID"};
PRIVATE Atom bg1_atom;
//PRIVATE Atom bg2_atom;
PRIVATE Atom pixmap_atom;

PRIVATE Display *display;
PRIVATE Window root;
PRIVATE int default_screen;
PRIVATE int root_depth;
PRIVATE Visual *root_visual;
PRIVATE int root_width;
PRIVATE int root_height;

PRIVATE GdkScreen *gdk_screen;
PRIVATE GdkWindow *background_window;

PRIVATE Pixmap current_rootpmap = None;

guint cross_timeout_id = 0; //cross-fade-interval

/*
 * all the time are in seconds.
 */
typedef struct _xfade_data {
    //all in seconds.
    gdouble     start_time;
    gdouble     total_duration;
    gdouble     interval;

    cairo_surface_t    *fading_surface;
    GdkPixbuf          *end_pixbuf;
    gdouble             alpha;

    Pixmap              pixmap;
} xfade_data_t;

PRIVATE void _update_rootpmap (Pixmap pm);
PRIVATE void initial_setup(GSettings *settings);
PRIVATE void bg_settings_current_picture_changed (GSettings *settings,
        gchar *key, gpointer user_data);
PRIVATE void bg_settings_cross_fade_interval_changed (GSettings *settings,
        gchar *key, gpointer user_data);
PRIVATE void bg_settings_draw_mode_changed (GSettings *settings,
        gchar *key, gpointer user_data);
PRIVATE GdkFilterReturn expose_cb (GdkXEvent *xevent, GdkEvent *event,
                                   gpointer data);
PRIVATE void screen_size_changed_cb (GdkScreen *screen, gpointer user_data);

PRIVATE void draw_background (xfade_data_t *fade_data);
PRIVATE const char *get_current_picture_path ();
PRIVATE gdouble get_current_time (void);
static inline Pixmap get_previous_background (void);
PRIVATE cairo_surface_t *get_surface(Pixmap pixmap);
PRIVATE GdkPixbuf *get_xformed_gdk_pixbuf (const char *pict_path);
PRIVATE void free_fade_data (xfade_data_t *fade_data);

PRIVATE gboolean on_tick (gpointer user_data);
PRIVATE void on_finished (gpointer user_data);
PRIVATE void start_cross_timer(void);
PRIVATE void remove_cross_timer(void);

DEEPIN_EXPORT void
bg_util_init (GdkWindow *bg_window)
{
    static gboolean __init__ = FALSE;

    if (__init__ == FALSE) {
        __init__ = TRUE;

        Settings = g_settings_new(BG_SCHEMA_ID);
        /*cur_pict_uri = g_settings_get_string(settings, BG_CURRENT_PICT);*/

        background_window = bg_window;
        display = GDK_DISPLAY_XDISPLAY(gdk_display_get_default());

        bg1_atom = gdk_x11_get_xatom_by_name(bg_props[0]);
        //bg2_atom = gdk_x11_get_xatom_by_name(bg_props[1]);
        pixmap_atom = gdk_x11_get_xatom_by_name ("PIXMAP");

        root = DefaultRootWindow(display);
        default_screen = DefaultScreen(display);
        root_depth = DefaultDepth(display, default_screen);
        root_visual = DefaultVisual(display, default_screen);
        root_width = DisplayWidth(display, default_screen);
        root_height = DisplayHeight (display, default_screen);

        gdk_window_move_resize(background_window,
                               0, 0, root_width, root_height);
        gdk_screen = gdk_screen_get_default();

        g_signal_connect (Settings, "changed::current-picture",
                          G_CALLBACK(bg_settings_current_picture_changed), NULL);
        g_signal_connect (Settings, "changed::cross-fade-interval",
                          G_CALLBACK(bg_settings_cross_fade_interval_changed), NULL);
        g_signal_connect (Settings, "changed::draw-mode",
                          G_CALLBACK(bg_settings_draw_mode_changed), NULL);

        gdk_window_add_filter(background_window, expose_cb, background_window);
    }
}

PRIVATE void
bg_settings_current_picture_changed (GSettings *settings,
                                     gchar *key, gpointer user_data)
{
    /*cur_pict_uri = g_settings_get_string(settings, key);*/
    NOUSED(settings);
    NOUSED(key);
    NOUSED(user_data);
    remove_cross_timer();
    start_cross_timer();
}

PRIVATE void
bg_settings_cross_fade_interval_changed (GSettings *settings,
        gchar *key, gpointer user_data)
{
    NOUSED(key);
    NOUSED(user_data);
    gsettings_xfade_interval = g_settings_get_int(settings,
                               BG_XFADE_INTERVAL);
    /*remove_cross_timer();*/
    /*start_cross_timer();*/
}

PRIVATE void
bg_settings_draw_mode_changed (GSettings *settings,
                               gchar *key, gpointer user_data)
{
    NOUSED(key);
    NOUSED(user_data);
    gsettings_draw_mode = g_settings_get_enum(Settings, BG_DRAW_MODE);
}

PRIVATE GdkFilterReturn
expose_cb (GdkXEvent *xevent, GdkEvent *event, gpointer data)
{
    NOUSED(event);
    NOUSED(data);

    //At least first running desktop and suspend/resume will trigger expose event
    if (((XEvent *)xevent)->type == Expose) {
        initial_setup (Settings);
    }

    return GDK_FILTER_CONTINUE;
}

PRIVATE void
start_cross_timer(void)
{
    xfade_data_t *fade_data = g_slice_new (xfade_data_t);

    Pixmap prev_pixmap = get_previous_background();
    gdk_error_trap_push ();

    if (prev_pixmap == None) {
        prev_pixmap = XCreatePixmap(display, root,
                                    root_width, root_height, root_depth);
        _update_rootpmap (prev_pixmap);
    }

    gdk_error_trap_pop_ignored();

    fade_data->pixmap = prev_pixmap;
    fade_data->fading_surface = get_surface(prev_pixmap);
    fade_data->alpha = 0;
    char *cur_pict = get_current_picture_path();
    fade_data->end_pixbuf = get_xformed_gdk_pixbuf(cur_pict);
    fade_data->total_duration = gsettings_xfade_interval / MSEC_PER_SEC;
    fade_data->interval = TIME_PER_FRAME;
    fade_data->start_time = get_current_time();
    g_free (cur_pict);

    GSource *source = g_timeout_source_new (fade_data->interval * MSEC_PER_SEC);
    g_source_set_callback(source, (GSourceFunc)on_tick,
                          fade_data, (GDestroyNotify)on_finished);
    cross_timeout_id = g_source_attach(source, g_main_context_default());
}

static inline Pixmap
get_previous_background (void)
{
    return current_rootpmap;
}

PRIVATE void
_update_rootpmap (Pixmap pm)
{
    // avoid unnecessary updates
    if ( (pm == None) || (pm == current_rootpmap) ) {
        return;
    }

    current_rootpmap = pm;

    gdk_error_trap_push();
    XChangeProperty(display, root, bg1_atom, pixmap_atom,
                    32, PropModeReplace, (unsigned char *)&pm, 1);
    //XChangeProperty (display, root, bg2_atom, pixmap_atom,
    //                 32, PropModeReplace, (unsigned char*)&pm, 1);
    XFlush (display);
    gdk_error_trap_pop_ignored ();
}

/*
 *      create a cairo surface from a pixmap. this is where
 *      we're drawing on
 *      NOTE: @pixmap should not be None.
 *      TODO: we assume that @pixmap is the same size as the
 *            root_window. if that's not tree, scale it.
 */
PRIVATE cairo_surface_t *
get_surface(Pixmap pixmap)
{
    cairo_surface_t *cs = NULL;
    cs = cairo_xlib_surface_create (display, pixmap,
                                    root_visual,
                                    root_width, root_height);

    return cs;
}

PRIVATE const char *
get_current_picture_path (void)
{
    char *cur_pict_uri = g_settings_get_string(Settings, BG_CURRENT_PICT);
    const gchar *cur_path = g_filename_from_uri (cur_pict_uri, NULL, NULL);
    g_free (cur_pict_uri);

    return cur_path;
}

PRIVATE gdouble
get_current_time (void)
{
    double timestamp;
    GTimeVal now;

    g_get_current_time(&now);
    timestamp = ((USEC_PER_SEC * now.tv_sec) + now.tv_usec) / USEC_PER_SEC;

    return timestamp;
}

PRIVATE gboolean
on_tick (gpointer user_data)
{
    xfade_data_t *fade_data = (xfade_data_t *)user_data;
    gdouble cur_time;
    cur_time = get_current_time();

    fade_data->alpha = (cur_time - fade_data->start_time) / fade_data->total_duration;
    fade_data->alpha = CLAMP(fade_data->alpha, 0.0, 1.0);

    draw_background(fade_data);

    // 'coz fade_data->alpha is a rough value
    if(fade_data->alpha >= ALPHA_THRESHOLD) {
        return FALSE;
    }

    return TRUE;
}

PRIVATE void
on_finished (gpointer user_data)
{
    xfade_data_t *fade_data = (xfade_data_t *) user_data;

    fade_data->alpha = 1.0;

    draw_background (fade_data);

    free_fade_data (fade_data);
}

/*
 *    compositing two cairo surfaces.
 *    use double buffering
 */
PRIVATE void
draw_background (xfade_data_t *fade_data)
{
    gdk_window_flush(background_window);
    cairo_t *cr;
    //draw on a pixmap
    cr = cairo_create (fade_data->fading_surface);
    gdk_cairo_set_source_pixbuf (cr, fade_data->end_pixbuf, 0, 0);
    cairo_paint_with_alpha (cr, fade_data->alpha);
    cairo_destroy (cr);
    //draw the pixmap on background window
    cr = gdk_cairo_create (background_window);
    cairo_set_source_surface (cr, fade_data->fading_surface, 0, 0);
    cairo_paint (cr);
    cairo_destroy (cr);
    gdk_window_flush(background_window);
}

/*
 *      free fade_data and its fields.
 */
PRIVATE void
free_fade_data (xfade_data_t *fade_data)
{
    cairo_surface_destroy (fade_data->fading_surface);
    g_object_unref (fade_data->end_pixbuf);
    g_slice_free(xfade_data_t, fade_data);
}

PRIVATE void
remove_cross_timer(void)
{
    if (cross_timeout_id) {
        g_source_remove(cross_timeout_id);
        cross_timeout_id = 0;
    }
}

/*
 * FIXME: screen_size_changed_cb and initial_setup
 * have a lot of duplicated function.
 */
PRIVATE void
initial_setup(GSettings *settings)
{
    static gboolean is_initialized = FALSE;

    if (is_initialized) {
        is_initialized = TRUE;

        gsettings_xfade_interval = g_settings_get_int(settings,
                                   BG_XFADE_INTERVAL);
        gsettings_draw_mode = g_settings_get_enum (settings, BG_DRAW_MODE);
    }

    /*
     *  don't remove following comments:
     *  to keep pixmap resource available
    */
    //XSetCloseDownMode (display, RetainPermanent);

    /*
     *  no previous background, no cross fade effect.
     *  this is most likely the situation when we first start up.
     *  resolution changed.
     */
    //since we now call initial setup in every expose event.
    Pixmap prev_pixmap = get_previous_background();
    gdk_error_trap_push ();

    if (prev_pixmap != None) {
        XFreePixmap (display, prev_pixmap);
    }

    gdk_error_trap_pop_ignored ();

    Pixmap new_pixmap = XCreatePixmap (display, root,
                                       root_width, root_height,
                                       root_depth);
    _update_rootpmap (new_pixmap);

    char *cur_pict = get_current_picture_path();
    GdkPixbuf *pb = get_xformed_gdk_pixbuf (cur_pict);
    g_free(cur_pict);

    xfade_data_t *fade_data = g_slice_new(xfade_data_t);

    fade_data->pixmap = new_pixmap;
    fade_data->fading_surface = get_surface (new_pixmap);
    fade_data->end_pixbuf = pb;
    fade_data->alpha = 1.0;

    draw_background (fade_data);
    cairo_pattern_t *pattern;
    pattern = cairo_pattern_create_for_surface (fade_data->fading_surface);
    gdk_window_set_background_pattern (background_window, pattern);
    cairo_pattern_destroy (pattern);
    free_fade_data (fade_data);

    return;
}

PRIVATE GdkPixbuf *
get_xformed_gdk_pixbuf (const char *pict_path)
{
    GError *error = NULL;
    GdkPixbuf *_pixbuf = NULL;
    GdkPixbuf *_xformed_pixbuf = NULL;

    if (pict_path == NULL) {
        g_warning("get_xformed_gdk_pixbuf pict path null...");
        return NULL;
    }

    g_warning("pict path: %s", pict_path);
    _pixbuf = gdk_pixbuf_new_from_file (pict_path, &error);

    if (error != NULL) {
        _pixbuf = gdk_pixbuf_new_from_file (BG_DEFAULT_PICTURE, NULL);
    }

    int w0, h0;
    w0 = gdk_pixbuf_get_width (_pixbuf);
    h0 = gdk_pixbuf_get_height (_pixbuf);
    gboolean has_alpha;
    has_alpha = gdk_pixbuf_get_has_alpha (_pixbuf);
    int x, y;
    int w, h;

    switch (gsettings_draw_mode) {
            //NOTE: GDK_INTERP_TILES has nothing to do with tiling.
        case DRAW_MODE_TILING:
            _xformed_pixbuf = gdk_pixbuf_new (GDK_COLORSPACE_RGB,
                                              has_alpha, 8,
                                              root_width, root_height);

            for (x = 0; x < root_width; x += w0) {
                if (x + w0 <= root_width) {
                    w = w0;
                } else {
                    w = root_width - x;
                }

                for (y = 0; y < root_height; y += h0) {
                    if (y + h0 <= root_height) {
                        h = h0;
                    } else {
                        h = root_height - y;
                    }

                    gdk_pixbuf_copy_area (_pixbuf,
                                          0, 0, w, h,
                                          _xformed_pixbuf,
                                          x, y);
                }
            }

            break;

            //default to draw scaling
        case DRAW_MODE_SCALING:
        default:
            _xformed_pixbuf = gdk_pixbuf_scale_simple (_pixbuf,
                              root_width,
                              root_height,
                              GDK_INTERP_BILINEAR);
            break;
    }

    //TODO: generate a gaussian picture here.
    g_object_unref (_pixbuf);

    return _xformed_pixbuf;
}

PRIVATE void
screen_size_changed_cb (GdkScreen *screen, gpointer user_data)
{
    NOUSED(user_data);
    //remove early to avoid fatal X errors
    int current_root_width = gdk_screen_width();
    int current_root_height = gdk_screen_height();

    if (current_root_width != root_width ||
            current_root_height != root_height) {
        root_width = current_root_width;
        root_height = current_root_height;
    } else {
        return;
    }

    remove_cross_timer();

    root_width = gdk_screen_get_width(screen);
    root_height = gdk_screen_get_height(screen);
    gdk_window_move_resize(background_window, 0, 0, root_width, root_height);

    char *current_picture = get_current_picture_path ();
    //g_debug ("screen_size_changed_cb: end set string");
    //start_gaussian_helper (current_picture);
    //g_debug ("screen_size_changed_cb: end helper");

    GdkPixbuf *pb = get_xformed_gdk_pixbuf (current_picture);
    g_free(current_picture);

    g_assert (pb != NULL);

    /*
     *  this is similar to initial setup. but we need to
     *  free previous pixmap first.
     */
    Pixmap prev_pixmap = get_previous_background();
    gdk_error_trap_push ();

    if (prev_pixmap != None) {
        XFreePixmap (display, prev_pixmap);
    }

    gdk_error_trap_pop_ignored ();

    Pixmap new_pixmap = XCreatePixmap (display, root,
                                       root_width, root_height,
                                       root_depth);

    _update_rootpmap (new_pixmap);

    xfade_data_t *fade_data = g_slice_new(xfade_data_t);

    fade_data->pixmap = new_pixmap;
    fade_data->fading_surface = get_surface (new_pixmap);
    fade_data->end_pixbuf = pb;
    fade_data->alpha = 1.0;

    cairo_pattern_t *pattern;
    pattern = cairo_pattern_create_for_surface (fade_data->fading_surface);
    gdk_window_set_background_pattern (background_window, pattern);
    cairo_pattern_destroy (pattern);

    draw_background (fade_data);

    free_fade_data (fade_data);
}

DEEPIN_EXPORT void
bg_util_connect_screen_signals (GdkWindow *bg_window)
{
    // xrandr screen resolution handling
    g_signal_connect (gdk_screen, "size-changed",
                      G_CALLBACK (screen_size_changed_cb), bg_window);
    g_signal_connect (gdk_screen, "monitors-changed",
                      G_CALLBACK (screen_size_changed_cb), bg_window);
}

DEEPIN_EXPORT void
bg_util_disconnect_screen_signals (GdkWindow *bg_window)
{
    g_signal_handlers_disconnect_by_func (gdk_screen,
                                          G_CALLBACK (screen_size_changed_cb), bg_window);
}
