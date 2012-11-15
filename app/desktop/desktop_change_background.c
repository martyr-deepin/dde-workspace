#include <X11/X.h>
#include <gdk-pixbuf/gdk-pixbuf.h>
#include <gdk/gdk.h>
#include <cairo.h>
#include <cairo-xlib.h>
#include <gtk/gtk.h>
#include <gio/gio.h>

#define BG_SCHEMA_ID "org.gnome.desktop.background"
#define BG_IMAGE_KEY "picture-uri"
/*
 * 	@image : background image file path.
 * 	
 */
static void set_bg_props(gchar* image)
{
	//create a pixmap
	Display* d=XOpenDisplay(NULL);
	//keep pixmap resource available
	XSetCloseDownMode(d,RetainPermanent);
	Window root=DefaultRootWindow(d);
	
	int screen=DefaultScreen(d);
	int depth=DefaultDepth(d,screen);

	Visual* v=DefaultVisual(d,screen);
	int width=DisplayWidth(d,screen);
	int height=DisplayHeight(d,screen);
	Pixmap pm=XCreatePixmap(d,root,width,height,depth);

	//create cairo surface for this pixmap.
	cairo_surface_t* cs=cairo_xlib_surface_create(d,pm,v,width,height);
	
	//creat pixbuf from image file
	GdkPixbuf* pb=gdk_pixbuf_new_from_file(image, NULL);
	g_assert(pb != NULL);

	cairo_t* cr=cairo_create(cs);
	gdk_cairo_set_source_pixbuf(cr,pb,0,0);

	cairo_paint(cr);

	cairo_surface_write_to_png(cs, "sd.png");

	//change root window property.
	static char* bgprops[2]={"_XROOTPMAP_ID","ESETROOT_PMAP_ID"};
	Atom abg1=XInternAtom(d,bgprops[0],False);
	Atom abg2=XInternAtom(d,bgprops[1],False);
        Atom apm=XInternAtom(d,"PIXMAP",False);

	//get previous properties.
	Atom actual_type;
	int  actual_format;
	unsigned nitems;
	unsigned bytes_after;
	unsigned char* prop;

	Pixmap pbg1=None;
	Pixmap pbg2=None;

	if(XGetWindowProperty(d,root,abg1,0,4,False,AnyPropertyType,
			&actual_type,&actual_format,&nitems,&bytes_after,&prop)==Success&&
	   actual_type==apm&&actual_format==32&&nitems==1)
	{
		memcpy(&pbg1,prop,4);
		XFree(prop);
	}	

	if(XGetWindowProperty(d,root,abg2,0,4,False,AnyPropertyType,
			&actual_type,&actual_format,&nitems,&bytes_after,&prop)==Success&&
	   actual_type==apm&&actual_format==32&&nitems==1)
	{
		memcpy(&pbg2,prop,4);
		XFree(prop);
	}	
	//compare two pixmaps.
	//g_assert(pbg1!=None);
	//g_assert(pbg2!=None);
	//g_assert(pbg1==pbg2);

	//free pixmaps?
	XFreePixmap(d,pbg1);
	
	//set new background pixmaps.
	//use XA_PIXMAP instead.
	XChangeProperty(d,root,abg1,apm,32,PropModeReplace,(unsigned char*)&pm,1);
	XChangeProperty(d,root,abg2,apm,32,PropModeReplace,(unsigned char*)&pm,1);

	XFlush(d);
	XCloseDisplay(d);
}

static gchar* get_bg_image_from_gsettings(GSettings* settings)
{
	gchar* bg_image_uri = g_settings_get_string(settings, BG_IMAGE_KEY);
	gchar* bg_image = g_filename_from_uri(bg_image_uri,NULL,NULL);

	return bg_image;
}

static void bg_changed(GSettings *settings, gchar* key, gpointer user_data)
{
	if (g_strcmp0(key,BG_IMAGE_KEY))
		return;
	gchar* bg_image=get_bg_image_from_gsettings(settings);

	set_bg_props(bg_image);

	return;
}

void install_background_handler(void)
{
	GSettings* bg_setting = g_settings_new (BG_SCHEMA_ID);
	g_signal_connect(bg_setting,"changed", G_CALLBACK(bg_changed),NULL);

	gchar* bg_image=get_bg_image_from_gsettings(bg_setting);
	set_bg_props(bg_image);
}



