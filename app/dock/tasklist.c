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
#include "X_misc.h"
#include "pixbuf.h"
#include "utils.h"
#include "xid2aid.h"
#include "launcher.h"
#include "dock_config.h"
#include "dominant_color.h"
#include "handle_icon.h"
#include "tasklist.h"
extern Window get_dock_window();

#include <gtk/gtk.h>
#include <gdk/gdkx.h>
#include <X11/Xatom.h>
#include <dwebview.h>
#include <string.h>
#include <math.h>


Atom ATOM_CLIENT_LIST;
Atom ATOM_ACTIVE_WINDOW;
Atom ATOM_WINDOW_ICON;
Atom ATOM_WINDOW_TYPE;
Atom ATOM_WINDOW_TYPE_NORMAL;
Atom ATOM_WINDOW_NAME;
Atom ATOM_WINDOW_CLASS;
Atom ATOM_WINDOW_STATE;
Atom ATOM_WINDOW_PID;
Atom ATOM_WINDOW_NET_STATE;
Atom ATOM_CLOSE_WINDOW;
Atom ATOM_SHOW_DESKTOP;
Atom ATOM_ACTION_ADD;
Atom ATOM_WINDOW_STATE_HIDDEN;
Atom ATOM_WINDOW_MAXIMIZED_VERT;
Atom ATOM_WINDOW_SKIP_TASKBAR;
Atom ATOM_XEMBED_INFO;
Display* _dsp = NULL;
void _init_atoms()
{
    ATOM_XEMBED_INFO = gdk_x11_get_xatom_by_name("_XEMBED_INFO");
    ATOM_CLIENT_LIST = gdk_x11_get_xatom_by_name("_NET_CLIENT_LIST");
    ATOM_ACTIVE_WINDOW = gdk_x11_get_xatom_by_name("_NET_ACTIVE_WINDOW");
    ATOM_WINDOW_ICON = gdk_x11_get_xatom_by_name("_NET_WM_ICON");
    ATOM_WINDOW_TYPE = gdk_x11_get_xatom_by_name("_NET_WM_WINDOW_TYPE");
    ATOM_WINDOW_TYPE_NORMAL = gdk_x11_get_xatom_by_name("_NET_WM_WINDOW_TYPE_NORMAL");
    ATOM_WINDOW_NAME = gdk_x11_get_xatom_by_name("_NET_WM_NAME");
    ATOM_WINDOW_STATE = gdk_x11_get_xatom_by_name("WM_STATE");
    ATOM_WINDOW_PID = gdk_x11_get_xatom_by_name("_NET_WM_PID");
    ATOM_WINDOW_NET_STATE = gdk_x11_get_xatom_by_name("_NET_WM_STATE");
    ATOM_CLOSE_WINDOW = gdk_x11_get_xatom_by_name("_NET_CLOSE_WINDOW");
    ATOM_SHOW_DESKTOP = gdk_x11_get_xatom_by_name("_NET_SHOWING_DESKTOP");
    ATOM_ACTION_ADD = gdk_x11_get_xatom_by_name("_NET_WM_STATE_ADD");
    ATOM_WINDOW_STATE_HIDDEN = gdk_x11_get_xatom_by_name("_NET_WM_STATE_HIDDEN");
    ATOM_WINDOW_MAXIMIZED_VERT = gdk_x11_get_xatom_by_name("_NET_WM_STATE_MAXIMIZED_VERT");
    ATOM_WINDOW_SKIP_TASKBAR = gdk_x11_get_xatom_by_name("_NET_WM_STATE_SKIP_TASKBAR");
}

typedef struct {
    char* title; /* _NET_WM_NAME */
    char* clss; /* WMClass */
    char* app_id; /*current is executabe file's name*/
    char* exec;
    int state;
    gboolean is_maximized;

    Window window;
    GdkWindow* gdkwindow;

    char* icon;
    gboolean need_update_icon;
} Client;

GHashTable* _clients_table = NULL;
Window _active_client_id = 0;
Window _launcher_id = 0;

static
GdkFilterReturn monitor_client_window(GdkXEvent* xevent, GdkEvent* event, Window id);

void _update_window_icon(Client *c);
void _update_window_title(Client *c); 
void _update_window_class(Client *c);
void _update_window_appid(Client *c);

