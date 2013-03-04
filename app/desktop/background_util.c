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


#define USEC_PER_SEC 1000000.0 // microseconds per second 
#define MSEC_PER_SEC 1000.0    // milliseconds per second
#define TIME_PER_FRAME	1.0/BG_FPS  // the interval between contingent frames
//
static GPtrArray *picture_paths;		//an array of picture paths (strings).
static char*	prev_picture = NULL;		//to track 
static guint	picture_num;		//number of pictures in GPtrArray.
static guint	picture_index;		// the next background picture.
//this is only used update current image in the gsettings
static GSettings *Settings;
//connect to AccountService DBus. and register background path
static GDBusProxy* AccountsProxy = NULL;

static gulong	gsettings_background_duration;
static gulong	gsettings_xfade_auto_interval; //use this time only when we use 
                                               //multiple background pictures.
static gulong	gsettings_xfade_manual_interval;
static BgXFadeAutoMode	gsettings_xfade_auto_mode;
static BgDrawMode	gsettings_draw_mode;

static const gchar* bg_props[2] = {"_XROOTPMAP_ID","ESETROOT_PMAP_ID"};
static Atom bg1_atom;  
static Atom bg2_atom;
static Atom pixmap_atom; 

static Display* display;
static Window	root;
static int	default_screen;
static int	root_depth;
static Visual*	root_visual;
static int	root_width;
static int	root_height;

static GdkScreen * gdk_screen;


//global timeout_id to track in process timeoutout
static guint	bg_timeout_id =0;	// background_duration
static guint	auto_timeout_id = 0;	// xfade_auto_interval
static guint	manual_timeout_id = 0;	// xfade_manual_interval
//

/*
 * 	all the time are in seconds.
 */
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

/*
 *	start gaussina helper in the background
 */
#if 1
static void
start_gaussian_helper (const char* _picture_path)
{
    //g_mkdir_with_parents (BG_GAUSSIAN_PICT_DIR, 0755);

#if 0
    //use symlink.
    //link file @_picture_path to /var/cache/background/gaussian.png"
    unlink (BG_GAUSSIAN_PICT_PATH);
    if (symlink (_picture_path, BG_GAUSSIAN_PICT_PATH))
    {
	g_debug ("start_gaussian_helper: symlink failed");
    }
#endif 
    //LIBEXECDIR is a CPP macro. see Makefile.am

    g_print ("_picture_path: %s\n", _picture_path);
    if (!g_strcmp0 (prev_picture, _picture_path))
    {
	//no need to generate pictures.
	if (prev_picture!=NULL)
	{
	   g_print ("start_gaussian_helper: alread started for this picture: %s\n", prev_picture);
	}
	return ;
    }
    else
    {
	g_free (prev_picture);
	prev_picture = NULL;
	prev_picture = g_strdup (_picture_path);
    }

    char* command;
    command = g_strdup_printf (LIBEXECDIR "/gsd-background-helper "
			       "%lf %lu %s",
			       BG_GAUSSIAN_SIGMA, BG_GAUSSIAN_NSTEPS, _picture_path);
#if 0
    //for testing locally.
    command = g_strdup_printf ("./gsd-background-helper "
			       "%lf %lu %s",
			       BG_GAUSSIAN_SIGMA, BG_GAUSSIAN_NSTEPS, _picture_path);
#endif
    g_debug ("command : %s", command);

    GError *error = NULL;
    gboolean ret;
    ret = g_spawn_command_line_async (command, &error);
    if (ret == FALSE) 
    {
	g_debug ("Failed to launch '%s': %s", command, error->message);
	g_error_free (error);
    }

    g_debug ("gsd-background-helper started");
    g_free (command);
}
#endif
/*
 *	change root window x properties.
 *	TODO: change set_bg_props or _change_bg_xproperties 
 *	      to a better name.
 */
static void 
_change_bg_xproperties (Pixmap pm)
{
    gdk_error_trap_push ();
    XChangeProperty (display, root, bg1_atom, pixmap_atom,
		     32, PropModeReplace, (unsigned char*)&pm, 1);
    XChangeProperty (display, root, bg2_atom, pixmap_atom,
		     32, PropModeReplace, (unsigned char*)&pm, 1);
    XFlush (display);
    gdk_error_trap_pop_ignored ();
}
/*
 *    compositing two cairo surfaces. 
 */
