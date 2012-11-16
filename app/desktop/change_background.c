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
#include <X11/X.h>
#include <gdk-pixbuf/gdk-pixbuf.h>
#include <gdk/gdk.h>
#include <cairo.h>
#include <cairo-xlib.h>
#include <gtk/gtk.h>
#include <gio/gio.h>

#include "X_misc.h"

#define BG_SCHEMA_ID "org.gnome.desktop.background"
#define BG_IMAGE_KEY "picture-uri"


#define USEC_PER_SEC 1000000.0 // microseconds per second 
#define MSEC_PER_SEC 1000.0    // milliseconds per second 
//TODO: get these values from gsettings.
#define BG_INTERVAL 0.05 //in seconds 
#define BG_DURATION 1.0 //in seconds

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

//
static gboolean	initialized = FALSE;

//global timeout_id to track in process timeoutout
static guint	timeout_id = 0;
//

/*
 * 	all the time are in seconds.
 */
typedef struct _xfade_data
{
	//all in seconds.
	gdouble		 start_time;
	gdouble		 total_duration;
	gdouble		 interval;
	
	cairo_surface_t* fading_surface;
	GdkPixbuf* 	 end_pixbuf;
	gdouble		 alpha;

	Pixmap		pixmap;
}xfade_data_t;

/*
 *	change root window x properties.
 *	TODO: change set_bg_props or _change_bg_xproperties 
 *	      to a better name.
 */
static void _change_bg_xproperties(Pixmap pm)
{
	XChangeProperty(display, root, bg1_atom, pixmap_atom,
			32, PropModeReplace, (unsigned char*)&pm,1);
	XChangeProperty(display, root, bg2_atom, pixmap_atom,
			32, PropModeReplace, (unsigned char*)&pm,1);
	XFlush(display);
}
/*
 *    compositing two cairo surfaces. 
 */
static void draw_background(xfade_data_t* fade_data)
{
	cairo_t* cr;
	cr = cairo_create(fade_data->fading_surface);

	gdk_cairo_set_source_pixbuf(cr, fade_data->end_pixbuf, 0, 0);
	cairo_paint_with_alpha (cr, fade_data->alpha);

	cairo_destroy (cr);

	_change_bg_xproperties(fade_data->pixmap);
}
        	
/*
 * 	free fade_data and its fields.
 */
static void free_fade_data(xfade_data_t* fade_data)
{
	cairo_surface_destroy(fade_data->fading_surface);
 	g_object_unref(fade_data->end_pixbuf);
	g_free(fade_data);
}

/*
 *	return current time in seconds.
 */
static gdouble get_current_time (void)
{
	double timestamp;
	GTimeVal now;

	g_get_current_time (&now);

	timestamp = ((USEC_PER_SEC * now.tv_sec) + now.tv_usec) / USEC_PER_SEC;

	return timestamp;
}
static gboolean on_tick(gpointer user_data)
{
	xfade_data_t* fade_data = (xfade_data_t*)user_data;

	gdouble cur_time;
	cur_time = get_current_time();

	fade_data->alpha = (cur_time - fade_data->start_time) / fade_data->total_duration;
	fade_data->alpha = CLAMP (fade_data->alpha, 0.0, 1.0);

	draw_background(fade_data);

	static int i=0;
	printf("tick %d\n",++i);
	printf("cur_time : %lf\n", cur_time);
	printf("alpha	 : %lf\n", fade_data->alpha);

	// 'coz fade_data->alpha is a rough value
	if(fade_data->alpha >=0.9)
		return FALSE;

	return TRUE;
}
static void on_finished(gpointer user_data)
{
	xfade_data_t* fade_data = (xfade_data_t*) user_data;

	fade_data->alpha = 1.0;

	draw_background(fade_data);

	free_fade_data(fade_data);
	printf("crossfade finished \n");
}
/*
 * 	setup cross fade timer and callback.
 */
