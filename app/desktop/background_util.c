/**
 * Copyright (c) 2011 ~ 2012 Deepin, Inc.
 *               2011 ~ 2012 hooke
 *
 * Author:      hooke
 * Maintainer:  hooke
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

#include <string.h>
#include <stdlib.h>
#include <unistd.h>

#include <X11/X.h>
#include <gdk-pixbuf/gdk-pixbuf.h>
#include <gdk/gdk.h>
#include <gdk/gdkx.h>
#include <cairo.h>
#include <cairo-xlib.h>
#include <gtk/gtk.h>
#include <gio/gio.h>

#include "background_util.h"
#include "jsextension.h"

#define USEC_PER_SEC 1000000.0 // microseconds per second
#define MSEC_PER_SEC 1000.0    // milliseconds per second
#define TIME_PER_FRAME  (1.0/BG_FPS)  // the interval between contingent frames
#define ALPHA_THRESHOLD 0.9  //if alpah > this_value, the fading process is deemed
                             //to be completed.

//
PRIVATE GPtrArray *picture_paths;               //an array of picture paths (strings).
//all picture paths are managed by picture_paths, this hashtable just references them.
PRIVATE GHashTable* picture_paths_ht;            //picture paths --> indices+1 in @picture_paths.
PRIVATE guint   picture_num;            //number of pictures in GPtrArray.
PRIVATE guint   picture_index;          // the next background picture.
//this is only used update current image in the gsettings
PRIVATE GSettings *Settings;
//connect to AccountService DBus. and register background path
PRIVATE GDBusProxy* AccountsProxy = NULL;

PRIVATE gulong  gsettings_background_duration;
PRIVATE gulong  gsettings_xfade_auto_interval; //use this time only when we use
                                               //multiple background pictures.
PRIVATE gulong  gsettings_xfade_manual_interval;
PRIVATE BgXFadeAutoMode gsettings_xfade_auto_mode;
PRIVATE BgDrawMode      gsettings_draw_mode;

//PRIVATE const gchar* bg_props[2] = {"_XROOTPMAP_ID","ESETROOT_PMAP_ID"};
PRIVATE const gchar* bg_props[1] = {"_XROOTPMAP_ID"};
PRIVATE Atom bg1_atom;
//PRIVATE Atom bg2_atom;
PRIVATE Atom pixmap_atom;

PRIVATE Display* display;
PRIVATE Window  root;
PRIVATE int     default_screen;
PRIVATE int     root_depth;
PRIVATE Visual* root_visual;
PRIVATE int     root_width;
PRIVATE int     root_height;

PRIVATE GdkScreen * gdk_screen;

PRIVATE GdkWindow* background_window;
PRIVATE Pixmap current_rootpmap = None; // track the current background pixmap XID.
                                       // to avoid unnecessary updates of "_XROOTPMAP_ID".

//global timeout_id to track in process timeoutout
PRIVATE guint   bg_timeout_id =0;       // background_duration
PRIVATE guint   auto_timeout_id = 0;    // xfade_auto_interval
PRIVATE guint   manual_timeout_id = 0;  // xfade_manual_interval
//

/*
 *      all the time are in seconds.
 */
typedef struct _xfade_data
{
    //all in seconds.
    gdouble     start_time;
    gdouble     total_duration;
    gdouble     interval;

    cairo_surface_t*    fading_surface;
    GdkPixbuf*          end_pixbuf;
    gdouble             alpha;

    Pixmap              pixmap;
} xfade_data_t;


PRIVATE void
_update_rootpmap (Pixmap pm)
{
    // avoid unnecessary updates
    if ((pm == None)||(pm == current_rootpmap))
        return ;
    current_rootpmap = pm;
    gdk_error_trap_push ();
    XChangeProperty (display, root, bg1_atom, pixmap_atom,
                     32, PropModeReplace, (unsigned char*)&pm, 1);
    //XChangeProperty (display, root, bg2_atom, pixmap_atom,
    //                 32, PropModeReplace, (unsigned char*)&pm, 1);
    XFlush (display);
    gdk_error_trap_pop_ignored ();
}