static void 
draw_background (xfade_data_t* fade_data)
{
    cairo_t* cr;
    cr = cairo_create (fade_data->fading_surface);

    gdk_cairo_set_source_pixbuf (cr, fade_data->end_pixbuf, 0, 0);
    cairo_paint_with_alpha (cr, fade_data->alpha);

    cairo_destroy (cr);
#if 0
    //Yep, we draw it again on the root window.

    GdkWindow* gdk_root = gdk_get_default_root_window ();
    cr = gdk_cairo_create (gdk_root);
    cairo_set_source_surface (cr, fade_data->fading_surface, 0, 0);
    cairo_paint (cr);
    cairo_destroy (cr);
#endif

    _change_bg_xproperties (fade_data->pixmap);
}
        	
/*
 * 	free fade_data and its fields.
 */
static void 
free_fade_data (xfade_data_t* fade_data)
{
    cairo_surface_destroy (fade_data->fading_surface);
    g_object_unref (fade_data->end_pixbuf);
    g_free (fade_data);
}

/*
 *	return current time in seconds.
 */
static gdouble 
get_current_time (void)
{
    double timestamp;
    GTimeVal now;

    g_get_current_time (&now);

    timestamp = ((USEC_PER_SEC * now.tv_sec) + now.tv_usec) / USEC_PER_SEC;

    return timestamp;
}

static gboolean 
on_tick (gpointer user_data)
{
    xfade_data_t* fade_data = (xfade_data_t*)user_data;

    gdouble cur_time;
    cur_time = get_current_time ();

    fade_data->alpha = (cur_time - fade_data->start_time) / fade_data->total_duration;
    fade_data->alpha = CLAMP (fade_data->alpha, 0.0, 1.0);

    draw_background (fade_data);

    static int i=0;
	
    g_debug ("tick %d",++i);
    g_debug ("cur_time : %lf", cur_time);
    g_debug ("start_time: %lf", fade_data->start_time);
    g_debug ("total_duration: %lf", fade_data->total_duration);
    g_debug ("alpha	 : %lf", fade_data->alpha);

    // 'coz fade_data->alpha is a rough value
    if(fade_data->alpha >=0.9)
	return FALSE;

    return TRUE;
}

static void 
on_finished (gpointer user_data)
{
    xfade_data_t* fade_data = (xfade_data_t*) user_data;

    fade_data->alpha = 1.0;

    draw_background (fade_data);

    free_fade_data (fade_data);
    g_debug ("crossfade finished ");
}
static void 
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
 * 	get previous background pixmap id.
 * 	NOTE: return value:
 * 	1. None
 * 	   1) the property is not set.
 * 	      when we first startup.
 * 	   2) a pixmap that has been freed
 * 	   3) a pixmap that is inconsistent 
 * 	      with current resolution. so 
 * 	      we need to regenerate a pixmap. 
 * 	2. non-None 
 * 	   a valid pixmap that has the same size as 
 * 	   the root window in pixel.
 *
 * 	all None return value indicates that 
 * 	we need to regenerate a pixmap.
 *
 */
