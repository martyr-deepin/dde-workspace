/**
 * Copyright (c) 2011 ~ 2012 Deepin, Inc.
 *               2011 ~ 2012 snyh
 *
 * Author:      snyh <snyh@snyh.org>
 * Maintainer:  snyh <snyh@snyh.org>
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

void set_wmspec_dock_hint(GdkWindow *window)
{
    GdkAtom atom = gdk_atom_intern ("_NET_WM_WINDOW_TYPE_DOCK", FALSE);

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
        js_post_message_simply("workarea_changed", tmp);
        g_free(tmp);
    }
    return GDK_FILTER_CONTINUE;
}


void watch_workarea_changes(GtkWidget* widget)
{

    GdkScreen *gscreen = gtk_widget_get_screen(widget);
    GdkWindow *groot = gdk_screen_get_root_window(gscreen);
    gdk_window_set_events(groot, gdk_window_get_events(groot) | GDK_PROPERTY_CHANGE_MASK);
    //TODO: remove this filter when unrealize
    gdk_window_add_filter(groot, watch_workarea, NULL);
}

void unwatch_workarea_changes(GtkWidget* widget)
{
    GdkScreen *gscreen = gtk_widget_get_screen(widget);
    GdkWindow *groot = gdk_screen_get_root_window(gscreen);
    gdk_window_remove_filter(groot, watch_workarea, NULL);
}


/* from libwnck/xutils.c, comes as LGPLv2+ */
static char *
latin1_to_utf8 (const char *latin1)
{
  GString *str;
  const char *p;

  str = g_string_new (NULL);

  p = latin1;
  while (*p)
    {
      g_string_append_unichar (str, (gunichar) *p);
      ++p;
    }

  return g_string_free (str, FALSE);
}

#include <gdk/gdkx.h>
/* derived from libwnck/xutils.c, comes as LGPLv2+ */
void get_wmclass (GdkWindow* xwindow, char **res_class, char **res_name)
{
  XClassHint ch;

  ch.res_name = NULL;
  ch.res_class = NULL;

  gdk_error_trap_push ();
  XGetClassHint (GDK_DISPLAY_XDISPLAY(gdk_display_get_default()), GDK_WINDOW_XID(xwindow), &ch);
  gdk_error_trap_pop_ignored ();

  if (res_class)
    *res_class = NULL;

  if (res_name)
    *res_name = NULL;

  if (ch.res_name)
    {
      if (res_name)
        *res_name = latin1_to_utf8 (ch.res_name);

      XFree (ch.res_name);
    }

  if (ch.res_class)
    {
      if (res_class)
        *res_class = latin1_to_utf8 (ch.res_class);

      XFree (ch.res_class);
    }
}

enum {
	STRUT_LEFT = 0,
	STRUT_RIGHT = 1,
	STRUT_TOP = 2,
	STRUT_BOTTOM = 3,
	STRUT_LEFT_START = 4,
	STRUT_LEFT_END = 5,
	STRUT_RIGHT_START = 6,
	STRUT_RIGHT_END = 7,
	STRUT_TOP_START = 8,
	STRUT_TOP_END = 9,
	STRUT_BOTTOM_START = 10,
	STRUT_BOTTOM_END = 11
};


static Atom net_wm_strut_partial      = None;
void set_struct_partial(GdkWindow* gdk_window, guint32 orientation, guint32 strut, guint32 strut_start, guint32 strut_end)
{
    Display *display;
    Window   window;
    gulong   struts [12] = { 0, };

    g_return_if_fail (GDK_IS_WINDOW (gdk_window));

    display = GDK_WINDOW_XDISPLAY (gdk_window);
    window  = GDK_WINDOW_XID (gdk_window);

    if (net_wm_strut_partial == None)
        net_wm_strut_partial = XInternAtom (display, "_NET_WM_STRUT_PARTIAL", False);

    switch (orientation) {
        case ORIENTATION_LEFT:
            struts [STRUT_LEFT] = strut;
            struts [STRUT_LEFT_START] = strut_start;
            struts [STRUT_LEFT_END] = strut_end;
            break;
        case ORIENTATION_RIGHT:
            struts [STRUT_RIGHT] = strut;
            struts [STRUT_RIGHT_START] = strut_start;
            struts [STRUT_RIGHT_END] = strut_end;
            break;
        case ORIENTATION_TOP:
            struts [STRUT_TOP] = strut;
            struts [STRUT_TOP_START] = strut_start;
            struts [STRUT_TOP_END] = strut_end;
            break;
        case ORIENTATION_BOTTOM:
            struts [STRUT_BOTTOM] = strut;
            struts [STRUT_BOTTOM_START] = strut_start;
            struts [STRUT_BOTTOM_END] = strut_end;
            break;
    }

    gdk_error_trap_push ();
    XChangeProperty (display, window, net_wm_strut_partial,
            XA_CARDINAL, 32, PropModeReplace,
            (guchar *) &struts, 12);
    gdk_error_trap_pop_ignored ();
}


void* get_window_property(Display* dsp, Window w, Atom pro, gulong* items)
{
    g_return_val_if_fail(pro != 0, NULL);
    Atom act_type;
    int act_format;
    gulong bytes_after;
    guchar* p_data = NULL;

    gdk_error_trap_push();
    int result = XGetWindowProperty(dsp, w, pro,
            0, G_MAXULONG, FALSE,
            AnyPropertyType, &act_type,
            &act_format,
            items,
            &bytes_after,
            (void*)&p_data);
    int err = gdk_error_trap_pop();

    if (err != Success || result != Success) {
        g_warning("get_window_property error... %d %d\n", (int)w, (int)pro);
        return NULL;
    } else {
        return p_data;
    }
}


