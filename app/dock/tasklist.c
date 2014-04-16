/**
 * Copyright (c) 2011 ~ 2013 Deepin, Inc.
 *               2011 ~ 2012 snyh
 *               2013 ~ 2013 Liqiang Lee
 *
 * Author:      snyh <snyh@snyh.org>
 * Maintainer:  snyh <snyh@snyh.org>
 *              Liqiang Lee <liliqiang@linuxdeepin.com>
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
#include "X_misc.h"
#include "pixbuf.h"
#include "utils.h"
#include "xid2aid.h"
// #include "launcher.h"
#include "dock_config.h"
#include "dominant_color.h"
#include "handle_icon.h"
#include "tasklist.h"
#include "dock_hide.h"
#include "region.h"
#include "special_window.h"
#include "xdg_misc.h"
#include "DBUS_dock.h"
#include "desktop_action.h"

#include <gtk/gtk.h>
#include <gdk/gdkx.h>
#include <X11/Xatom.h>
#include <dwebview.h>
#include <string.h>
#include <math.h>

PRIVATE Atom ATOM_ACTIVE_WINDOW;
PRIVATE Atom ATOM_CLOSE_WINDOW;
PRIVATE Atom ATOM_SHOW_DESKTOP;
PRIVATE Display* _dsp = NULL;
PRIVATE Atom ATOM_DEEPIN_SCREEN_VIEWPORT;


PRIVATE
void _init_atoms()
{
    ATOM_ACTIVE_WINDOW = gdk_x11_get_xatom_by_name("_NET_ACTIVE_WINDOW");
    ATOM_CLOSE_WINDOW = gdk_x11_get_xatom_by_name("_NET_CLOSE_WINDOW");
    ATOM_SHOW_DESKTOP = gdk_x11_get_xatom_by_name("_NET_SHOWING_DESKTOP");
    ATOM_DEEPIN_SCREEN_VIEWPORT = gdk_x11_get_xatom_by_name("DEEPIN_SCREEN_VIEWPORT");
}

typedef struct _Workspace Workspace;
struct _Workspace {
    int x, y;
};

static Workspace current_workspace = {0, 0};

// Key: GINT_TO_POINTER(the id of window)
// Value: struct Client*
Window active_client_id = 0;


JS_EXPORT_API
double dock_get_active_window()
{
    Window aw = 0;
#if 1
    get_atom_value_by_atom(_dsp, GDK_ROOT_WINDOW(), ATOM_ACTIVE_WINDOW, &aw, get_atom_value_for_index, 0);
#else
    gulong n_item;
    gpointer data = get_window_property(_dsp, GDK_ROOT_WINDOW(), ATOM_ACTIVE_WINDOW, &n_item);
    if (data == NULL)
        return 0;

    aw = X_FETCH_32(data, 0);
    XFree(data);
#endif

    return aw;
}

PRIVATE
void _update_current_viewport(Workspace* vp)
{
    gulong n_item;
    gpointer data = get_window_property(_dsp, GDK_ROOT_WINDOW(), ATOM_DEEPIN_SCREEN_VIEWPORT, &n_item);
    if (data == NULL)
        return;
    vp->x = X_FETCH_32(data, 0);
    vp->y = X_FETCH_32(data, 1);
    XFree(data);

    dock_update_hide_mode();
}


GdkFilterReturn monitor_root_change(GdkXEvent* xevent, GdkEvent *event, gpointer _nouse)
{
    NOUSED(event);
    NOUSED(_nouse);
    switch (((XEvent*)xevent)->type) {
    case PropertyNotify: {
        XPropertyEvent* ev = xevent;
        if (ev->atom == ATOM_SHOW_DESKTOP) {
            js_post_signal("desktop_status_changed");
        } else if (ev->atom == ATOM_DEEPIN_SCREEN_VIEWPORT) {
            _update_current_viewport(&current_workspace);
        }
    }
    }

    //NOTO: what's time should be we call this?
    //dock_update_hide_mode();
    return GDK_FILTER_CONTINUE;
}


void init_task_list()
{
    _dsp = GDK_DISPLAY_XDISPLAY(gdk_display_get_default());
    _init_atoms();

    GdkWindow* root = gdk_get_default_root_window();
    gdk_window_set_events(root, GDK_PROPERTY_CHANGE_MASK | gdk_window_get_events(root));

    gdk_window_add_filter(root, monitor_root_change, NULL);
}


JS_EXPORT_API
void dock_active_window(double id)
{
    XClientMessageEvent event;
    event.type = ClientMessage;
    event.window = (Window)id;
    event.message_type = ATOM_ACTIVE_WINDOW;
    event.format = 32;
    event.data.l[0] = 2; // we are a pager?
    XSendEvent(_dsp, GDK_ROOT_WINDOW(), False,
            StructureNotifyMask, (XEvent*)&event);
}


JS_EXPORT_API
int dock_close_window(double id)
{
    XClientMessageEvent event;
    event.type = ClientMessage;
    event.window = (Window)id;
    event.message_type = ATOM_CLOSE_WINDOW;
    event.format = 32;
    return XSendEvent(_dsp, GDK_ROOT_WINDOW(), False,
                      StructureNotifyMask, (XEvent*)&event);
}


JS_EXPORT_API
gboolean dock_get_desktop_status()
{
    gulong items;
    void* data = get_window_property(_dsp, GDK_ROOT_WINDOW(), ATOM_SHOW_DESKTOP, &items);
    if (data == NULL) return FALSE;
    long value = *(long*)data;
    XFree(data);
    return value;
}


DBUS_EXPORT_API
JS_EXPORT_API
void dock_show_desktop(gboolean value)
{
    Window root = GDK_ROOT_WINDOW();
    XClientMessageEvent event;
    event.type = ClientMessage;
    event.message_type = ATOM_SHOW_DESKTOP;
    event.format = 32;
    event.window = root;
    event.data.l[0] = value;
    XSendEvent(_dsp, root, False,
            StructureNotifyMask, (XEvent*)&event);
}