static void crossfade_start(xfade_data_t* fade_data)
{
	fade_data->start_time = get_current_time(); 
	printf("start_time : %lf\n", fade_data->start_time);
	printf("interval   : %lf\n", fade_data->interval);
	GSource* source = g_timeout_source_new(fade_data->interval*MSEC_PER_SEC);

	g_source_set_callback(source, (GSourceFunc) on_tick, fade_data, (GDestroyNotify)on_finished);

	timeout_id = g_source_attach(source, g_main_context_default());
}
static void crossfade_stop()
{
	g_source_remove(timeout_id);
	timeout_id = 0;
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
static Pixmap get_previous_background()
{
	printf(" enter get_previous_background:\n");
	//get previous properties.
	gulong nitems = 0;

	Pixmap pbg1 = None;
	Pixmap pbg2 = None;

	guchar* prop = NULL;
	prop = get_window_property(display, root, bg1_atom, &nitems);
	if(prop)
	{
		pbg1 = X_FETCH_32(prop,0);
		g_free(prop);
	}
	prop = get_window_property(display, root, bg2_atom, &nitems);
	if(prop)
	{
		pbg2 = X_FETCH_32(prop,0);
		g_free(prop);
	}
	//compare two pixmaps.
	g_assert(pbg1==pbg2);

	//check whether the pixmap exists
	Window _root;
	int _x,_y;
	unsigned int _width,_height;
	unsigned int _border,_depth;
	/*
	 * 	TODO: how to reliably check the existence of a pixmap.
	 */
	
	if(pbg1!=None)
	{
		gdk_error_trap_push();
		Status _s = XGetGeometry(display, pbg1, &_root,
		                &_x,&_y,&_width,&_height,
		                &_border,&_depth);
		if((_s==0)||(_width!=root_width)||(_height!=root_height))
		{
			// the drawable have been freed or resolution changed.
			pbg1 = None;
		}
		gdk_error_trap_pop();
	}

	printf("prev_pixmap = 0x%x\n", (unsigned) pbg1);
	printf("leaving get_previous_background:\n");
	return pbg1;
}

/*
 * 	create a cairo surface from a pixmap. this is where 
 * 	we're drawing on
 * 	NOTE: @pixmap should not be None.
 * 	TODO: we assume that @pixmap is the same size as the
 * 	      root_window. if that's not tree, scale it.
 */
static cairo_surface_t* get_surface(Pixmap pixmap)
{
	cairo_surface_t* cs=NULL;
	cs = cairo_xlib_surface_create(display, pixmap, 
			               root_visual, 
				       root_width, root_height);
	
	return cs;
}
/*
 *	@pb : pixbuf for new background, we should ensure 
 *	      that pb is not null.
 */
static void set_bg_props(GdkPixbuf* pb)
{
	//don't remove following comments:
	//to keep pixmap resource available
	XSetCloseDownMode(display, RetainPermanent);
	g_assert(pb!=NULL);

	xfade_data_t* fade_data = g_new0(xfade_data_t, 1);

	Pixmap prev_pixmap = get_previous_background();
	
	if(initialized&&(prev_pixmap!=None))
	{
		// cross fade 
		//TODO: scale prev_pixmap to root window size.
		fade_data->pixmap = prev_pixmap;
		fade_data->fading_surface = get_surface(prev_pixmap);
		fade_data->end_pixbuf = pb;
		//TODO: get this from gsettings.
		fade_data->total_duration = BG_DURATION;
		fade_data->interval = BG_INTERVAL;
		
		printf("we've setup fade_data\n");

		if(timeout_id!=0)
			crossfade_stop();
		crossfade_start(fade_data);
		// free fade_data in on_finished
		// reuse pixman. no need to change background xproperty.
		// if this causes problems, we need to set a new Pixmap.
	}
	else
	{
		//no previous background, no cross fade effect.
		//this is most likely the situation when we first start up.
		//resolution changed.
		Pixmap new_pixmap = XCreatePixmap(display, root, 
				          root_width,root_height,
					  root_depth);

		fade_data->pixmap = new_pixmap;
		fade_data->fading_surface = get_surface(new_pixmap);
		fade_data->end_pixbuf = pb;
		fade_data->alpha = 1.0;     

		draw_background(fade_data);
		free_fade_data(fade_data);

		initialized = TRUE;
	}
}

static GdkPixbuf* get_bg_pixbuf_from_gsettings(GSettings* settings)
{
	gchar* bg_image_uri = g_settings_get_string(settings, BG_IMAGE_KEY);
	gchar* bg_image = g_filename_from_uri(bg_image_uri,NULL,NULL);

	g_free(bg_image_uri);

	//creat pixbuf from image file
	GdkPixbuf* pb = gdk_pixbuf_new_from_file(bg_image, NULL);

	printf("background image: %s\n", bg_image);
	
	g_free(bg_image);

	return pb;
}

static void bg_changed(GSettings *settings, gchar* key, gpointer user_data)
{
	if (g_strcmp0(key,BG_IMAGE_KEY))
		return;
	
	GdkPixbuf* pb = get_bg_pixbuf_from_gsettings(settings);
	if(pb==NULL)
		return;

	set_bg_props(pb);

	return;
}

static void screen_size_changed(GdkScreen* screen, gpointer user_data)
{
	root_width = gdk_screen_get_width(screen);
	root_height = gdk_screen_get_height(screen);

	//TODO: change root bg xproperty.
	
	GSettings* settings = (GSettings*) user_data;
	GdkPixbuf* pb = get_bg_pixbuf_from_gsettings(settings);
	if(pb==NULL)
		return;
	set_bg_props(pb);
}

void install_background_handler(void)
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

	initialized = FALSE;

	GdkScreen* gdk_screen = gdk_screen_get_default();

	GSettings* bg_setting = g_settings_new (BG_SCHEMA_ID);

	g_signal_connect(bg_setting,"changed", G_CALLBACK(bg_changed), NULL);
	g_signal_connect(gdk_screen,"size-changed", G_CALLBACK(screen_size_changed), bg_setting);

	GdkPixbuf* pb = get_bg_pixbuf_from_gsettings(bg_setting);
	if(pb==NULL) //just return.
		return;

	set_bg_props(pb);

}