/*
 *    compositing two cairo surfaces.
 *    use double buffering
 */
PRIVATE void
draw_background (xfade_data_t* fade_data)
{
    gdk_window_flush(background_window);
    cairo_t* cr;
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
free_fade_data (xfade_data_t* fade_data)
{
    cairo_surface_destroy (fade_data->fading_surface);
    g_object_unref (fade_data->end_pixbuf);
    g_slice_free(xfade_data_t, fade_data);
}

/*
 *      return current time in seconds.
 */
PRIVATE gdouble
get_current_time (void)
{
    double timestamp;
    GTimeVal now;

    g_get_current_time (&now);

    timestamp = ((USEC_PER_SEC * now.tv_sec) + now.tv_usec) / USEC_PER_SEC;

    return timestamp;
}

PRIVATE gboolean
on_tick (gpointer user_data)
{
    xfade_data_t* fade_data = (xfade_data_t*)user_data;

    gdouble cur_time;
    cur_time = get_current_time ();

    fade_data->alpha = (cur_time - fade_data->start_time) / fade_data->total_duration;
    fade_data->alpha = CLAMP (fade_data->alpha, 0.0, 1.0);

    draw_background (fade_data);

    // 'coz fade_data->alpha is a rough value
    if(fade_data->alpha >= ALPHA_THRESHOLD)
        return FALSE;

    return TRUE;
}

PRIVATE void
on_finished (gpointer user_data)
{
    xfade_data_t* fade_data = (xfade_data_t*) user_data;

    fade_data->alpha = 1.0;

    draw_background (fade_data);

    free_fade_data (fade_data);
}

PRIVATE void
remove_timers ()
{
    if (bg_timeout_id)
    {
        g_source_remove (bg_timeout_id);
        bg_timeout_id = 0;
    }
    if (auto_timeout_id)
    {
        g_source_remove (auto_timeout_id);
        auto_timeout_id = 0;
    }
    if (manual_timeout_id)
    {
        g_source_remove (manual_timeout_id);
        manual_timeout_id = 0;
    }
}
/*
 *      get previous background pixmap id.
 *      NOTE: return value:
 *      1. None
 *         1) the property is not set.
 *            when we first startup.
 *         2) a pixmap that has been freed
 *         3) a pixmap that is inconsistent
 *            with current resolution. so
 *            we need to regenerate a pixmap.
 *      2. non-None
 *         a valid pixmap that has the same size as
 *         the root window in pixel.
 *
 *      all None return value indicates that
 *      we need to regenerate a pixmap.
 *
 */
static inline Pixmap
get_previous_background (void)
{
    return current_rootpmap;
}

/*
 *      create a cairo surface from a pixmap. this is where
 *      we're drawing on
 *      NOTE: @pixmap should not be None.
 *      TODO: we assume that @pixmap is the same size as the
 *            root_window. if that's not tree, scale it.
 */
PRIVATE cairo_surface_t*
get_surface(Pixmap pixmap)
{
    cairo_surface_t* cs=NULL;
    cs = cairo_xlib_surface_create (display, pixmap,
                                    root_visual,
                                    root_width, root_height);

    return cs;
}

PRIVATE const char*
get_current_picture_path ()
{
    const char* _pic = g_ptr_array_index (picture_paths,
                                          picture_index);
    return _pic;
}
// NOTE: this should be the only place to update picture_index
PRIVATE guint
get_next_picture_index ()
{
    guint _next_picture = 0;
    switch (gsettings_xfade_auto_mode)
    {
        // header doesn't work, add this to avoid warning
        extern long int random();
        case XFADE_AUTO_MODE_RANDOM:
            _next_picture = random() % picture_num;
            break;
        //default to draw in sequence.
        case XFADE_AUTO_MODE_SEQUENTIAL:
        default:
            _next_picture = (picture_index+1) % picture_num;
            break;
    }
    //NOTE: update picture_index;
    picture_index = _next_picture;

    return _next_picture;
}

// NOTE: this should be the only place to update picture_index
PRIVATE const char*
get_next_picture_path ()
{
    guint _next_picture_index = 0;
    const gchar *_next_picture_path = NULL;

    _next_picture_index = get_next_picture_index ();
    _next_picture_path = g_ptr_array_index (picture_paths,
                                            _next_picture_index);
    return _next_picture_path;
}

PRIVATE GdkPixbuf*
get_xformed_gdk_pixbuf (const char* pict_path)
{
    GError* error = NULL;
    GdkPixbuf* _pixbuf = NULL;
    GdkPixbuf* _xformed_pixbuf = NULL;

    _pixbuf = gdk_pixbuf_new_from_file (pict_path, &error);
    if (error != NULL)
    {
        _pixbuf = gdk_pixbuf_new_from_file (BG_DEFAULT_PICTURE, NULL);
    }

    int w0, h0;
    w0 = gdk_pixbuf_get_width (_pixbuf);
    h0 = gdk_pixbuf_get_height (_pixbuf);
    gboolean has_alpha;
    has_alpha = gdk_pixbuf_get_has_alpha (_pixbuf);
    int x, y;
    int w, h;
    switch (gsettings_draw_mode)
    {
        //NOTE: GDK_INTERP_TILES has nothing to do with tiling.
        case DRAW_MODE_TILING:
            _xformed_pixbuf = gdk_pixbuf_new (GDK_COLORSPACE_RGB,
                                              has_alpha, 8,
                                              root_width, root_height);
            for (x = 0; x < root_width; x += w0)
            {
                if (x + w0 <= root_width)
                    w = w0;
                else
                    w = root_width - x;

                for (y = 0; y < root_height; y += h0)
                {
                    if (y + h0 <= root_height)
                        h = h0;
                    else
                        h = root_height - y;

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


PRIVATE gboolean
on_bg_duration_tick (gpointer user_data G_GNUC_UNUSED)
{
    xfade_data_t* fade_data = g_slice_new(xfade_data_t);

    fade_data->total_duration = gsettings_xfade_auto_interval/MSEC_PER_SEC;
    fade_data->interval = TIME_PER_FRAME;

    fade_data->start_time = get_current_time();
    fade_data->alpha = 0.0;

    Pixmap prev_pixmap = get_previous_background();
    gdk_error_trap_push ();
    if (prev_pixmap == None)
    {
        prev_pixmap = XCreatePixmap (display, root,
                                     root_width, root_height,
                                     root_depth);
        _update_rootpmap (prev_pixmap);
    }
    gdk_error_trap_pop_ignored ();

    fade_data->pixmap = prev_pixmap;
    fade_data->fading_surface = get_surface (prev_pixmap);

    const char* next_picture = get_next_picture_path ();
    g_settings_set_string (Settings, BG_CURRENT_PICT, next_picture);

    fade_data->end_pixbuf = get_xformed_gdk_pixbuf (next_picture);

    GSource* source = g_timeout_source_new (fade_data->interval*MSEC_PER_SEC);

    g_source_set_callback (source, (GSourceFunc) on_tick, fade_data, (GDestroyNotify)on_finished);

    if (auto_timeout_id)
        g_source_remove (auto_timeout_id);

    auto_timeout_id = g_source_attach (source, g_main_context_default());

    return TRUE;
}

PRIVATE void
on_bg_duration_finished (gpointer user_data G_GNUC_UNUSED)
{
}

PRIVATE void
setup_background_timer ()
{
    GSource* source = g_timeout_source_new (gsettings_background_duration*MSEC_PER_SEC);

    g_source_set_callback (source, (GSourceFunc) on_bg_duration_tick, NULL, (GDestroyNotify)on_bg_duration_finished);

    bg_timeout_id = g_source_attach (source, g_main_context_default());
}

PRIVATE void
setup_crossfade_timer ()
{
    xfade_data_t* fade_data = g_slice_new(xfade_data_t);

    Pixmap prev_pixmap = get_previous_background ();
    gdk_error_trap_push ();
    if (prev_pixmap == None)
    {
        prev_pixmap = XCreatePixmap (display, root,
                                     root_width, root_height,
                                     root_depth);
        _update_rootpmap (prev_pixmap);
    }
    gdk_error_trap_pop_ignored ();

    fade_data->pixmap = prev_pixmap;
    fade_data->fading_surface = get_surface (prev_pixmap);
    fade_data->alpha = 0;

    g_settings_set_string (Settings, BG_CURRENT_PICT, get_current_picture_path());
    fade_data->end_pixbuf = get_xformed_gdk_pixbuf (get_current_picture_path());

    fade_data->total_duration = gsettings_xfade_manual_interval/MSEC_PER_SEC;
    fade_data->interval = TIME_PER_FRAME;

    fade_data->start_time = get_current_time();
    GSource* source = g_timeout_source_new (fade_data->interval*MSEC_PER_SEC);

    g_source_set_callback (source, (GSourceFunc) on_tick, fade_data, (GDestroyNotify)on_finished);

    manual_timeout_id = g_source_attach (source, g_main_context_default());
}

/*
 */
PRIVATE void
setup_timers ()
{
    if (gsettings_background_duration && picture_num > 1)
    {
        setup_crossfade_timer ();
        setup_background_timer ();
    }
    else
    {
        setup_crossfade_timer ();
    }
}

/*
 *      parse picture-uris string and
 *      add them to global array---picture_paths
 *
 *      <picture_uris> := (<uri> ";")* <uri> [";"]
 */
PRIVATE void
parse_picture_uris ()
{
    gchar* pic_uris = g_settings_get_string (Settings, BG_PICTURE_URIS);
    gchar* cur_pic = g_settings_get_string (Settings, BG_CURRENT_PICT);
    if (strlen(cur_pic) == 0) {
        g_free(cur_pic);
        cur_pic = g_strdup(BG_DEFAULT_PICTURE);
    }
    if (strlen(pic_uris) == 0) {
        g_free(pic_uris);
        pic_uris = g_strdup(cur_pic);
    }

    picture_num = 0;
    picture_index = 0;

    gchar* uri_end;   // end of a uri
    gchar* uri_start;   //start of a uri
    gchar* filename_ptr;


    uri_start = pic_uris;
    while ((uri_end = strchr (uri_start, DELIMITER)) != NULL)
    {
        *uri_end = '\0';

        filename_ptr = g_filename_from_uri (uri_start, NULL, NULL);
        if (filename_ptr != NULL)
        {
            if (g_strcmp0(cur_pic, filename_ptr) == 0) {
                picture_index = picture_num;
            }
            g_ptr_array_add (picture_paths, filename_ptr);
            g_hash_table_insert (picture_paths_ht,
                                 filename_ptr,
                                 GUINT_TO_POINTER(picture_num+1));
            picture_num ++;
        }

        uri_start = uri_end + 1;
    }
    if (*uri_start != '\0')
    {
        filename_ptr = g_filename_from_uri (uri_start, NULL, NULL);
        if (filename_ptr != NULL)
        {
            g_ptr_array_add (picture_paths, filename_ptr);
            g_hash_table_insert (picture_paths_ht,
                                 filename_ptr,
                                 GUINT_TO_POINTER(picture_num+1));
            picture_num ++;
        }
    }
    //ensure we don't have a empty picture uris
    if (picture_num == 0)
    {
        filename_ptr = g_strdup(BG_DEFAULT_PICTURE);
        g_ptr_array_add (picture_paths, filename_ptr);
        g_hash_table_insert (picture_paths_ht,
                             filename_ptr,
                             GUINT_TO_POINTER(picture_num+1));
        picture_num =1;
    }
    g_free(pic_uris);
    g_free(cur_pic);
}
PRIVATE void
destroy_picture_path (gpointer data)
{
    g_free (data);
}
/*
 *      it's not efficient to check whether the new picture_uris is the same
 *      as the previous value. we just restart all.
 */
PRIVATE void
bg_settings_picture_uris_changed (GSettings *settings G_GNUC_UNUSED, gchar *key G_GNUC_UNUSED, gpointer user_data G_GNUC_UNUSED)
{
    g_hash_table_destroy (picture_paths_ht);
    g_ptr_array_free (picture_paths, TRUE);

    picture_paths = g_ptr_array_new_with_free_func (destroy_picture_path);
    picture_paths_ht = g_hash_table_new (g_str_hash, g_str_equal);

    parse_picture_uris ();

    const char* current_picture = get_current_picture_path ();
    g_settings_set_string (Settings, BG_CURRENT_PICT, current_picture);

    remove_timers ();

    setup_timers ();
}

/*
 *      handle user-selected picture uri
 */
PRIVATE void
bg_settings_picture_uri_changed (GSettings *settings, gchar *key G_GNUC_UNUSED, gpointer user_data G_GNUC_UNUSED)
{
    gchar* tmp_image_uri = g_settings_get_string (settings, BG_PICTURE_URI);
    if (strlen(tmp_image_uri) == 0)  return;
    gchar* tmp_image_path = g_filename_from_uri (tmp_image_uri, NULL, NULL);
    g_debug ("picture-uri changed: |%s|(%p len:%ld) |%s|", tmp_image_uri, tmp_image_uri, strlen(tmp_image_uri), tmp_image_path);
    g_free (tmp_image_uri);
    guint tmp_value = GPOINTER_TO_UINT (g_hash_table_lookup (picture_paths_ht, tmp_image_path));
    g_free (tmp_image_path);

    //g_hash_table_lookup can return NULL, so we store 'index+1' in hashtable
    if ((tmp_value != 0)&&(tmp_value != picture_index+1))
    {
        picture_index = tmp_value - 1;
        remove_timers ();
        setup_timers ();
    }
}
/*
 *      we should reset timer and start auto
 */
PRIVATE void
bg_settings_bg_duration_changed (GSettings *settings, gchar *key G_GNUC_UNUSED, gpointer user_data G_GNUC_UNUSED)
{
    gsettings_background_duration = g_settings_get_int (settings, BG_BG_DURATION);

    remove_timers ();

    setup_timers ();
}

PRIVATE void
bg_settings_xfade_manual_interval_changed (GSettings *settings, gchar *key G_GNUC_UNUSED, gpointer user_data G_GNUC_UNUSED)
{
    gsettings_xfade_manual_interval = g_settings_get_int (settings, BG_XFADE_MANUAL_INTERVAL);

    remove_timers ();

    setup_timers ();
}

PRIVATE void
bg_settings_xfade_auto_interval_changed (GSettings *settings, gchar *key G_GNUC_UNUSED, gpointer user_data G_GNUC_UNUSED)
{
    gsettings_xfade_auto_interval = g_settings_get_int (settings, BG_XFADE_AUTO_INTERVAL);

    remove_timers ();

    if (gsettings_background_duration)
        setup_timers ();
}

PRIVATE void
bg_settings_xfade_auto_mode_changed (GSettings *settings, gchar *key G_GNUC_UNUSED, gpointer user_data G_GNUC_UNUSED)
{
    gsettings_xfade_auto_mode = g_settings_get_enum (settings, BG_XFADE_AUTO_MODE);

    remove_timers ();

    setup_timers ();
}
//TODO: draw mode: scaling, and tiling
PRIVATE void
bg_settings_draw_mode_changed (GSettings *settings, gchar *key G_GNUC_UNUSED, gpointer user_data G_GNUC_UNUSED)
{
    gsettings_draw_mode = g_settings_get_enum (settings, BG_DRAW_MODE);

    remove_timers ();

    setup_timers ();
}

PRIVATE void
register_account_service_background_path (const char* current_picture)
{
    GError* error = NULL;

    if (AccountsProxy == NULL)
    {
        int flags = G_DBUS_PROXY_FLAGS_DO_NOT_LOAD_PROPERTIES|
                    G_DBUS_PROXY_FLAGS_DO_NOT_CONNECT_SIGNALS;

        GDBusProxy* _proxy = NULL;
        _proxy = g_dbus_proxy_new_for_bus_sync (G_BUS_TYPE_SYSTEM,
                                                flags,
                                                NULL,
                                                "org.freedesktop.Accounts",
                                                "/org/freedesktop/Accounts",
                                                "org.freedesktop.Accounts",
                                                NULL,
                                                &error);
        g_dbus_connection_set_exit_on_close(g_dbus_proxy_get_connection(_proxy), FALSE);
        if (error != NULL)
        {
            g_error_free (error);
        }

        gint64 user_id = 0;
        user_id = (gint64)geteuid ();

        GVariant* object_path_var = NULL;
        error = NULL;
        object_path_var = g_dbus_proxy_call_sync (_proxy, "FindUserById",
                                                  g_variant_new ("(x)", user_id),
                                                  G_DBUS_CALL_FLAGS_NONE,
                                                  -1,
                                                  NULL,
                                                  &error);
        if (error != NULL)
        {
            g_error_free (error);
        }

        char* object_path = NULL;
        g_variant_get (object_path_var, "(o)", &object_path);

        g_variant_unref (object_path_var);
        g_object_unref (_proxy);

        //yeah, setup another proxy to set background
        AccountsProxy = g_dbus_proxy_new_for_bus_sync (G_BUS_TYPE_SYSTEM,
                                                       flags,
                                                       NULL,
                                                       "org.freedesktop.Accounts",
                                                       object_path,
                                                       "org.freedesktop.Accounts.User",
                                                       NULL,
                                                       &error);
        g_dbus_connection_set_exit_on_close(g_dbus_proxy_get_connection(AccountsProxy), FALSE);
        if (error != NULL)
        {
            g_error_free (error);
        }
        g_free (object_path);
    }

    error = NULL;
    g_dbus_proxy_call_sync (AccountsProxy,
                            "SetBackgroundFile",
                            g_variant_new("(s)",current_picture),
                            G_DBUS_CALL_FLAGS_NONE,
                            -1,
                            NULL,
                            &error);
    if (error != NULL)
    {
        g_error_free (error);
    }
}
PRIVATE void
bg_settings_current_picture_changed (GSettings *settings, gchar *key G_GNUC_UNUSED, gpointer user_data G_GNUC_UNUSED)
{
    gchar* cur_pict = g_settings_get_string (settings, BG_CURRENT_PICT);
    if (strlen(cur_pict) == 0)  return;

    register_account_service_background_path (cur_pict);
    g_free (cur_pict);
}

PRIVATE void
screen_size_changed_cb (GdkScreen* screen, gpointer user_data G_GNUC_UNUSED)
{
    //remove early to avoid fatal X errors
    int current_root_width = gdk_screen_width();
    int current_root_height = gdk_screen_height();
    if (current_root_width != root_width || current_root_height != root_height) {
        root_width = current_root_width;
        root_height = current_root_height;
    } else {
        return;
    }
    remove_timers ();

    root_width = gdk_screen_get_width(screen);
    root_height = gdk_screen_get_height(screen);
    gdk_window_move_resize(background_window, 0, 0, root_width, root_height);

    const char* current_picture = get_current_picture_path ();
    g_settings_set_string (Settings, BG_CURRENT_PICT, current_picture);
    //g_debug ("screen_size_changed_cb: end set string");
    //start_gaussian_helper (current_picture);
    //g_debug ("screen_size_changed_cb: end helper");

    GdkPixbuf* pb = get_xformed_gdk_pixbuf (current_picture);

    g_assert (pb != NULL);

    /*
     *  this is similar to initial setup. but we need to
     *  free previous pixmap first.
     */
    Pixmap prev_pixmap = get_previous_background();
    gdk_error_trap_push ();
    if (prev_pixmap != None)
    {
        XFreePixmap (display, prev_pixmap);
    }
    gdk_error_trap_pop_ignored ();

    Pixmap new_pixmap = XCreatePixmap (display, root,
                                       root_width, root_height,
                                       root_depth);

    _update_rootpmap (new_pixmap);

    xfade_data_t* fade_data = g_slice_new(xfade_data_t);

    fade_data->pixmap = new_pixmap;
    fade_data->fading_surface = get_surface (new_pixmap);
    fade_data->end_pixbuf = pb;
    fade_data->alpha = 1.0;

    cairo_pattern_t* pattern;
    pattern = cairo_pattern_create_for_surface (fade_data->fading_surface);
    gdk_window_set_background_pattern (background_window, pattern);
    cairo_pattern_destroy (pattern);

    draw_background (fade_data);

    free_fade_data (fade_data);

    if (gsettings_background_duration && picture_num > 1)
    {
        setup_background_timer ();
    }
}

DEEPIN_EXPORT void
bg_util_connect_screen_signals (GdkWindow* bg_window)
{
    // xrandr screen resolution handling
    g_signal_connect (gdk_screen, "size-changed",
                      G_CALLBACK (screen_size_changed_cb), bg_window);
    g_signal_connect (gdk_screen, "monitors-changed",
                      G_CALLBACK (screen_size_changed_cb), bg_window);
}

DEEPIN_EXPORT void
bg_util_disconnect_screen_signals (GdkWindow* bg_window)
{
    g_signal_handlers_disconnect_by_func (gdk_screen,
                           G_CALLBACK (screen_size_changed_cb), bg_window);
}

//FIXME: screen_size_changed_cb and initial_setup have a lot of
//       duplicated function.
PRIVATE void
initial_setup (GSettings *settings)
{
    static gboolean is_initialized = FALSE;
    if (is_initialized == FALSE) {
        is_initialized = TRUE;
        gsettings_background_duration = g_settings_get_int (settings, BG_BG_DURATION);
        gsettings_xfade_manual_interval = g_settings_get_int (settings, BG_XFADE_MANUAL_INTERVAL);
        gsettings_xfade_auto_interval = g_settings_get_int (settings, BG_XFADE_AUTO_INTERVAL);

        gsettings_xfade_auto_mode = g_settings_get_enum (settings, BG_XFADE_AUTO_MODE);
        gsettings_draw_mode = g_settings_get_enum (settings, BG_DRAW_MODE);
    }

    /*
     *  don't remove following comments:
     *  to keep pixmap resource available
    */
    //XSetCloseDownMode (display, RetainPermanent);

    const char* current_picture = get_current_picture_path ();
    g_settings_set_string (Settings, BG_CURRENT_PICT, current_picture);
    //start_gaussian_helper (current_picture);

    /*
     *  no previous background, no cross fade effect.
     *  this is most likely the situation when we first start up.
     *  resolution changed.
     */
    //since we now call initial setup in every expose event.
    Pixmap prev_pixmap = get_previous_background();
    gdk_error_trap_push ();
    if (prev_pixmap != None)
    {
        XFreePixmap (display, prev_pixmap);
    }
    gdk_error_trap_pop_ignored ();

    Pixmap new_pixmap = XCreatePixmap (display, root,
                                       root_width, root_height,
                                       root_depth);
    _update_rootpmap (new_pixmap);

    GdkPixbuf* pb = get_xformed_gdk_pixbuf (get_current_picture_path());

    xfade_data_t* fade_data = g_slice_new(xfade_data_t);

    fade_data->pixmap = new_pixmap;
    fade_data->fading_surface = get_surface (new_pixmap);
    fade_data->end_pixbuf = pb;
    fade_data->alpha = 1.0;

    draw_background (fade_data);
    cairo_pattern_t* pattern;
    pattern = cairo_pattern_create_for_surface (fade_data->fading_surface);
    gdk_window_set_background_pattern (background_window, pattern);
    cairo_pattern_destroy (pattern);
    free_fade_data (fade_data);

    if (gsettings_background_duration && picture_num > 1)
    {
        setup_background_timer ();
    }

    return;
}

PRIVATE GdkFilterReturn
expose_cb (GdkXEvent* xevent, GdkEvent* event G_GNUC_UNUSED, gpointer data G_GNUC_UNUSED)
{
    //At least first running desktop and suspend/resume will trigger expose event
    if (((XEvent*)xevent)->type == Expose)
    {
        initial_setup (Settings);
    }
    return GDK_FILTER_CONTINUE;
}

DEEPIN_EXPORT void
bg_util_init (GdkWindow* bg_window)
{
    static gboolean __init__ = FALSE;
    if (__init__ == FALSE) {
        __init__ = TRUE;
        Settings = g_settings_new (BG_SCHEMA_ID);
        picture_paths = g_ptr_array_new_with_free_func (destroy_picture_path);
        picture_paths_ht = g_hash_table_new (g_str_hash, g_str_equal);
        picture_num = 0;

        parse_picture_uris ();

        background_window = bg_window;

        display = GDK_DISPLAY_XDISPLAY(gdk_display_get_default());

        bg1_atom = gdk_x11_get_xatom_by_name(bg_props[0]);
        //bg2_atom = gdk_x11_get_xatom_by_name(bg_props[1]);
        pixmap_atom = gdk_x11_get_xatom_by_name("PIXMAP");

        root = DefaultRootWindow(display);
        default_screen = DefaultScreen(display);
        root_depth = DefaultDepth(display, default_screen);
        root_visual = DefaultVisual(display, default_screen);
        root_width = DisplayWidth(display, default_screen);
        root_height = DisplayHeight(display, default_screen);

        gdk_window_move_resize(background_window, 0, 0, root_width, root_height);

        gdk_screen = gdk_screen_get_default();

        g_signal_connect (Settings, "changed::picture-uris",
                G_CALLBACK (bg_settings_picture_uris_changed), NULL);
        g_signal_connect (Settings, "changed::picture-uri",
                G_CALLBACK (bg_settings_picture_uri_changed), NULL);
        g_signal_connect (Settings, "changed::background-duration",
                G_CALLBACK (bg_settings_bg_duration_changed), NULL);
        g_signal_connect (Settings, "changed::cross-fade-manual-interval",
                G_CALLBACK (bg_settings_xfade_manual_interval_changed), NULL);
        g_signal_connect (Settings, "changed::cross-fade-auto-interval",
                G_CALLBACK (bg_settings_xfade_auto_interval_changed), NULL);
        g_signal_connect (Settings, "changed::cross-fade-auto-mode",
                G_CALLBACK (bg_settings_xfade_auto_mode_changed), NULL);
        g_signal_connect (Settings, "changed::draw-mode",
                G_CALLBACK (bg_settings_draw_mode_changed), NULL);
        g_signal_connect (Settings, "changed::current-picture",
                G_CALLBACK (bg_settings_current_picture_changed), NULL);

        gdk_window_add_filter (background_window, expose_cb, background_window);
    }
}