static Pixmap 
get_previous_background (void)
{
    Pixmap pbg1 = None;
    Pixmap pbg2 = None;

    //get previous properties.
    gulong nitems = 0;
    guchar* prop = NULL;
    Atom actual_type;
    int  actual_format;
    gulong bytes_after;

    gdk_error_trap_push ();
    if (XGetWindowProperty (display, root, bg1_atom, 0, 4, False, AnyPropertyType,
			&actual_type, &actual_format, &nitems, &bytes_after, &prop) == Success &&
	   actual_type == pixmap_atom && actual_format == 32 && nitems == 1)
    {
	memcpy (&pbg1, prop, 4);
	XFree (prop);
    }	

    if (XGetWindowProperty (display, root, bg2_atom, 0, 4, False, AnyPropertyType,
			&actual_type, &actual_format, &nitems, &bytes_after, &prop) == Success &&
	   actual_type == pixmap_atom && actual_format == 32 && nitems == 1)
    {
	memcpy (&pbg2, prop, 4);
	XFree (prop);
    }	
    gdk_error_trap_pop_ignored ();
    //compare two pixmaps.
    g_assert (pbg1 == pbg2);

    //check whether the pixmap exists
    Window _root;
    int _x,_y;
    unsigned int _width,_height;
    unsigned int _border,_depth;
	/*
	 * 	TODO: how to reliably check the existence of a pixmap.
	 */
	
    if (pbg1 != None)
    {
	gdk_error_trap_push ();
	Status _s = XGetGeometry (display, pbg1, &_root,
		                &_x, &_y, &_width, &_height,
		                &_border, &_depth);
	if ((_s==0)||(_width!=root_width)||(_height!=root_height))
	{
	    // the drawable have been freed or resolution changed.
	    pbg1 = None;
	}
	gdk_error_trap_pop_ignored ();
    }

    g_debug ("prev_pixmap = 0x%x", (unsigned) pbg1);
    return pbg1;
}

/*
 * 	create a cairo surface from a pixmap. this is where 
 * 	we're drawing on
 * 	NOTE: @pixmap should not be None.
 * 	TODO: we assume that @pixmap is the same size as the
 * 	      root_window. if that's not tree, scale it.
 */