void _update_task_list(Window root);
void update_active_window(Display* display, Window root);

Client* create_client_from_window(Window w)
{
    GdkWindow* win = gdk_x11_window_foreign_new_for_display(gdk_x11_lookup_xdisplay(_dsp), w);
    if (win == NULL)
        return NULL;
    g_assert(win != NULL);
    gdk_window_set_events(win, GDK_PROPERTY_CHANGE_MASK | GDK_VISIBILITY_NOTIFY_MASK | gdk_window_get_events(win));
    gdk_window_add_filter(win, (GdkFilterFunc)monitor_client_window, GINT_TO_POINTER(w));

    Client* c = g_new0(Client, 1);
    c->window = w;
    c->gdkwindow = win;
    c->is_maximized = FALSE;
    c->app_id = NULL;
    c->exec = NULL;



    _update_window_title(c);
    _update_window_class(c);
    _update_window_appid(c);

    c->need_update_icon = FALSE;
    c->icon = try_get_deepin_icon(c->app_id);

    if (c->icon == NULL) {
        c->need_update_icon = TRUE;
        _update_window_icon(c);
    }

    return c;
}

void _update_client_info(Client *c)
{
    JSObjectRef json = json_create();
    json_append_number(json, "id", c->window);
    json_append_string(json, "title", c->title);
    json_append_string(json, "icon", c->icon);
    json_append_string(json, "app_id", c->app_id);
    g_assert(c->app_id != NULL);
    js_post_message("task_updated", json);
}

gboolean launcher_should_exit()
{
    return _active_client_id != get_dock_window() && _active_client_id != _launcher_id;
}

void active_window_changed(Display* dsp, Window w)
{
    if (_active_client_id != w) {
        _active_client_id = w;
        Client* c = g_hash_table_lookup(_clients_table, GINT_TO_POINTER((int)w));
        if (c != NULL) {
            JSObjectRef json = json_create();
            json_append_number(json, "id", (int)w);
            json_append_string(json, "app_id", c->app_id);
            js_post_message("active_window_changed", json);
        } else {
            /*g_warning("0x%x get focus..\n", (int)w);*/
        }
    }
    if (_launcher_id != 0 && launcher_should_exit()) {
        close_launcher_window();
    }
}

void client_free(Client* c)
{
    gdk_window_remove_filter(c->gdkwindow,
            (GdkFilterFunc)monitor_client_window, GINT_TO_POINTER(c->window));
    JSObjectRef json = json_create();
    json_append_number(json, "id", c->window);
    json_append_string(json, "app_id", c->app_id);
    js_post_message("task_removed", json);
    g_free(c->title);
    g_free(c->clss);
    g_free(c->app_id);
    g_free(c->exec);
    g_object_unref(c->gdkwindow);
    g_free(c->icon);

    g_free(c);
}


gboolean is_skip_taskbar(Window w)
{
    gulong items;
    void* data = get_window_property(_dsp, w, ATOM_WINDOW_NET_STATE, &items);
    if (data == NULL) return FALSE;
    for (int i=0; i<items; i++) {
        if ((Atom)X_FETCH_32(data, i) == ATOM_WINDOW_SKIP_TASKBAR) {
            XFree(data);
            return TRUE;
        }
    }
    XFree(data);
    return FALSE;
}

static
GdkFilterReturn _monitor_launcher_window(GdkXEvent* xevent, GdkEvent* event, Window win)
{
    XEvent* xev = xevent;
    if (xev->type == DestroyNotify) {
        js_post_message_simply("launcher_destroy", NULL);
        _launcher_id = 0;
    }
    return GDK_FILTER_CONTINUE;
}
void start_monitor_launcher_window(Window w)
{
    _launcher_id = w;
    GdkWindow* win = gdk_x11_window_foreign_new_for_display(gdk_x11_lookup_xdisplay(_dsp), w);
    if (win == NULL)
        return;
    js_post_message_simply("launcher_running", NULL);

    g_assert(win != NULL);
    gdk_window_set_events(win, GDK_VISIBILITY_NOTIFY_MASK | gdk_window_get_events(win));
    gdk_window_add_filter(win, (GdkFilterFunc)_monitor_launcher_window, GINT_TO_POINTER(w));
}

