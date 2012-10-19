#include "jsextension.h"
#include <glib.h>
#include <string.h>
#include "xdg_misc.h"
#include "dwebview.h"

char* get_desktop_items()
{
    return get_desktop_entries();
}

//TODO: remvoe this( this code should be under app/desktop/X_misc.c)
#include <X11/Xlib.h>
#include <X11/Xatom.h>
#include <gdk/gdkx.h>
void notify_workarea_size()
{
    GdkDisplay* gdpy = gdk_display_get_default();
    GdkScreen* gscreen = gdk_display_get_screen(gdpy, 0);
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


    gulong *data = (gulong*)(data_p + 0 * sizeof(long) * 4);

    char* tmp = g_strdup_printf("{\"x\":%d, \"y\":%d, \"width\":%d, \"height\":%d}",
            (int)data[0], (int)data[1], (int)data[2], (int)data[3]);

    XFree(data_p);
    js_post_message("workarea_changed", tmp);
}
