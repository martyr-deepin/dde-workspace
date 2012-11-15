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
/*
 *	@pb : pixbuf for new background, we should ensure we 
 *	      don't pass a invalid pb. 	
 */
static void set_bg_props(GdkPixbuf* pb, Display* d)
{
	//don't remove following comments:
	//keep pixmap resource available
	//XSetCloseDownMode(d,RetainPermanent);
	
	g_assert(pb!=NULL);

	Window root = DefaultRootWindow(d);
	int screen = DefaultScreen(d);
	int depth = DefaultDepth(d,screen);
	Visual* v = DefaultVisual(d,screen);
	int width = DisplayWidth(d,screen);
	int height = DisplayHeight(d,screen);
	
	Pixmap pm = XCreatePixmap(d,root,width,height,depth);

	//create cairo surface for this pixmap.
	cairo_surface_t* cs=NULL;
	cs = cairo_xlib_surface_create(d,pm,v,width,height);
	if(cs==NULL)
	{	
		XFreePixmap(d,pm);
		g_object_unref(pb);
		return;	
	}

	cairo_t* cr = cairo_create(cs);
	if(cr==NULL)
	{
		g_object_unref(pb);
		cairo_surface_destroy(cs);
		XFreePixmap(d,pm);
		return;
	}

	gdk_cairo_set_source_pixbuf(cr,pb,0,0);

	cairo_paint(cr);

	//dispose
	cairo_destroy(cr);
	g_object_unref(pb);
	cairo_surface_destroy(cs);

	//change root window property.
	static const gchar* bgprops[2] = {"_XROOTPMAP_ID","ESETROOT_PMAP_ID"};
	Atom abg1 = gdk_x11_get_xatom_by_name(bgprops[0]);
	Atom abg2 = gdk_x11_get_xatom_by_name(bgprops[1]);
        Atom apm = gdk_x11_get_xatom_by_name("PIXMAP");

	//get previous properties.
	gulong nitems = 0;

	Pixmap pbg1 = None;
	Pixmap pbg2 = None;

	guchar* prop = NULL;
	prop = get_window_property(d, root, abg1, &nitems);
	if(prop)
	{
		pbg1 = X_FETCH_32(prop,0);
		g_free(prop);
	}
	prop = get_window_property(d, root, abg1, &nitems);
	if(prop)
	{
		pbg2 = X_FETCH_32(prop,0);
		g_free(prop);
	}
	//compare two pixmaps.
	g_assert(pbg1==pbg2);

	//free pixmaps
	XFreePixmap(d,pbg1);
	
	//set new background pixmaps.
	//use XA_PIXMAP instead.
	XChangeProperty(d,root,abg1,apm,32,PropModeReplace,(unsigned char*)&pm,1);
	XChangeProperty(d,root,abg2,apm,32,PropModeReplace,(unsigned char*)&pm,1);

	XFlush(d);
}

static GdkPixbuf* get_bg_pixbuf_from_gsettings(GSettings* settings)
{
	gchar* bg_image_uri = g_settings_get_string(settings, BG_IMAGE_KEY);
	gchar* bg_image = g_filename_from_uri(bg_image_uri,NULL,NULL);

	g_free(bg_image_uri);

	//creat pixbuf from image file
	GdkPixbuf* pb = gdk_pixbuf_new_from_file(bg_image, NULL);
	
	g_free(bg_image);

	return pb;
}

static void bg_changed(GSettings *settings, gchar* key, Display* _dsp)
{
	if (g_strcmp0(key,BG_IMAGE_KEY))
		return;
	
	GdkPixbuf* pb = get_bg_pixbuf_from_gsettings(settings);
	if(pb==NULL)
		return;

	set_bg_props(pb, _dsp);

	return;
}

void install_background_handler(void)
{
	Display* _dsp = GDK_DISPLAY_XDISPLAY(gdk_display_get_default());

	GSettings* bg_setting = g_settings_new (BG_SCHEMA_ID);
	g_signal_connect(bg_setting,"changed", G_CALLBACK(bg_changed), _dsp);

	GdkPixbuf* pb = get_bg_pixbuf_from_gsettings(bg_setting);
	if(pb==NULL) //just return.
		return;

	set_bg_props(pb, _dsp);
}