static cairo_surface_t* 
get_surface(Pixmap pixmap)
{
    cairo_surface_t* cs=NULL;
    cs = cairo_xlib_surface_create (display, pixmap, 
			            root_visual, 
				    root_width, root_height);
	
    return cs;
}
#if 0
static guint
get_current_picture_index ()
{
    return picture_index;
}
#endif
static const char* 
get_current_picture_path ()
{
    const char* _pic = g_ptr_array_index (picture_paths, 
	                                  picture_index);

    return _pic;
}
// NOTE: this should be the only place to update picture_index
static guint
get_next_picture_index ()
{
    guint _next_picture = 0;
    switch (gsettings_xfade_auto_mode)
    {
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
static const char*
get_next_picture_path ()
{
    guint _next_picture_index = 0;
    const gchar *_next_picture_path = NULL;

    _next_picture_index = get_next_picture_index ();
    _next_picture_path = g_ptr_array_index (picture_paths, 
	                                    _next_picture_index);
    return _next_picture_path;
}

static GdkPixbuf*
get_xformed_gdk_pixbuf (const char* pict_path)
{
    g_debug ("picture_index : %d", picture_index);
    GError* error = NULL;
    GdkPixbuf* _pixbuf = NULL;
    GdkPixbuf* _xformed_pixbuf = NULL;

    _pixbuf = gdk_pixbuf_new_from_file (pict_path, &error);
    if (error != NULL)
    {
	g_debug ("get_next_gdk_pixbuf: %s", error->message);
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
#if 0
static GdkPixbuf*
get_next_xformed_gdk_pixbuf ()
{
    const char* _path = get_next_picture_path ();
    GdkPixbuf* _pixbuf = get_xformed_gdk_pixbuf (_path);

    return _pixbuf;
}
#endif
static gboolean 
on_bg_duration_tick (gpointer user_data)
{
    xfade_data_t* fade_data = g_new0 (xfade_data_t, 1);
    
    fade_data->total_duration = gsettings_xfade_auto_interval/MSEC_PER_SEC;
    fade_data->interval = TIME_PER_FRAME;

    fade_data->start_time = get_current_time(); 
    fade_data->alpha = 0.0;

    g_debug ("on_bg_duration_tick: current_time: %lf", fade_data->start_time);
    Pixmap prev_pixmap = get_previous_background();
    gdk_error_trap_push ();
    if (prev_pixmap == None)
    {
	prev_pixmap = XCreatePixmap (display, root, 
				           root_width, root_height,
				           root_depth);
	_change_bg_xproperties (prev_pixmap);
    }
    gdk_error_trap_pop_ignored ();

    fade_data->pixmap = prev_pixmap;
    fade_data->fading_surface = get_surface (prev_pixmap);

    const char* next_picture = get_next_picture_path ();
    g_settings_set_string (Settings, BG_CURRENT_PICT, next_picture);
    g_debug ("on_bg_duration_tick: end set string");
    start_gaussian_helper (next_picture);
    g_debug ("on_bg_duration_tick: end helper");

    fade_data->end_pixbuf = get_xformed_gdk_pixbuf (next_picture);

    GSource* source = g_timeout_source_new (fade_data->interval*MSEC_PER_SEC);

    g_source_set_callback (source, (GSourceFunc) on_tick, fade_data, (GDestroyNotify)on_finished);

    if (auto_timeout_id)
	g_source_remove (auto_timeout_id);

    auto_timeout_id = g_source_attach (source, g_main_context_default());

    return TRUE;
}

static void 
on_bg_duration_finished (gpointer user_data)
{
    g_debug ("bg_duration_finished");
}

static void
setup_background_timer ()
{
    GSource* source = g_timeout_source_new (gsettings_background_duration*MSEC_PER_SEC);

    g_source_set_callback (source, (GSourceFunc) on_bg_duration_tick, NULL, (GDestroyNotify)on_bg_duration_finished);

    bg_timeout_id = g_source_attach (source, g_main_context_default());
}

static void
setup_crossfade_timer ()
{
    xfade_data_t* fade_data = g_new0 (xfade_data_t, 1);

    Pixmap prev_pixmap = get_previous_background ();
    gdk_error_trap_push ();
    if (prev_pixmap == None)
    {
	prev_pixmap = XCreatePixmap (display, root, 
				     root_width, root_height,
				     root_depth);
	_change_bg_xproperties (prev_pixmap);
    }
    gdk_error_trap_pop_ignored ();

    fade_data->pixmap = prev_pixmap;
    fade_data->fading_surface = get_surface (prev_pixmap);
    fade_data->alpha = 0;

    const char* current_picture = get_current_picture_path ();
    g_settings_set_string (Settings, BG_CURRENT_PICT, current_picture);
    g_debug ("setup_crossfade_timer: end set string");
    start_gaussian_helper (current_picture);
    g_debug ("setup_crossfade_timer: end helper");

    fade_data->end_pixbuf = get_xformed_gdk_pixbuf (current_picture);

    fade_data->total_duration = gsettings_xfade_manual_interval/MSEC_PER_SEC;
    fade_data->interval = TIME_PER_FRAME;

    fade_data->start_time = get_current_time(); 
    g_debug ("start_time : %lf", fade_data->start_time);
    GSource* source = g_timeout_source_new (fade_data->interval*MSEC_PER_SEC);

    g_source_set_callback (source, (GSourceFunc) on_tick, fade_data, (GDestroyNotify)on_finished);

    manual_timeout_id = g_source_attach (source, g_main_context_default());
    g_debug ("timeout_id : %d", manual_timeout_id);
}
/*
 */
static void 
setup_timers ()
{
    if (gsettings_background_duration && picture_num > 1)
    {
	g_debug ("setup_background_timer");
	setup_crossfade_timer ();
	setup_background_timer ();
    }
    else
    {
	g_debug ("setup_crossfade_timer");
	setup_crossfade_timer ();
    }
}

/*
 *	parse picture-uris string and
 *	add them to global array---picture_paths
 *
 *	<picture_uris> := (<uri> ";")* <uri> [";"]
 */
static void
parse_picture_uris (gchar * pic_uri)
{
    gchar* uri_end;   // end of a uri
    gchar* uri_start;   //start of a uri
    gchar* filename_ptr;

    uri_start = pic_uri;
    while ((uri_end = strchr (uri_start, DELIMITER)) != NULL)
    {
	*uri_end = '\0';
	
       	filename_ptr = g_filename_from_uri (uri_start, NULL, NULL);
	if (filename_ptr != NULL)
	{
	    g_ptr_array_add (picture_paths, filename_ptr);
	    picture_num ++;
	    g_debug ("picture %d: %s", picture_num, filename_ptr);
	}

	uri_start = uri_end + 1;
    }
    if (*uri_start != '\0')
    {
       	filename_ptr = g_filename_from_uri (uri_start, NULL, NULL);
	if (filename_ptr != NULL)
	{
	    g_ptr_array_add (picture_paths, filename_ptr);
	    picture_num ++;
	    g_debug ("picture %d: %s", picture_num, filename_ptr);
	}
    }
    //ensure we don't have a empty picture uris
    if (picture_num == 0)
    {
	g_ptr_array_add (picture_paths, BG_DEFAULT_PICTURE);
	picture_num =1;
    }
}
static void
destroy_picture_path (gpointer data)
{
    g_free (data);
}
/*
 *	it's not efficient to check if the new picture_uris is the same 
 *	as the previous value. we just restart all.
 */
static void 
bg_settings_picture_uris_changed (GSettings *settings, gchar *key, gpointer user_data)
{
    if (g_strcmp0 (key, BG_PICTURE_URIS))
	return;


    g_debug ("picture_uris changed");
    g_ptr_array_free (picture_paths, TRUE);
    picture_paths = g_ptr_array_new_with_free_func (destroy_picture_path);
    picture_num = 0;
    picture_index = 0;

    gchar* bg_image_uri = g_settings_get_string (settings, BG_PICTURE_URIS);
    parse_picture_uris (bg_image_uri);
    free (bg_image_uri);

    const char* current_picture = get_current_picture_path ();
    g_settings_set_string (Settings, BG_CURRENT_PICT, current_picture);
    g_debug ("bg_settings_picture_uris_changed: end set string");
    start_gaussian_helper (current_picture);
    g_debug ("bg_settings_picture_uris_changed: end helper");
#if 0
    GdkPixbuf* pb = get_xformed_gdk_pixbuf (current_picture);
    g_assert (pb != NULL);

    Pixmap prev_pixmap = get_previous_background();

    gdk_error_trap_push ();
    if (prev_pixmap == None)
    {
	Pixmap new_pixmap = XCreatePixmap (display, root, 
				       root_width, root_height,
				       root_depth);
	prev_pixmap = new_pixmap;
    }
    gdk_error_trap_pop_ignored ();

    xfade_data_t* fade_data = g_new0 (xfade_data_t, 1);
    
    fade_data->pixmap = prev_pixmap;
    fade_data->fading_surface = get_surface (prev_pixmap);
    fade_data->end_pixbuf = pb;
    fade_data->alpha = 1.0;     

    draw_background (fade_data);
    free_fade_data (fade_data);
#endif
    remove_timers ();

    setup_timers ();
}

/*
 *	we should reset timer and start auto	
 */
static void 
bg_settings_bg_duration_changed (GSettings *settings, gchar *key, gpointer user_data)
{
    if (g_strcmp0 (key, BG_BG_DURATION))
	return;

    gsettings_background_duration = g_settings_get_int (settings, BG_BG_DURATION);

    remove_timers ();

    setup_timers ();
}

static void
bg_settings_xfade_manual_interval_changed (GSettings *settings, gchar *key, gpointer user_data)
{
    if (g_strcmp0 (key, BG_XFADE_MANUAL_INTERVAL))
	return;

    gsettings_xfade_manual_interval = g_settings_get_int (settings, BG_XFADE_MANUAL_INTERVAL);

    remove_timers ();

    setup_timers ();
}

static void
bg_settings_xfade_auto_interval_changed (GSettings *settings, gchar *key, gpointer user_data)
{
    if (g_strcmp0 (key, BG_XFADE_AUTO_INTERVAL))
	return;

    gsettings_xfade_auto_interval = g_settings_get_int (settings, BG_XFADE_AUTO_INTERVAL);

    remove_timers ();
    
    if (gsettings_background_duration)
	setup_timers ();
}

static void
bg_settings_xfade_auto_mode_changed (GSettings *settings, gchar *key, gpointer user_data)
{
    if (g_strcmp0 (key, BG_XFADE_AUTO_MODE))
	return;

    gsettings_xfade_auto_mode = g_settings_get_enum (settings, BG_XFADE_AUTO_MODE);

    if (gsettings_xfade_auto_mode == XFADE_AUTO_MODE_RANDOM)
	g_debug ("XFADE_AUTO_MODE_RANDOM");
    else if (gsettings_xfade_auto_mode == XFADE_AUTO_MODE_SEQUENTIAL)
	g_debug ("XFADE_AUTO_MODE_SEQUENTIAL");

    remove_timers ();

    setup_timers ();
}
//TODO: draw mode: scaling, and tiling
static void
bg_settings_draw_mode_changed (GSettings *settings, gchar *key, gpointer user_data)
{
    if (g_strcmp0 (key, BG_DRAW_MODE))
	return;

    gsettings_draw_mode = g_settings_get_enum (settings, BG_DRAW_MODE);

    remove_timers ();

    setup_timers ();
}

static void
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
	if (error != NULL)
	{
	    g_debug ("connect org.freedesktop.Accounts failed");
	    g_error_free (error);
	}

	gint64 user_id = 0;
	user_id = (gint64)geteuid ();
	g_debug ("call FindUserById: uid = %i", user_id);

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
	    g_debug ("FindUserById: %s", error->message);
	    g_error_free (error);
	}

	char* object_path = NULL;
	g_variant_get (object_path_var, "(o)", &object_path);
	g_debug ("object_path : %s", object_path);

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
	if (error != NULL)
	{
	    g_debug ("connect to %s failed", object_path);
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
	g_debug ("org.freedesktop.Accounts.User: SetBackgroundFile %s failed", current_picture);
	g_error_free (error);
    }
}
static void
bg_settings_current_picture_changed (GSettings *settings, gchar *key, gpointer user_data)
{
    if (g_strcmp0 (key, BG_CURRENT_PICT))
	return;
    const char* cur_pict = g_settings_get_string (settings, BG_CURRENT_PICT);

    register_account_service_background_path (cur_pict);
}

static void 
screen_size_changed_cb (GdkScreen* screen, gpointer user_data)
{
    //remove early to avoid fatal X errors
    remove_timers ();

    root_width = gdk_screen_get_width(screen);
    root_height = gdk_screen_get_height(screen);
    g_debug ("screen_size_changed: root_width = %d", root_width);
    g_debug ("screen_size_changed: root_height = %d", root_height);

    const char* current_picture = get_current_picture_path ();
    g_settings_set_string (Settings, BG_CURRENT_PICT, current_picture);
    g_debug ("screen_size_changed_cb: end set string");
    start_gaussian_helper (current_picture);
    g_debug ("screen_size_changed_cb: end helper");

    GdkPixbuf* pb = get_xformed_gdk_pixbuf (current_picture);

    g_assert (pb != NULL);

    /*
     *	this is similar to initial setup. but we need to
     *	free previous pixmap first.
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

    g_debug ("screen_size_changed_cb: new_pixmap = 0x%x", (unsigned)new_pixmap);
    xfade_data_t* fade_data = g_new0 (xfade_data_t, 1);
    
    fade_data->pixmap = new_pixmap;
    fade_data->fading_surface = get_surface (new_pixmap);
    fade_data->end_pixbuf = pb;
    fade_data->alpha = 1.0;     

    draw_background (fade_data);
    free_fade_data (fade_data);

    if (gsettings_background_duration && picture_num > 1)
    {
	setup_background_timer ();
    }
}

DEEPIN_EXPORT void
bg_util_connect_screen_signals (GsdBackgroundManager* manager)
{
    // xrandr screen resolution handling
    g_signal_connect (gdk_screen, "size-changed", 
		      G_CALLBACK (screen_size_changed_cb), NULL);
    g_signal_connect (gdk_screen, "monitors-changed",
		      G_CALLBACK (screen_size_changed_cb), NULL);
}

DEEPIN_EXPORT void
bg_util_disconnect_screen_signals (GsdBackgroundManager* manager)
{
    g_signal_handlers_disconnect_by_func (gdk_screen, 
			   G_CALLBACK (screen_size_changed_cb), NULL);
}


static void
initial_setup (GSettings *settings)
{
    picture_paths = g_ptr_array_new_with_free_func (destroy_picture_path);

    picture_num = 0;
    picture_index = 0;

    gchar* bg_image_uri = g_settings_get_string (settings, BG_PICTURE_URIS);
    parse_picture_uris (bg_image_uri);
    free (bg_image_uri);

    gsettings_background_duration = g_settings_get_int (settings, BG_BG_DURATION);
    gsettings_xfade_manual_interval = g_settings_get_int (settings, BG_XFADE_MANUAL_INTERVAL);
    gsettings_xfade_auto_interval = g_settings_get_int (settings, BG_XFADE_AUTO_INTERVAL);

    gsettings_xfade_auto_mode = g_settings_get_enum (settings, BG_XFADE_AUTO_MODE);
    gsettings_draw_mode = g_settings_get_enum (settings, BG_DRAW_MODE);

    if (gsettings_xfade_auto_mode == XFADE_AUTO_MODE_RANDOM)
	g_debug ("XFADE_AUTO_MODE_RANDOM");
    else if (gsettings_xfade_auto_mode == XFADE_AUTO_MODE_SEQUENTIAL)
	g_debug ("XFADE_AUTO_MODE_SEQUENTIAL");

    if (gsettings_draw_mode == DRAW_MODE_TILING)
	g_debug ("DRAW_MODE_TILING");
    else if (gsettings_draw_mode == DRAW_MODE_SCALING)
	g_debug ("DRAW_MODE_SCALING");
    /*
     *	don't remove following comments:
     * 	to keep pixmap resource available
    */
    XSetCloseDownMode (display, RetainPermanent);

    const char* current_picture = get_current_picture_path ();
    g_settings_set_string (Settings, BG_CURRENT_PICT, current_picture);
    start_gaussian_helper (current_picture);

    GdkPixbuf* pb = get_xformed_gdk_pixbuf (current_picture);

    g_assert (pb != NULL);
    /*
     *	no previous background, no cross fade effect.
     *	this is most likely the situation when we first start up.
     *	resolution changed.
     */
    Pixmap new_pixmap = XCreatePixmap (display, root, 
				       root_width, root_height,
				       root_depth);

    xfade_data_t* fade_data = g_new0 (xfade_data_t, 1);
    
    fade_data->pixmap = new_pixmap;
    fade_data->fading_surface = get_surface (new_pixmap);
    fade_data->end_pixbuf = pb;
    fade_data->alpha = 1.0;     

    draw_background (fade_data);
    free_fade_data (fade_data);

    if (gsettings_background_duration && picture_num > 1)
    {
	setup_background_timer ();
    }

    return;
}

DEEPIN_EXPORT void
bg_util_init (GsdBackgroundManager* manager)
{
    display = GDK_DISPLAY_XDISPLAY(gdk_display_get_default());

    bg1_atom = gdk_x11_get_xatom_by_name(bg_props[0]);
    bg2_atom = gdk_x11_get_xatom_by_name(bg_props[1]);
    pixmap_atom = gdk_x11_get_xatom_by_name("PIXMAP");

    root = DefaultRootWindow(display);
    default_screen = DefaultScreen(display);
    root_depth = DefaultDepth(display, default_screen);
    root_visual = DefaultVisual(display, default_screen);
    root_width = DisplayWidth(display, default_screen);
    root_height = DisplayHeight(display, default_screen);

    gdk_screen = gdk_screen_get_default();

    manager->priv->settings = g_settings_new (BG_SCHEMA_ID);

    Settings = manager->priv->settings;

    g_signal_connect (manager->priv->settings, "changed::picture-uris",
		      G_CALLBACK (bg_settings_picture_uris_changed), NULL);
    g_signal_connect (manager->priv->settings, "changed::background-duration",
		      G_CALLBACK (bg_settings_bg_duration_changed), NULL);
    g_signal_connect (manager->priv->settings, "changed::cross-fade-manual-interval",
		      G_CALLBACK (bg_settings_xfade_manual_interval_changed), NULL);
    g_signal_connect (manager->priv->settings, "changed::cross-fade-auto-interval",
		      G_CALLBACK (bg_settings_xfade_auto_interval_changed), NULL);
    g_signal_connect (manager->priv->settings, "changed::cross-fade-auto-mode",
		      G_CALLBACK (bg_settings_xfade_auto_mode_changed), NULL);
    g_signal_connect (manager->priv->settings, "changed::draw-mode",
		      G_CALLBACK (bg_settings_draw_mode_changed), NULL);
    //serialize access to current_picture.
    g_signal_connect (manager->priv->settings, "changed::current-picture",
		      G_CALLBACK (bg_settings_current_picture_changed), NULL);

    initial_setup (manager->priv->settings);
}

