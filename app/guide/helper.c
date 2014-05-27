#include <gtk/gtk.h>
#include <X11/extensions/shape.h>
#include "X_misc.h"

GtkWidget* get_container();

void guide_disable_right_click()
{
    Display* dpy = GDK_DISPLAY_XDISPLAY(gdk_display_get_default());
    XGrabButton(dpy, Button3, AnyModifier, DefaultRootWindow(dpy), True, ButtonPressMask | ButtonReleaseMask, GrabModeAsync, GrabModeAsync, None, None);
}
void guide_enable_right_click()
{
    Display* dpy = GDK_DISPLAY_XDISPLAY(gdk_display_get_default());
    XUngrabButton(dpy, Button3, AnyModifier, DefaultRootWindow(dpy));
}
void guide_disable_keyboard()
{
    Display* dpy = GDK_DISPLAY_XDISPLAY(gdk_display_get_default());
    XGrabKeyboard(dpy, DefaultRootWindow(dpy), True, GrabModeAsync, GrabModeAsync, CurrentTime);
}
void guide_enable_keyboard()
{
    Display* dpy = GDK_DISPLAY_XDISPLAY(gdk_display_get_default());
    XUngrabKeyboard(dpy, CurrentTime);
}

void guide_disable_dock_region()
{
    //TODO: find the dock XID
    Window dock = 0x2a00004;
    return;

    Display* dpy = GDK_DISPLAY_XDISPLAY(gdk_display_get_default());
    cairo_region_t* dock_region = get_window_input_region(dpy, dock);
    gdk_window_input_shape_combine_region(gtk_widget_get_window(get_container()), dock_region, 0, 0);
    cairo_region_destroy(dock_region);
}

void guide_enable_dock_region()
{
    gdk_window_input_shape_combine_region(gtk_widget_get_window(get_container()), NULL, 0, 0);
}

