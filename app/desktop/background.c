#include "X_misc.h"
#include <gdk/gdkx.h>
#include <gtk/gtk.h>
#include <cairo/cairo-xlib.h>

Atom ATOM_ROOT_PIXMAP = 0;

GdkWindow* get_background_window();
gboolean update_root_pixmap()
{
    Display *_dsp = GDK_DISPLAY_XDISPLAY(gdk_display_get_default());
    long items = 0;
    void* data = get_window_property(_dsp, GDK_ROOT_WINDOW(), ATOM_ROOT_PIXMAP,
            &items);
    if (data != NULL) {
        Pixmap ROOT_PIXMAP = X_FETCH_32(data, 0);

        cairo_t* _background_cairo = gdk_cairo_create(get_background_window());
        g_assert(cairo_status(_background_cairo) == CAIRO_STATUS_SUCCESS);
        g_assert(cairo_status(_background_cairo) == CAIRO_STATUS_SUCCESS);
        GdkScreen *screen = gdk_screen_get_default();
        g_assert(screen);
        int s_width = gdk_screen_get_width(screen);
        int s_height = gdk_screen_get_height(screen);
        g_assert(s_width > 800 && s_height > 600);
        GdkVisual *visual = gdk_screen_get_system_visual (screen);
        g_assert(visual);
        cairo_surface_t* surface = cairo_xlib_surface_create(_dsp, ROOT_PIXMAP, GDK_VISUAL_XVISUAL(visual), s_width, s_height);
        g_assert(cairo_status(_background_cairo) == CAIRO_STATUS_SUCCESS);
        g_assert(surface != NULL);
        g_assert(_background_cairo != NULL);

        cairo_set_source_surface(_background_cairo, surface, 0, 0);
        g_assert(cairo_status(_background_cairo) == CAIRO_STATUS_SUCCESS);
        cairo_paint(_background_cairo);
        g_assert(cairo_status(_background_cairo) == CAIRO_STATUS_SUCCESS);
        cairo_surface_destroy(surface);
        cairo_destroy(_background_cairo);
    } else {
        cairo_t* _background_cairo = gdk_cairo_create(get_background_window());
        g_assert(cairo_status(_background_cairo) == CAIRO_STATUS_SUCCESS);
        cairo_set_source_rgb(_background_cairo, 1, 1, 1);
        g_assert(cairo_status(_background_cairo) == CAIRO_STATUS_SUCCESS);
        cairo_paint(_background_cairo);
        g_assert(cairo_status(_background_cairo) == CAIRO_STATUS_SUCCESS);
        cairo_destroy(_background_cairo);
    }
    return FALSE;
}

GdkFilterReturn monitor_root_change(GdkXEvent *xevent, GdkEvent *event, gpointer data)
{
    if (((XEvent*)xevent)->type == PropertyNotify) {
        XPropertyEvent* ev = xevent;
        if (ev->atom == ATOM_ROOT_PIXMAP) {
            update_root_pixmap();
        } 
    } 
    return GDK_FILTER_CONTINUE;
}

static GdkWindow* _background_window = NULL;
GdkWindow* get_background_window()
{
    if (_background_window == NULL) {
        ATOM_ROOT_PIXMAP = gdk_x11_get_xatom_by_name("_XROOTPMAP_ID");
        GdkWindow* root = gdk_get_default_root_window();
        gdk_window_set_events(root, GDK_PROPERTY_CHANGE_MASK | gdk_window_get_events(root));
        gdk_window_add_filter(root, monitor_root_change, NULL);

        GdkWindowAttr attributes;
        attributes.window_type = GDK_WINDOW_CHILD;
        attributes.wclass = GDK_INPUT_OUTPUT;
        attributes.event_mask = GDK_EXPOSURE_MASK;

        _background_window = gdk_window_new(NULL, &attributes, 0);
        GdkRGBA rgba = {0, 0, 0, 0};
        gdk_window_set_background_rgba(_background_window, &rgba);

        set_wmspec_desktop_hint(_background_window);
        gdk_window_move_resize(_background_window, 0, 0, 
                gdk_window_get_width(root),
                gdk_window_get_height(root)
                );
        gdk_window_show(_background_window);
        g_idle_add(update_root_pixmap, NULL);
        g_timeout_add(300, update_root_pixmap, NULL);
        g_timeout_add(600, update_root_pixmap, NULL);
        g_timeout_add(1000, update_root_pixmap, NULL);
        g_timeout_add(2500, update_root_pixmap, NULL);
    }
    return _background_window;
}
