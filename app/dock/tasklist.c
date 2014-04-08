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
#include "launcher.h"
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
extern Window get_dock_window();
extern char* dcore_get_theme_icon(const char*, double);

#include <gtk/gtk.h>
#include <gdk/gdkx.h>
#include <X11/Xatom.h>
#include <dwebview.h>
#include <string.h>
#include <math.h>
#include <gio/gdesktopappinfo.h>

#define RECORD_FILE "dock/record.ini"
#define FILTER_FILE "dock/filter.ini"
GKeyFile* record_file = NULL;

PRIVATE Atom ATOM_ACTIVE_WINDOW;
PRIVATE Atom ATOM_WINDOW_ICON;
PRIVATE Atom ATOM_WINDOW_TYPE;
/* PRIVATE Atom ATOM_WINDOW_TYPE_KDE_OVERRIDE; */
PRIVATE Atom ATOM_CLOSE_WINDOW;
PRIVATE Atom ATOM_SHOW_DESKTOP;
PRIVATE Display* _dsp = NULL;
PRIVATE Atom ATOM_DEEPIN_WINDOW_VIEWPORTS;
PRIVATE Atom ATOM_DEEPIN_SCREEN_VIEWPORT;
PRIVATE Atom ATOM_CLIENT_LIST;


PRIVATE
void _init_atoms()
{
    ATOM_CLIENT_LIST = gdk_x11_get_xatom_by_name("_NET_CLIENT_LIST");
    ATOM_ACTIVE_WINDOW = gdk_x11_get_xatom_by_name("_NET_ACTIVE_WINDOW");
    ATOM_WINDOW_ICON = gdk_x11_get_xatom_by_name("_NET_WM_ICON");
    ATOM_WINDOW_TYPE = gdk_x11_get_xatom_by_name("_NET_WM_WINDOW_TYPE");
    /* ATOM_WINDOW_TYPE_KDE_OVERRIDE = gdk_x11_get_xatom_by_name("_KDE_NET_WM_WINDOW_TYPE_OVERRIDE"); */
    ATOM_CLOSE_WINDOW = gdk_x11_get_xatom_by_name("_NET_CLOSE_WINDOW");
    ATOM_SHOW_DESKTOP = gdk_x11_get_xatom_by_name("_NET_SHOWING_DESKTOP");
    ATOM_DEEPIN_WINDOW_VIEWPORTS = gdk_x11_get_xatom_by_name("DEEPIN_WINDOW_VIEWPORTS");
    ATOM_DEEPIN_SCREEN_VIEWPORT = gdk_x11_get_xatom_by_name("DEEPIN_SCREEN_VIEWPORT");
}

typedef struct _Workspace Workspace;
struct _Workspace {
    int x, y;
};

static Workspace current_workspace = {0, 0};

gboolean is_same_workspace(Workspace* lhs, Workspace* rhs)
{
    return lhs->x == rhs->x && lhs->y == rhs->y;
}
// Key: GINT_TO_POINTER(the id of window)
// Value: struct Client*
Window active_client_id = 0;
DesktopFocusState desktop_focus_state = DESKTOP_HAS_FOCUS;


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
    gpointer data= get_window_property(_dsp, GDK_ROOT_WINDOW(), ATOM_DEEPIN_SCREEN_VIEWPORT, &n_item);
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
        if (ev->atom == ATOM_ACTIVE_WINDOW) {
            active_window_changed(_dsp, (Window)dock_get_active_window());
        } else if (ev->atom == ATOM_SHOW_DESKTOP) {
            js_post_signal("desktop_status_changed");
        } else if (ev->atom == ATOM_DEEPIN_SCREEN_VIEWPORT) {
            _update_current_viewport(&current_workspace);
        }
        break;
    }
    }

    dock_update_hide_mode();
    return GDK_FILTER_CONTINUE;
}


void init_task_list()
{
    _dsp = GDK_DISPLAY_XDISPLAY(gdk_display_get_default());
    _init_atoms();

    GdkWindow* root = gdk_get_default_root_window();
    gdk_window_set_events(root, GDK_PROPERTY_CHANGE_MASK | gdk_window_get_events(root));

    gdk_window_add_filter(root, monitor_root_change, NULL);


    active_window_changed(_dsp, (Window)dock_get_active_window());
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


JS_EXPORT_API
void dock_iconify_window(double id)
{
    XIconifyWindow(_dsp, (Window)id, 0);
}


JS_EXPORT_API
gboolean dock_window_need_to_be_minimized(double id)
{
    return !dock_is_client_minimized(id) && dock_get_active_window() == id;
}


JS_EXPORT_API
void dock_draw_window_preview(JSValueRef canvas, double xid, double dest_width, double dest_height)
{
    GdkWindow* win = gdk_x11_window_foreign_new_for_display(gdk_display_get_default(), (long)xid);
    if (win == NULL) {
	return;
    }

    if (JSValueIsNull(get_global_context(), canvas)) {
        g_debug("draw_window_preview with null canvas!");
        return;
    }
    cairo_t* cr =  fetch_cairo_from_html_canvas(get_global_context(), canvas);

    cairo_save(cr);
    //clear preview content to prevent translucency window problem
    cairo_set_operator(cr, CAIRO_OPERATOR_CLEAR);
    cairo_paint(cr);
    cairo_restore(cr);

    int width = gdk_window_get_width(win);
    int height = gdk_window_get_height(win);

    cairo_save(cr);
    double scale = 0;
    if (width > height) {
        scale = dest_width/width;
        cairo_scale(cr, scale, scale);
        gdk_cairo_set_source_window(cr, win, 0, 0.5*(dest_height/scale-height));
    } else {
        scale = dest_height/height;
        cairo_scale(cr, scale, scale);
        gdk_cairo_set_source_window(cr, win, 0.5*(dest_width/scale-width), 0);
    }
    cairo_paint(cr);
    cairo_restore(cr);

    canvas_custom_draw_did(cr, NULL);
}


JS_EXPORT_API
gboolean dock_request_dock_by_client_id(double id)
{
    //TODO:REMOVE
    /*Client* c = g_hash_table_lookup(_clients_table, GINT_TO_POINTER((int)id));*/
    /*g_return_val_if_fail(c != NULL, FALSE);*/

    /*if (dock_has_launcher(c->app_id)) {*/
        /*// already has this app info*/
        /*g_debug("[%s] already has this app info", __func__);*/
        /*return FALSE;*/
    /*} else if (c->app_id == NULL || c->exec == NULL || c->icon == NULL) {*/
        /*g_warning("[%s] cannot dock app, because app_id, command line or icon maybe NULL", __func__);*/
        /*return FALSE;*/
    /*} else {*/
        /*g_debug("[%s] request_by_info: appid: %s, exec: %s, icon: %s",*/
                /*__func__, c->app_id, c->exec, c->icon);*/
        /*request_by_info(c->app_id, c->exec, c->icon);*/
        /*return TRUE;*/
    /*}*/
    return False;
}



JS_EXPORT_API
void dock_set_compiz_workaround_preview(gboolean v)
{
    static gboolean _v = 3;
    if (_v != v) {
        GSettings* compiz_workaround = g_settings_new_with_path(
                "org.compiz.workarounds",
                "/org/compiz/profiles/deepin/plugins/workarounds/");
        g_settings_set_boolean(compiz_workaround, "keep-minimized-windows", v);
        g_object_unref(compiz_workaround);
        _v = v;
    }
}