gboolean is_normal_window(Window w)
{
    XClassHint ch;
    if (XGetClassHint(_dsp, w, &ch)) {
        gboolean need_return = FALSE;
        if (g_strcmp0(ch.res_name, "explorer.exe") == 0 && g_strcmp0(ch.res_class, "Wine") == 0) {
            need_return = TRUE;
        } else if (g_strcmp0(ch.res_class, "DDELauncher") == 0) {
            start_monitor_launcher_window(w);
            need_return = TRUE;
        }
        XFree(ch.res_name);
        XFree(ch.res_class);
        if (need_return)
            return FALSE;
    }

    if (is_skip_taskbar(w)) return FALSE;

    gulong items;
    void* data = get_window_property(_dsp, w, ATOM_WINDOW_TYPE, &items);

    if (data == NULL && !has_atom_property(_dsp, w, ATOM_WINDOW_PID)) return TRUE;

    if (data == NULL && has_atom_property(_dsp, w, ATOM_XEMBED_INFO)) return FALSE;

    for (int i=0; i<items; i++) {
        if ((Atom)X_FETCH_32(data, i) == ATOM_WINDOW_TYPE_NORMAL) {
            XFree(data);
            return TRUE;
        }
    }
    XFree(data);

    return FALSE;
}

void client_list_changed(Window* cs, size_t n)
{
    for (int i=0; i<n; i++) {
        Client* c = g_hash_table_lookup(_clients_table, GINT_TO_POINTER(cs[i]));
        if (c == NULL && is_normal_window(cs[i]) && (c = create_client_from_window(cs[i]))) {
            //client maybe create failed!!
            //because monitor_client_window maybe run after _update_task_list when XWindow has be destroied"
            g_hash_table_insert(_clients_table, GINT_TO_POINTER(cs[i]), c);
            _update_client_info(c);
        }
    }
}

void update_task_list()
{
    g_hash_table_remove_all(_clients_table);
    GdkWindow* root = gdk_get_default_root_window();
    _update_task_list(GDK_WINDOW_XID(root));
    update_active_window(_dsp, GDK_WINDOW_XID(root));
}

void _update_task_list(Window root)
{
    gulong items;
    void* data = get_window_property(_dsp, root, ATOM_CLIENT_LIST, &items);
    if (data == NULL) {
        return;
    }

    Window *cs = g_new(Window, items);
    for (int i=0; i<items; i++) {
        cs[i] = X_FETCH_32(data, i);
    }
    XFree(data);

    client_list_changed(cs, items);
    g_free(cs);
}

void update_active_window(Display* display, Window root)
{
    gulong items;
    void* data = get_window_property(display, root, ATOM_ACTIVE_WINDOW, &items);
    if (data == NULL)
        return;
    Window aw = X_FETCH_32(data, 0);
    active_window_changed(display, aw);
    XFree(data);
}

static 
void* argb_to_rgba(gulong* data, size_t s)
{
    guint32* img = g_new(guint32, s);
    for (int i=0; i < s; i++) {
        guchar a = data[i] >> 24;
        guchar r = (data[i] >> 16) & 0xff;
        guchar g = (data[i] >> 8) & 0xff;
        guchar b = data[i] & 0xff;
        img[i] = r | g << 8 | b << 16 | a << 24;
    }
    return img;
}

void _update_window_icon(Client* c)
{
    gulong items;
    gulong* data = get_window_property(_dsp, c->window, ATOM_WINDOW_ICON, &items);
    if (data == NULL) {
        c->icon = NULL;
        return;
    }

    int w=0, h=0;
    gulong *p = NULL;
    guint offset = 0;
    while (offset + 3 < items) {
        int width = X_FETCH_32(data, offset);
        int height = X_FETCH_32(data, offset+1);

        h = MAX(height, h);
        if (width > w) {
            w = width;
            p = data + offset;
        }

        offset += 2;
        offset += width*height;
    }

    void* img = argb_to_rgba(p, w*h);


    GdkPixbuf* pixbuf = gdk_pixbuf_new_from_data(img, GDK_COLORSPACE_RGB, TRUE, 8, w, h, w*4, NULL, NULL);
    GdkPixbuf* tmp = gdk_pixbuf_scale_simple(pixbuf, IMG_WIDTH, IMG_HEIGHT, GDK_INTERP_HYPER);
    g_object_unref(pixbuf);
    pixbuf= tmp;


    char* handle_icon(GdkPixbuf* icon);
    g_free(c->icon);
    c->icon = handle_icon(pixbuf);
    g_object_unref(pixbuf);

    g_free(img);
    XFree(data);
}

