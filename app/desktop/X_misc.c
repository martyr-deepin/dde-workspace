#include <gtk/gtk.h>
#include <gdk/gdkx.h>
#include <X11/Xlib.h>
#include <X11/Xatom.h>
#include "X_misc.h"
#include "dwebview.h"

void set_wmspec_desktop_hint (GdkWindow *window)
{
    GdkAtom atom = gdk_atom_intern ("_NET_WM_WINDOW_TYPE_DESKTOP", FALSE);

    gdk_property_change (window,
            gdk_atom_intern ("_NET_WM_WINDOW_TYPE", FALSE),
            gdk_x11_xatom_to_atom (XA_ATOM), 32,
            GDK_PROP_MODE_REPLACE, (guchar *) &atom, 1);
}

void get_workarea_size(int screen_n, int desktop_n, 
        int* x, int* y, int* width, int* height)
{
    GdkDisplay* gdpy = gdk_display_get_default();
    GdkScreen* gscreen = gdk_display_get_screen(gdpy, screen_n);
    Display *dpy = GDK_DISPLAY_XDISPLAY(gdpy);
    Window root = GDK_WINDOW_XID(gdk_screen_get_root_window(gscreen));
    Atom property = XInternAtom(dpy, "_NET_WORKAREA", False);
    Atom actual_type = None;
    gint actual_format = 0;
    gulong nitems = 0;
    gulong bytes_after = 0;
    unsigned char *data_p = NULL;
    XGetWindowProperty(dpy, root, property, 0, G_MAXULONG, False, XA_CARDINAL,
            &actual_type, &actual_format, &nitems, &bytes_after, &data_p);


    g_assert(desktop_n < nitems / 4);
    g_assert(bytes_after == 0);
    g_assert(actual_format == 32);

    // Although the actual_format is 32 bit, but the f**k xlib specified it format equal 
    // sizeof(long), eg on 64 bit os the value is 8 byte.
    gulong *data = (gulong*)(data_p + desktop_n * sizeof(long) * 4);

    *x = data[0];
    *y = data[1];
    *width = data[2];
    *height = data[3];

    XFree(data_p);
}


static GdkFilterReturn watch_workarea(GdkXEvent *gxevent, GdkEvent* event, gpointer user_data)
{
    XPropertyEvent *xevt = (XPropertyEvent*)gxevent;

    if (xevt->type == PropertyNotify && 
            XInternAtom(xevt->display, "_NET_WORKAREA", False) == xevt->atom) {
        g_message("GET _NET_WORKAREA change on rootwindow");

        int x, y, width, height;
        get_workarea_size(0, 0, &x, &y, &width, &height);
        char* tmp = g_strdup_printf("{\"x\":%d, \"y\":%d, \"width\":%d, \"height\":%d}",
                x, y, width, height);
        js_post_message("workarea_changed", tmp);
        g_free(tmp);
    }
    return GDK_FILTER_CONTINUE;
}


static
void watch_workarea_changes(GtkWidget* widget)
{

    GdkScreen *gscreen = gtk_widget_get_screen(widget);
    GdkWindow *groot = gdk_screen_get_root_window(gscreen);
    gdk_window_set_events(groot, gdk_window_get_events(groot) | GDK_PROPERTY_CHANGE_MASK);
    //TODO: remove this filter when unrealize
    gdk_window_add_filter(groot, watch_workarea, NULL);
}

static
void unwatch_workarea_changes(GtkWidget* widget)
{
    GdkScreen *gscreen = gtk_widget_get_screen(widget);
    GdkWindow *groot = gdk_screen_get_root_window(gscreen);
    gdk_window_remove_filter(groot, watch_workarea, NULL);
}
