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
#include "dock_hide.h"
#include "region.h"
#include "special_window.h"
#include "xdg_misc.h"
#include "DBUS_dock.h"
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
GKeyFile* record_file = NULL;

static Atom ATOM_WINDOW_HIDDEN;
PRIVATE Atom ATOM_CLIENT_LIST;
static Atom ATOM_ACTIVE_WINDOW;
static Atom ATOM_WINDOW_ICON;
static Atom ATOM_WINDOW_TYPE;
static Atom ATOM_WINDOW_TYPE_NORMAL;
static Atom ATOM_WINDOW_NAME;
static Atom ATOM_WINDOW_PID;
static Atom ATOM_WINDOW_NET_STATE;
static Atom ATOM_CLOSE_WINDOW;
static Atom ATOM_SHOW_DESKTOP;
static Atom ATOM_ACTION_ADD;
static Atom ATOM_WINDOW_STATE_HIDDEN;
static Atom ATOM_WINDOW_MAXIMIZED_VERT;
static Atom ATOM_WINDOW_SKIP_TASKBAR;
static Atom ATOM_XEMBED_INFO;
static Display* _dsp = NULL;
static Atom ATOM_DEEPIN_WINDOW_VIEWPORTS;
static Atom ATOM_DEEPIN_SCREEN_VIEWPORT;
PRIVATE void _init_atoms()
{
    ATOM_WINDOW_HIDDEN = gdk_x11_get_xatom_by_name("_NET_WM_STATE_HIDDEN");
    ATOM_CLIENT_LIST = gdk_x11_get_xatom_by_name("_NET_CLIENT_LIST");
    ATOM_ACTIVE_WINDOW = gdk_x11_get_xatom_by_name("_NET_ACTIVE_WINDOW");
    ATOM_WINDOW_ICON = gdk_x11_get_xatom_by_name("_NET_WM_ICON");
    ATOM_WINDOW_TYPE = gdk_x11_get_xatom_by_name("_NET_WM_WINDOW_TYPE");
    ATOM_WINDOW_TYPE_NORMAL = gdk_x11_get_xatom_by_name("_NET_WM_WINDOW_TYPE_NORMAL");
    ATOM_WINDOW_NAME = gdk_x11_get_xatom_by_name("_NET_WM_NAME");
    ATOM_WINDOW_PID = gdk_x11_get_xatom_by_name("_NET_WM_PID");
    ATOM_WINDOW_NET_STATE = gdk_x11_get_xatom_by_name("_NET_WM_STATE");
    ATOM_CLOSE_WINDOW = gdk_x11_get_xatom_by_name("_NET_CLOSE_WINDOW");
    ATOM_SHOW_DESKTOP = gdk_x11_get_xatom_by_name("_NET_SHOWING_DESKTOP");
    ATOM_ACTION_ADD = gdk_x11_get_xatom_by_name("_NET_WM_STATE_ADD");
    ATOM_WINDOW_STATE_HIDDEN = gdk_x11_get_xatom_by_name("_NET_WM_STATE_HIDDEN");
    ATOM_WINDOW_MAXIMIZED_VERT = gdk_x11_get_xatom_by_name("_NET_WM_STATE_MAXIMIZED_VERT");
    ATOM_WINDOW_SKIP_TASKBAR = gdk_x11_get_xatom_by_name("_NET_WM_STATE_SKIP_TASKBAR");
    ATOM_XEMBED_INFO = gdk_x11_get_xatom_by_name("_XEMBED_INFO");
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

typedef struct {
    char* title; /* _NET_WM_NAME */
    char* instance_name;  /*WMClass first field */
    char* clss; /* WMClass second field*/
    char* app_id; /*current is executabe file's name*/
    char* exec; /* /proc/pid/cmdline or /proc/pid/exe */
    int state;
    gboolean is_overlay_dock;
    gboolean is_hidden;
    gboolean is_maximize;
    gboolean use_board;
    gulong cross_workspace_num;
    Workspace workspace[4];

    Window window;
    GdkWindow* gdkwindow;

    char* icon;
    gboolean need_update_icon;
} Client;

// Key: GINT_TO_POINTER(the id of window)
// Value: struct Client*
PRIVATE GHashTable* _clients_table = NULL;
Window active_client_id = 0;
DesktopFocusState desktop_focus_state = DESKTOP_HAS_FOCUS;

PRIVATE
GdkFilterReturn monitor_client_window(GdkXEvent* xevent, GdkEvent* event, Window id);

void _update_window_icon(Client *c);
void _update_window_title(Client *c);
void _update_window_class(Client *c);
void _update_window_appid(Client *c);
void _update_window_net_state(Client* c);
PRIVATE void _update_is_overlay_client(Client* c);
PRIVATE gboolean _is_maximized_window(Window win);
PRIVATE void _update_task_list(Window root);
void client_free(Client* c);

PRIVATE
void _update_window_viewport_callback(gpointer data, gulong n_item, gpointer res)
{
    Client* c = (Client*)res;
    c->cross_workspace_num = (int)X_FETCH_32(data, 0);
    for (int i = 0, j = 1; j < n_item; ++i, j += 2) {
        c->workspace[i].x = (int)X_FETCH_32(data, j);
        c->workspace[i].y = (int)X_FETCH_32(data, j + 1);
    }
}

PRIVATE
void _update_window_viewport(Client* c)
{
    get_atom_value_by_atom(_dsp, c->window, ATOM_DEEPIN_WINDOW_VIEWPORTS, c,
                           _update_window_viewport_callback, -1);
    dock_update_hide_mode();
}

PRIVATE
gboolean _get_launcher_icon(Client* c)
{
    g_debug("[_get_launcher_icon] try to get launcher's icon");
    GDesktopAppInfo* info = guess_desktop_file(c->app_id);

    if (info == NULL) {
        g_debug("[_get_launcher_icon] info == NULL");
        return FALSE;
    }

    char* icon_name = NULL;
    GIcon* icon = g_app_info_get_icon(G_APP_INFO(info));

    if (icon != NULL) {
        g_debug("[_get_launcher_icon] get icon from desktop file");
        icon_name = g_icon_to_string(icon);
    } else {
        g_debug("[_get_launcher_icon] get icon from config file");
        extern GKeyFile* k_apps;
        icon_name = g_key_file_get_string(k_apps, c->app_id, "Icon", NULL);
    }

    g_debug("[_get_launcher_icon] icon name is \"%s\"", icon_name);

    if (icon_name != NULL) {
        if (g_str_has_prefix(icon_name, "data:image")) {
            g_debug("[_get_launcher_icon] get image data from data uri scheme");
            c->icon = icon_name;
        } else {
            g_debug("[_get_launcher_icon] get image path");
            if (g_path_is_absolute(icon_name)) {
                g_debug("[_get_launcher_icon] image path is absolute path");
                char* temp_icon_name_holder = dcore_get_theme_icon(c->app_id, 48);

                if (temp_icon_name_holder != NULL) {
                    g_free(icon_name);
                    icon_name = temp_icon_name_holder;
                } else {
                    char* basename =
                        get_basename_without_extend_name(icon_name);

                    if (basename != NULL) {
                        char*temp_icon_name_holder = dcore_get_theme_icon(basename,
                                                                     48);
                        g_free(basename);

                        if (temp_icon_name_holder != NULL &&
                            !g_str_has_prefix(temp_icon_name_holder,
                                              "data:image")) {
                            g_free(icon_name);
                            icon_name = temp_icon_name_holder;
                        }
                    }
                }
            }

            char* icon_path = icon_name_to_path(icon_name, 48);
            g_free(icon_name);

            g_debug("[_get_launcher_icon] icon path is %s", icon_path);
            if (is_deepin_icon(icon_path)) {
                g_debug("[_get_launcher_icon] icon is deepin icon");
                c->icon = icon_path;
            } else {
                g_debug("[_get_launcher_icon] icon is not deepin icon");
                GdkPixbuf* pixbuf = NULL;
                if (c->use_board) {
                    pixbuf = gdk_pixbuf_new_from_file_at_scale(icon_path,
                                                               IMG_WIDTH,
                                                               IMG_HEIGHT,
                                                               TRUE, NULL);
                } else {
                    pixbuf = gdk_pixbuf_new_from_file_at_scale(icon_path,
                                                               BOARD_WIDTH,
                                                               BOARD_HEIGHT,
                                                               TRUE, NULL);
                }
                g_free(icon_path);

                if (pixbuf == NULL) {
                    c->icon = NULL;
                } else {
                    char* icon_data = handle_icon(pixbuf, c->use_board);
                    g_object_unref(pixbuf);
                    c->icon = icon_data;
                }
            }
        }
    }

    g_object_unref(info);
    return c->icon == NULL;
}

Client* create_client_from_window(Window w)
{
    GdkWindow* win = gdk_x11_window_foreign_new_for_display(gdk_x11_lookup_xdisplay(_dsp), w);
    if (win == NULL)
        return NULL;
    g_assert(win != NULL);
    gdk_window_set_events(win, GDK_STRUCTURE_MASK | GDK_PROPERTY_CHANGE_MASK | GDK_VISIBILITY_NOTIFY_MASK | gdk_window_get_events(win));
    gdk_window_add_filter(win, (GdkFilterFunc)monitor_client_window, GINT_TO_POINTER(w));

    Client* c = g_new0(Client, 1);
    c->window = w;
    c->gdkwindow = win;
    c->is_overlay_dock = FALSE;
    c->is_hidden = FALSE;
    c->title = NULL;
    c->instance_name = NULL;
    c->app_id = NULL;
    c->exec = NULL;
    c->is_maximize = FALSE;
    c->use_board = TRUE;
    // initialize workspace
    _update_window_viewport(c);


    _update_window_title(c);
    _update_window_class(c);
    _update_window_appid(c);
    _update_window_net_state(c);
    _update_is_overlay_client(c);
    if (c->app_id == NULL) {
        client_free(c);
        return NULL;
    }

    c->icon = NULL;
    c->need_update_icon = FALSE;
    int operator_code = 0;
    try_get_deepin_icon(c->app_id, &c->icon, &operator_code);
    if (operator_code == ICON_OPERATOR_USE_RUNTIME_WITHOUT_BOARD)
        c->use_board = FALSE;

    if (c->icon == NULL) {
        g_debug("[create_client_from_window] try get deepin icon failed");
        g_debug("[create_client_from_window] appid: %s, operator_code: %d",
                c->app_id, operator_code);
        if (operator_code == ICON_OPERATOR_USE_ICONNAME)
            _get_launcher_icon(c);
    }

    g_debug("[create_client_from_window] icon path is %s", c->icon);

    if (c->icon == NULL) {
        g_debug("[create_client_from_window] get launcher icon failed");
        c->need_update_icon = TRUE;
        _update_window_icon(c);
    }

    if (record_file == NULL)
        record_file = load_app_config(RECORD_FILE);

    guint64 last_time = g_key_file_get_uint64(record_file, c->app_id, "StartNum", NULL);
    g_key_file_set_uint64(record_file, c->app_id, "StartNum", last_time + 1);
    save_app_config(record_file, RECORD_FILE);

    g_debug("");

    return c;
}

void _update_client_info(Client *c)
{
    JSObjectRef json = json_create();
    json_append_number(json, "id", c->window);
    json_append_string(json, "title", c->title);
    json_append_string(json, "icon", c->icon);
    json_append_string(json, "app_id", c->app_id);
    json_append_string(json, "exec", c->exec);
    g_assert(c->app_id != NULL);
    js_post_message("task_updated", json);
}

PRIVATE
void notify_desktop(DesktopFocusState current_state)
{
    dbus_set_desktop_focused(current_state == DESKTOP_HAS_FOCUS);
}


void active_window_changed(Display* dsp, Window w)
{
    if (active_client_id != w) {
        active_client_id = w;
        Client* c = g_hash_table_lookup(_clients_table, GINT_TO_POINTER((int)w));
        JSObjectRef json = json_create();
        json_append_number(json, "id", (int)w);
        if (c)
            json_append_string(json, "app_id", c->app_id);
        //else we should tell frontend we lost the active window
        js_post_message("active_window_changed", json);
    }
    if (launcher_id != 0 && launcher_should_exit()) {
        close_launcher_window();
    }
    if (desktop_pid != 0) {
        DesktopFocusState current_state = get_desktop_focus_state(_dsp);
        if (current_state != DESKTOP_FOCUS_UNKNOWN && desktop_focus_state != current_state) {
            desktop_focus_state = current_state;
            notify_desktop(current_state);
        }
    }
}

void client_free(Client* _c)
{
    Client* c = (Client*)_c;
    gdk_window_remove_filter(c->gdkwindow,
            (GdkFilterFunc)monitor_client_window, GINT_TO_POINTER(c->window));
    JSObjectRef json = json_create();
    json_append_number(json, "id", c->window);
    json_append_string(json, "app_id", c->app_id);
    js_post_message("task_removed", json);
    g_free(c->title);
    g_free(c->clss);
    g_free(c->instance_name);
    g_free(c->app_id);
    g_free(c->exec);
    g_object_unref(c->gdkwindow);
    /* gdk_window_destroy(c->gdkwindow); */
    g_free(c->icon);

    g_free(c);
    dock_update_hide_mode();
}


PRIVATE gboolean _is_hidden(Window w)
{
    gulong items;
    void* data = get_window_property(_dsp, w, ATOM_WINDOW_NET_STATE, &items);
    if (data == NULL) return FALSE;
    for (int i=0; i<items; i++) {
        if ((Atom)X_FETCH_32(data, i) == ATOM_WINDOW_HIDDEN) {
            XFree(data);
            return TRUE;
        }
    }
    XFree(data);
    return FALSE;
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


gboolean is_normal_window(Window w)
{
    XClassHint ch;
    if (XGetClassHint(_dsp, w, &ch)) {
        gboolean need_return = FALSE;
        if (g_strcmp0(ch.res_name, "explorer.exe") == 0 && g_strcmp0(ch.res_class, "Wine") == 0) {
            need_return = TRUE;
        } else if (g_strcmp0(ch.res_class, "DDELauncher") == 0) {
            start_monitor_launcher_window(_dsp, w);
            need_return = TRUE;
        } else if (g_str_equal(ch.res_class, "Desktop")) {
            get_atom_value_by_name(_dsp, w, "_NET_WM_PID", &desktop_pid, get_atom_value_by_index, 0);
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
        if ((Atom)X_FETCH_32(data, i) != ATOM_WINDOW_TYPE_NORMAL) {
            XFree(data);
            return FALSE;
        }
    }
    XFree(data);

    return TRUE;
}

PRIVATE void _destroy_client(gpointer id)
{
    g_hash_table_remove(_clients_table, id);
}
void client_list_changed(Window* cs, size_t n)
{
    GList* destroying_clients = g_hash_table_get_keys(_clients_table);
    for (int i=0; i<n; i++) {
        Client* c = g_hash_table_lookup(_clients_table, GINT_TO_POINTER(cs[i]));

        if (is_normal_window(cs[i])) {
            if (c == NULL && (c = create_client_from_window(cs[i]))) {
                //client maybe create failed!!
                //because monitor_client_window maybe run after _update_task_list when XWindow has be destroyed"
                g_hash_table_insert(_clients_table, GINT_TO_POINTER(cs[i]), c);
                dock_update_hide_mode();
                _update_client_info(c);
            }

            if (c != NULL)
                destroying_clients = g_list_remove(destroying_clients, GINT_TO_POINTER(cs[i]));
        }
    }
    g_list_free_full(destroying_clients, (GDestroyNotify)_destroy_client);
}

void update_task_list()
{
    g_hash_table_remove_all(_clients_table);
    _update_task_list(GDK_ROOT_WINDOW());
    active_window_changed(_dsp, (Window)dock_get_active_window());
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

JS_EXPORT_API
double dock_get_active_window()
{
    Window aw = 0;
    get_atom_value_by_atom(_dsp, GDK_ROOT_WINDOW(), ATOM_ACTIVE_WINDOW, &aw, get_atom_value_by_index, 0);
    return aw;
}

PRIVATE
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
    GdkPixbuf* tmp = NULL;
    if (c->use_board) {
        tmp = gdk_pixbuf_scale_simple(pixbuf, IMG_WIDTH, IMG_HEIGHT,
                                      GDK_INTERP_HYPER);
    } else {
        tmp = gdk_pixbuf_scale_simple(pixbuf, BOARD_WIDTH, BOARD_HEIGHT,
                                      GDK_INTERP_HYPER);
    }

    g_object_unref(pixbuf);
    pixbuf= tmp;


    g_free(c->icon);
    c->icon = handle_icon(pixbuf, c->use_board);
    g_object_unref(pixbuf);

    g_free(img);
    XFree(data);
}

void _update_window_title(Client* c)
{
    g_free(c->title);
    gulong item;
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
    gulong item;
    long* s_pid = get_window_property(_dsp, c->window, ATOM_WINDOW_PID, &item);
    if (s_pid != NULL) {
        char* exec_name = NULL;
        char* exec_args = NULL;
        get_pid_info(*s_pid, &exec_name, &exec_args);
        if (exec_name != NULL) {
            g_debug("[_update_window_appid] exec_name: %s, exec_args: %s", exec_name, exec_args);
            g_assert(c->title != NULL);
            app_id = find_app_id(exec_name, c->title, APPID_FILTER_WMNAME);
            if (app_id == NULL && c->instance_name != NULL)
                app_id = find_app_id(exec_name, c->instance_name, APPID_FILTER_WMINSTANCE);
            if (app_id == NULL && c->clss != NULL)
                app_id = find_app_id(exec_name, c->clss, APPID_FILTER_WMCLASS);
            if (app_id == NULL && exec_args != NULL)
                app_id = find_app_id(exec_name, exec_args, APPID_FILTER_ARGS);
            if (app_id == NULL)
                app_id = g_strdup(exec_name);
        } else {
            app_id = g_strdup(c->clss);
        }
        g_free(exec_name);
        g_free(exec_args);
    } else {
        //if there is no ATOM_WINDOW_PID use WMCLASS
        app_id = g_strdup(c->clss);
    }

    g_free(c->app_id);
    if (app_id != NULL) {
        c->app_id = to_lower_inplace(app_id);

        if (s_pid != NULL) {
            GDesktopAppInfo* desktop_file = guess_desktop_file(c->app_id);
            if (desktop_file != NULL) {
                c->exec = g_desktop_app_info_get_string(desktop_file,
                                                        G_KEY_FILE_DESKTOP_KEY_EXEC);

                g_object_unref(desktop_file);
            } else {
                c->exec = get_exe(app_id, *s_pid);
            }
        }
    }

    XFree(s_pid);
}

void _update_window_class(Client* c)
{
    g_free(c->clss);
    g_free(c->instance_name);
    XClassHint ch;
    if (XGetClassHint(_dsp, c->window, &ch)) {
        c->instance_name = g_strdup(ch.res_name);
        c->clss = g_strdup(ch.res_class);
        XFree(ch.res_name);
        XFree(ch.res_class);
    } else {
        c->clss = NULL;
        c->instance_name = NULL;
    }

    if (c->title && g_str_equal(c->title, "Unknow Name") && c->clss) {
        g_free(c->title);
        c->title = g_strdup(c->clss);
    }
}

void _update_window_net_state(Client* c)
{
    if (is_skip_taskbar(c->window)) {
        g_hash_table_remove(_clients_table, GINT_TO_POINTER(c->window));
    } else {
        c->is_hidden = _is_hidden(c->window);
        _update_is_overlay_client(c);
    }
    dock_update_hide_mode();
}

PRIVATE gboolean _is_maximized_window(Window win)
{
    gulong items;
    long* data = get_window_property(_dsp, win, ATOM_WINDOW_NET_STATE, &items);

    if (data != NULL) {
        for (int i=0; i<items; i++) {
            if ((Atom)X_FETCH_32(data, i) == ATOM_WINDOW_MAXIMIZED_VERT) {
                XFree(data);
                return TRUE;
            }
        }
        XFree(data);
    }
    return FALSE;
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
    switch (((XEvent*)xevent)->type) {
    case PropertyNotify: {
        XPropertyEvent* ev = xevent;
        if (ev->atom == ATOM_CLIENT_LIST) {
            _update_task_list(ev->window);
        } else if (ev->atom == ATOM_ACTIVE_WINDOW) {
            active_window_changed(_dsp, (Window)dock_get_active_window());
        } else if (ev->atom == ATOM_SHOW_DESKTOP) {
            js_post_message_simply("desktop_status_changed", NULL);
        } else if (ev->atom == ATOM_DEEPIN_SCREEN_VIEWPORT) {
            _update_current_viewport(&current_workspace);
        }
        break;
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
                _update_client_info(c);
            } else if (ev->atom == ATOM_WINDOW_NET_STATE) {
                _update_window_net_state(c);
            } else if (ev->atom == ATOM_DEEPIN_WINDOW_VIEWPORTS) {
                _update_window_viewport(c);
            }
        }
    } else if (xev->type == ConfigureNotify) {
        Client* c = g_hash_table_lookup(_clients_table, GINT_TO_POINTER(win));
        _update_is_overlay_client(c);
    }
    return GDK_FILTER_CONTINUE;
}

gboolean cross_workspaces_contain_current_workspace(Client* c)
{
    for (int i = 0; i < c->cross_workspace_num; ++i) {
        if (is_same_workspace(&c->workspace[i], &current_workspace))
            return TRUE;
    }

    return FALSE;
}

PRIVATE
gboolean _find_maximize_client(gpointer key, Client* c)
{
    return cross_workspaces_contain_current_workspace(c) && !c->is_hidden && c->is_maximize;
}
gboolean dock_has_maximize_client()
{
    return g_hash_table_find(_clients_table, (GHRFunc)_find_maximize_client, NULL) != NULL;
}

void _update_is_overlay_client(Client* c)
{
    gboolean is_overlay = FALSE;
    if (c->is_hidden) {
        is_overlay = FALSE;
    } else if (_is_maximized_window(c->window)) {
        c->is_maximize = TRUE;
        is_overlay = TRUE;
    } else {
        c->is_maximize = FALSE;
        cairo_rectangle_int_t tmp;
        gdk_window_get_geometry(c->gdkwindow, &(tmp.x), &(tmp.y), &(tmp.width), &(tmp.height));
        gdk_window_get_origin(c->gdkwindow, &(tmp.x), &(tmp.y));
        is_overlay = dock_region_overlay(&tmp);
    }
    if (c->is_overlay_dock != is_overlay) {
        c->is_overlay_dock = is_overlay;
        dock_update_hide_mode();
    }
}

PRIVATE
gboolean _find_overlay_window(gpointer key, Client* c)
{
    return cross_workspaces_contain_current_workspace(c) && c->is_overlay_dock;
}
gboolean dock_has_overlay_client()
{
    return g_hash_table_find(_clients_table, (GHRFunc)_find_overlay_window, NULL) != NULL;
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
gboolean dock_is_client_minimized(double id)
{
    Client* c = g_hash_table_lookup(_clients_table, GINT_TO_POINTER((Window)id));
    if (c == NULL)
        return FALSE;

    gulong wm_state;
    gboolean is_minimized = FALSE;
    if (get_atom_value_by_name(_dsp, c->window, "WM_STATE", &wm_state, get_atom_value_by_index, 0)) {
        is_minimized = wm_state == IconicState;

        const char* state[] = {"WithDraw", "Normal", NULL, "Iconic"};
        g_debug("window state: %s", state[wm_state]);
    } else {
        g_debug("cannot get Window state(WM_STATE)");
    }

    return is_minimized;
}

JS_EXPORT_API
gboolean dock_window_need_to_be_minimized(double id)
{
    return !dock_is_client_minimized(id) && dock_get_active_window() == id;
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
    Client* c = g_hash_table_lookup(_clients_table, GINT_TO_POINTER((int)id));
    g_return_val_if_fail(c != NULL, FALSE);

    if (dock_has_launcher(c->app_id)) {
        // already has this app info
        g_debug("already has this app info");
        return FALSE;
    } else if (c->app_id == NULL || c->exec == NULL || c->icon == NULL) {
        g_warning("cannot dock app, because app_id, command line or icon maybe NULL");
        return FALSE;
    } else {
        request_by_info(c->app_id, c->exec, c->icon);
        return TRUE;
    }
}

PRIVATE
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