void _update_window_title(Client* c)
{
    g_free(c->title);
    long item;
    char* name = get_window_property(_dsp, c->window, ATOM_WINDOW_NAME, &item);
    if (name != NULL)
        c->title = g_strdup(name);
    else
        c->title = g_strdup("Unknow Name");
    XFree(name);

}

void _update_window_appid(Client* c)
{
    char* app_id = NULL;
    long item;
    long* s_pid = get_window_property(_dsp, c->window, ATOM_WINDOW_PID, &item);
    if (s_pid != NULL) {
        char* exec_name = NULL;
        char* exec_args = NULL;
        get_pid_info(*s_pid, &exec_name, &exec_args);
        if (exec_name != NULL) {
            app_id = find_app_id(exec_name, c->title, APPID_FILTER_WMNAME);
            if (app_id == NULL)
                app_id = find_app_id(exec_name, c->clss, APPID_FILTER_WMCLASS);
            if (app_id == NULL && exec_args != NULL)
                app_id = find_app_id(exec_name, exec_args, APPID_FILTER_ARGS);
            if (app_id == NULL)
                app_id = g_strdup(exec_name);
        } else {
            app_id = g_strdup(c->clss);
        }
        c->exec = get_exe(*s_pid);
        XFree(s_pid);
        g_free(exec_name);
        g_free(exec_args);
    } else {
        //if there is no ATOM_WINDOW_PID use WMCLASS 
        app_id = g_strdup(c->clss);
    }

    g_free(c->app_id);
    g_assert(app_id != NULL);
    c->app_id = to_lower_inplace(app_id);

}

void _update_window_class(Client* c)
{
    g_free(c->clss);
    XClassHint ch;
    if (XGetClassHint(_dsp, c->window, &ch)) {
        c->clss = g_strdup(ch.res_class);
        XFree(ch.res_name);
        XFree(ch.res_class);
    } else {
        c->clss = NULL;
    }
}

void _update_window_net_state(Client* c)
{
    if (is_skip_taskbar(c->window))
        g_hash_table_remove(_clients_table, GINT_TO_POINTER(c->window));
    //TODO: update other info
}

void _update_has_maximized_window(Client* c)
{
    if (gdk_window_get_state(c->gdkwindow) == GDK_WINDOW_STATE_MAXIMIZED) {
        c->is_maximized = TRUE;
        g_assert_not_reached();
    } else {
        c->is_maximized = FALSE;
    }
}

void _update_window_state(Client* c)
{
    gulong items = 0;
    void* data = get_window_property(_dsp, c->window, ATOM_WINDOW_STATE, &items);
    if (data != NULL) {
        int state = X_FETCH_32(data, 0);
        XFree(data);
        switch (state) {
            case WithdrawnState:
                {
                    JSObjectRef json = json_create();
                    json_append_number(json, "id", (int)c->window);
                    json_append_string(json, "app_id", c->app_id);
                    js_post_message("task_withdraw", json);
                    break;
                }
                /*js_post_message("task_withdraw", "{\"id\":%d, \"clss\":}", (int)c->window);*/
            case NormalState:
                {
                    JSObjectRef json = json_create();
                    json_append_number(json, "id", (int)c->window);
                    json_append_string(json, "app_id", c->app_id);
                    js_post_message("task_normal", json);
                    break;
                }
                /*js_post_message("task_normal", "{\"id\":%d}", (int)c->window);*/
                /*break;*/
        }
    }
}


GdkFilterReturn monitor_root_change(GdkXEvent* xevent, GdkEvent *event, gpointer _nouse)
{
    if (((XEvent*)xevent)->type == PropertyNotify) {
        XPropertyEvent* ev = xevent;
        if (ev->atom == ATOM_CLIENT_LIST) {
            _update_task_list(ev->window);
        } else if (ev->atom == ATOM_ACTIVE_WINDOW) {
            update_active_window(ev->display, ev->window);
        } else if (ev->atom == ATOM_SHOW_DESKTOP) {
            js_post_message_simply("desktop_status_changed", NULL);
        }
    }
    return GDK_FILTER_CONTINUE;
}


