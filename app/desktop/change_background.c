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
 * 	@image : background image file path.
 * 	
 */
static void set_bg_props(gchar* image, Display* d)
{
	//keep pixmap resource available
	//XSetCloseDownMode(d,RetainPermanent);

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
		g_free(image);
		return;	
	}
	//creat pixbuf from image file
	GdkPixbuf* pb = gdk_pixbuf_new_from_file(image, NULL);
	if(pb==NULL)
	{
		cairo_surface_destroy(cs);
		XFreePixmap(d,pm);
		g_free(image);
		return;
	}

	cairo_t* cr = cairo_create(cs);
	if(cr==NULL)
	{
		g_object_unref(pb);
		cairo_surface_destroy(cs);
		XFreePixmap(d,pm);
		g_free(image);
		return;
	}

	gdk_cairo_set_source_pixbuf(cr,pb,0,0);

	cairo_paint(cr);

	//dispose
	cairo_destroy(cr);
	g_object_unref(pb);
	cairo_surface_destroy(cs);
	g_free(image);

	//change root window property.
	static char* bgprops[2] = {"_XROOTPMAP_ID","ESETROOT_PMAP_ID"};
	Atom abg1 = XInternAtom(d,bgprops[0],False);
	Atom abg2 = XInternAtom(d,bgprops[1],False);
        Atom apm = XInternAtom(d,"PIXMAP",False);

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

static gchar* get_bg_image_from_gsettings(GSettings* settings)
{
	gchar* bg_image_uri = g_settings_get_string(settings, BG_IMAGE_KEY);
	gchar* bg_image = g_filename_from_uri(bg_image_uri,NULL,NULL);

	g_free(bg_image_uri);


	return bg_image;
}

static void bg_changed(GSettings *settings, gchar* key, Display* _dsp)
{
	if (g_strcmp0(key,BG_IMAGE_KEY))
		return;
	gchar* bg_image=get_bg_image_from_gsettings(settings);

	set_bg_props(bg_image, _dsp);

	return;
}

void install_background_handler(void)
{
	Display* _dsp = GDK_DISPLAY_XDISPLAY(gdk_display_get_default());

	GSettings* bg_setting = g_settings_new (BG_SCHEMA_ID);
	g_signal_connect(bg_setting,"changed", G_CALLBACK(bg_changed), _dsp);

	gchar* bg_image=get_bg_image_from_gsettings(bg_setting);

	set_bg_props(bg_image, _dsp);
}
