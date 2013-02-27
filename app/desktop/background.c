#include "X_misc.h"
#include <gdk/gdkx.h>
#include <gtk/gtk.h>
#include <cairo/cairo-xlib.h>

GdkWindow* get_background_window();
Atom ATOM_ROOT_PIXMAP = 0;

void update_root_pixmap()
{
    Display *_dsp = GDK_DISPLAY_XDISPLAY(gdk_display_get_default());
    long items = 0;
    void* data = get_window_property(_dsp, GDK_ROOT_WINDOW(), ATOM_ROOT_PIXMAP,
            &items);
    if (data != NULL) {
        Pixmap ROOT_PIXMAP = X_FETCH_32(data, 0);

        GdkWindow* w = get_background_window();
        GdkScreen *screen = gdk_screen_get_default();
        int s_width = gdk_screen_get_width(screen);
        int s_height = gdk_screen_get_height(screen);
        GdkVisual *visual = gdk_screen_get_system_visual (screen);
        cairo_surface_t* surface = cairo_xlib_surface_create(_dsp, ROOT_PIXMAP, GDK_VISUAL_XVISUAL(visual), s_width, s_height);
        cairo_pattern_t* pt = cairo_pattern_create_for_surface(surface);
        gdk_window_hide(w);
        gdk_window_set_background_pattern(w, pt);
        gdk_window_show(w);
        gdk_window_lower(w);

        cairo_surface_destroy(surface);
    }
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

        attributes.width = 0;
        attributes.height = 0;
        attributes.window_type = GDK_WINDOW_CHILD;
        attributes.wclass = GDK_INPUT_OUTPUT;
        attributes.event_mask = GDK_EXPOSURE_MASK;

        _background_window = gdk_window_new(NULL, &attributes, 0);
        set_wmspec_desktop_hint(_background_window);

        update_root_pixmap();
        gdk_window_move_resize(_background_window, 0, 0,
                gdk_window_get_width(root),
                gdk_window_get_height(root)
                );
        gdk_window_show(_background_window);
    }
    return _background_window;
}