GdkFilterReturn monitor_client_window(GdkXEvent* xevent, GdkEvent* event, Window win)
{
    XEvent* xev = xevent;
    if (xev->type == DestroyNotify) {
        g_hash_table_remove(_clients_table, GINT_TO_POINTER(win));
    } else if (xev->type == PropertyNotify) {
        XPropertyEvent* ev = xevent;
        Client* c = g_hash_table_lookup(_clients_table, GINT_TO_POINTER(win));
        if (c != NULL) {
            if (ev->atom == ATOM_WINDOW_ICON && c->need_update_icon) {
                // we didn't update window_icon now because of hasn't decide how handle the same class applications' icon
                _update_window_icon(c);
                _update_client_info(c);
            } else if (ev->atom == ATOM_WINDOW_NAME) {
                _update_window_title(c);
                _update_window_class(c);
            } else if (ev->atom == ATOM_WINDOW_STATE) {
                _update_window_state(c);
                _update_client_info(c);
            } else if (ev->atom == ATOM_WINDOW_NET_STATE) {
                _update_window_net_state(c);
            }
        }
    }
    return GDK_FILTER_CONTINUE;
}


void init_task_list()
{
    _dsp = GDK_DISPLAY_XDISPLAY(gdk_display_get_default());
    _init_atoms();

    _clients_table = g_hash_table_new_full(g_direct_hash, g_direct_equal, NULL, (GDestroyNotify)client_free);

    GdkWindow* root = gdk_get_default_root_window();
    gdk_window_set_events(root, GDK_PROPERTY_CHANGE_MASK | gdk_window_get_events(root));

    gdk_window_add_filter(root, monitor_root_change, NULL);


    update_task_list();
    update_active_window(_dsp, GDK_WINDOW_XID(root));
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
void dock_close_window(double id)
{
    XClientMessageEvent event;
    event.type = ClientMessage;
    event.window = (Window)id;
    event.message_type = ATOM_CLOSE_WINDOW;
    event.format = 32;
    XSendEvent(_dsp, GDK_ROOT_WINDOW(), False, 
            StructureNotifyMask, (XEvent*)&event);
}
void close_launcher_window()
{
    dock_close_window(_launcher_id);
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
void dock_draw_window_preview(JSValueRef canvas, double xid, double dest_width, double dest_height, JSData* data)
{
    if (JSValueIsNull(data->ctx, canvas)) {
        g_debug("draw_window_preview with null canvas!");
        return;
    }
    cairo_t* cr =  fetch_cairo_from_html_canvas(data->ctx, canvas);

    Client* c = g_hash_table_lookup(_clients_table, GINT_TO_POINTER((Window)xid));
    if (c == NULL)
        return;
    GdkWindow* win = c->gdkwindow;

    int width = gdk_window_get_width(win);
    int height = gdk_window_get_height(win);
    double scale = width / (double) height;

    if (width > height) {
        dest_height =  dest_width / scale;
    } else {
        dest_width = dest_height * scale;
    }

    double s1 = dest_width / width;
    double s2 = dest_height / height;

    cairo_save(cr);
    cairo_scale(cr, dest_width / width, dest_height / height);
    gdk_cairo_set_source_window(cr, win, 0, 0);
    cairo_paint(cr);
    cairo_restore(cr);

    canvas_custom_draw_did(cr, NULL);
}

JS_EXPORT_API
gboolean dock_request_dock_by_client_id(double id)
{
    Client* c = g_hash_table_lookup(_clients_table, GINT_TO_POINTER((int)id));
    g_assert(c != NULL);
    if (is_has_app_info(c->app_id)) {
        // already has this app info
        return FALSE;
    } else {
        request_by_info(c->app_id, c->exec, c->icon);
    }
}

static 
gboolean _find_app_id(gpointer key, Client* c, const char* app_id)
{
    return g_strcmp0(c->app_id, app_id) == 0;
}

gboolean is_has_client(const char* app_id)
{
    //TODO: change this O(n*n) find method.
    if (g_hash_table_find(_clients_table, (GHRFunc)_find_app_id, (gpointer)app_id) != NULL)
        return TRUE;
    else
        return FALSE;
}
