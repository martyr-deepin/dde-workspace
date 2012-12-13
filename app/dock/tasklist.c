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
#include "desktop_file_matcher.h"
#include "launcher.h"

#include <gtk/gtk.h>
#include <gdk/gdkx.h>
#include <X11/Xatom.h>
#include <dwebview.h>
#include <string.h>


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
Display* _dsp = NULL;
void _init_atoms()
{
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
}

typedef struct {
    char* icon;
    char* title;
    char* clss;
    char* app_id; /*current is executabe file's name*/
    int state;
    Window window;
    GdkWindow* gdkwindow;
} Client;

GHashTable* _clients_table = NULL;
Window _active_client_id = 0;

static 
GdkFilterReturn monitor_client_window(GdkXEvent* xevent, GdkEvent* event, Window id);

void _update_window_icon(Client *c);
void _update_window_title(Client *c); 
void _update_window_class(Client *c);
void _set_window_exec(Client *c);

void _update_task_list(Window root);

Client* create_client_from_window(Window w)
{
    GdkWindow* win = gdk_x11_window_foreign_new_for_display(gdk_x11_lookup_xdisplay(_dsp), w);
    gdk_window_set_events(win, GDK_PROPERTY_CHANGE_MASK | GDK_VISIBILITY_NOTIFY_MASK | gdk_window_get_events(win));
    gdk_window_add_filter(win, (GdkFilterFunc)monitor_client_window, GINT_TO_POINTER(w));

    Client* c = g_new(Client, 1);
    c->window = w;
    c->gdkwindow = win;

    _set_window_exec(c);

    _update_window_icon(c);
    _update_window_title(c);
    _update_window_class(c);

    return c;
}

void _update_client_info(Client *c)
{
    JSObjectRef json = json_create();
    json_append_number(json, "id", c->window);
    json_append_string(json, "title", c->title);
    json_append_string(json, "clss", c->clss);
    json_append_string(json, "icon", c->icon);
    json_append_string(json, "app_id", c->app_id);
    js_post_message_json("task_added", json);
}
void active_window_changed(Display* dsp, Window w)
{
    if (_active_client_id != w) {
        _active_client_id = w;
        Client* c = g_hash_table_lookup(_clients_table, GINT_TO_POINTER((int)w));
        if (c != NULL) {
            JSObjectRef json = json_create();
            json_append_number(json, "id", (int)w);
            json_append_string(json, "clss", c->clss);
            js_post_message_json("active_window_changed", json);
        }
    }
}


void client_free(Client* c)
{
    JSObjectRef json = json_create();
    json_append_number(json, "id", c->window);
    json_append_string(json, "clss", c->clss);
    js_post_message_json("task_removed", json);

    gdk_window_remove_filter(c->gdkwindow,
            (GdkFilterFunc)monitor_client_window, GINT_TO_POINTER(c->window));
    g_object_unref(c->gdkwindow);
    g_free(c->icon);
    g_free(c->title);
    g_free(c->clss);
    g_free(c->app_id);
    g_free(c);
}



gboolean is_normal_window(Window w)
{
    XClassHint ch;
    if (XGetClassHint(_dsp, w, &ch)) {
        if (g_strcmp0(ch.res_name, "explorer.exe") == 0 && g_strcmp0(ch.res_class, "Wine") == 0) {
            XFree(ch.res_name);
            XFree(ch.res_class);
            return FALSE;
        } else {
            XFree(ch.res_name);
            XFree(ch.res_class);
        }
    }

    gulong items;
    void* data = get_window_property(_dsp, w, ATOM_WINDOW_TYPE, &items);
    if (data == NULL)
        return FALSE;
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
        if (c == NULL && is_normal_window(cs[i])) {
            c = create_client_from_window(cs[i]);
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

GdkPixbuf* get_client_icon(Client* c)
{
}
void _update_window_icon(Client* c)
{
    gulong items;
    gulong* data = get_window_property(_dsp, c->window, ATOM_WINDOW_ICON, &items);
    if (data == NULL) {
        c->icon = g_strdup("img/not_found.png");
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
    c->icon = get_data_uri_by_pixbuf(pixbuf);
    g_object_unref(pixbuf);

    g_free(img);
    
    XFree(data);
}

void _update_window_title(Client* c)
{
    long item;
    char* name = get_window_property(_dsp, c->window, ATOM_WINDOW_NAME, &item);
    if (name != NULL)
        /*c->title = json_escape(name);*/
        c->title = g_strdup(name);
    else
        c->title = g_strdup("Unknow Name");
    XFree(name);

}

void _set_window_exec(Client* c)
{
    long item;
    long* s_pid = get_window_property(_dsp, c->window, ATOM_WINDOW_PID, &item);
    if (s_pid != NULL) {
        c->app_id = get_app_id_by_pid(*s_pid);
        XFree(s_pid);
    } else {
        c->app_id = NULL;
    }
}

void _update_window_class(Client* c)
{
    XClassHint ch;
    if (XGetClassHint(_dsp, c->window, &ch)) {
        c->clss = g_strdup(ch.res_class);
        XFree(ch.res_name);
        XFree(ch.res_class);
    } else {
        c->clss = NULL;
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
                js_post_message("task_withdraw", "{\"id\":%d}", (int)c->window);
                break;
            case NormalState:
                js_post_message("task_normal", "{\"id\":%d}", (int)c->window);
                break;
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
            if (ev->atom == ATOM_WINDOW_ICON) {
                // we didn't update window_icon now because of hasn't decide how handle the same class applications' icon
                /*_update_window_icon(c);*/
                /*_update_client_info(c);*/
            } else if (ev->atom == ATOM_WINDOW_NAME) {
                _update_window_title(c);
                _update_client_info(c);
            } else if (ev->atom == ATOM_WINDOW_STATE) {
                _update_window_state(c);
                _update_client_info(c);
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

//JS_EXPORT
void set_active_window(double id)
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
void close_window(double id)
{
    XClientMessageEvent event;
    event.type = ClientMessage;
    event.window = (Window)id;
    event.message_type = ATOM_CLOSE_WINDOW;
    event.format = 32;
    XSendEvent(_dsp, GDK_ROOT_WINDOW(), False, 
            StructureNotifyMask, (XEvent*)&event);
}
void show_desktop(gboolean value)
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
void minimize_window(double id)
{
    XIconifyWindow(_dsp, (Window)id, 0);
}

void draw_window_preview(JSValueRef canvas, double xid, double dest_width, double dest_height, JSData* data)
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

double test_get_n()
{
    return (double)g_hash_table_size(_clients_table);
}


JS_EXPORT_API
gboolean request_dock_by_client_id(double id)
{
    Client* c = g_hash_table_lookup(_clients_table, GINT_TO_POINTER((int)id));
    g_assert(c != NULL);
    if (is_has_app_info(c->app_id)) {
        // already has this app info
        return FALSE;
    } else {
        char* name =  g_strdup(c->app_id);
        for (gsize i=0; i<strlen(name); i++) {
            if (name[i] == ' ') {
                name[i] = '\0';
                break;
            }
        }
        request_by_info(name, c->app_id, c->icon);
        g_free(name);
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
