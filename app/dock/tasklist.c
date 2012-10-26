#include <gtk/gtk.h>
#include <gdk/gdkx.h>
#include <X11/Xatom.h>
#include "X_misc.h"
#include "pixbuf.h"
#include "dwebview.h"

Atom ATOM_CLIENT_LIST;
Atom ATOM_ACTIVE_WINDOW;
Atom ATOM_WINDOW_ICON;
Atom ATOM_WINDOW_TYPE;
Atom ATOM_WINDOW_TYPE_NORMAL;
Atom ATOM_WINDOW_NAME;
Atom ATOM_WINDOW_STATE;
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
    int state;
    Window window;
} Client;

GHashTable* _clients_table = NULL;
Window _active_client_id = 0;

static 
GdkFilterReturn monitor_client_window(GdkXEvent* xevent, GdkEvent* event, Window id);

char* _get_window_icon(Display *dsp, Window w);
Client* create_client_from_window(Display* dsp, Window w)
{
    GdkWindow* win = gdk_x11_window_foreign_new_for_display(gdk_x11_lookup_xdisplay(dsp), w);
    gdk_window_set_events(win, GDK_PROPERTY_CHANGE_MASK | GDK_VISIBILITY_NOTIFY_MASK | gdk_window_get_events(win));
    gdk_window_add_filter(win, (GdkFilterFunc)monitor_client_window, GINT_TO_POINTER(w));

    XClassHint ch;
    XGetClassHint(dsp, w, &ch);

    Client* c = g_new(Client, 1);
    c->icon = _get_window_icon(dsp, w);
    c->title = g_strdup(ch.res_name);
    c->clss = g_strdup(ch.res_class);
    c->window = w;

    XFree(ch.res_name);
    XFree(ch.res_class);

    return c;
}
void client_free(Client* c)
{
    js_post_message("task_removed", "{\"id\": %d}", (int)c->window);
    g_free(c->icon);
    g_free(c->title);
    g_free(c->clss);
    g_free(c);
}


void active_window_changed(Display* dsp, Window w)
{
    if (_active_client_id != w) {
        _active_client_id = w;
        js_post_message("active_window_changed", "{\"id\": %d}", (int)w);
    }
}

gboolean is_normal_window(Display* dsp, Window w)
{
    gulong items;
    void* data = get_window_property(dsp, w, ATOM_WINDOW_TYPE, &items);
    for (int i=0; i<items; i++) {
        if ((Atom)X_FETCH_32(data, i) == ATOM_WINDOW_TYPE_NORMAL) {
            XFree(data);
            return TRUE;
        }
    }
    XFree(data);
    return FALSE;
}

void client_list_changed(Display* dsp, Window* cs, size_t n)
{
    for (int i=0; i<n; i++) {
        Client* c = g_hash_table_lookup(_clients_table, GINT_TO_POINTER(cs[i]));
        if (c == NULL && is_normal_window(dsp, cs[i])) {
            c = create_client_from_window(dsp, cs[i]);
            g_hash_table_insert(_clients_table, GINT_TO_POINTER(cs[i]), c);
            js_post_message("task_added", "{\"id\":%d, \"title\":\"%s\", \"clss\":\"%s\", \"icon\":\"%s\"}",
                    (int)cs[i], c->title, c->clss, c->icon);
        }
    }
}

void update_task_list(Display* display, Window root)
{
    gulong items;
    void* data = get_window_property(display, root, ATOM_CLIENT_LIST, &items);
    Window *cs = g_new(Window, items);
    for (int i=0; i<items; i++) {
        cs[i] = X_FETCH_32(data, i);
    }
    XFree(data);

    client_list_changed(display, cs, items);
    g_free(cs);
}

void update_active_window(Display* display, Window root)
{
    gulong items;
    void* data = get_window_property(display, root, ATOM_ACTIVE_WINDOW, &items);
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

char* _get_window_icon(Display *dsp, Window win)
{
    gulong items;
    void* data = get_window_property(dsp, win, ATOM_WINDOW_ICON, &items);

    if (data == NULL) {
        /*g_warning("has no icons...\n");*/
        return NULL;
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
    gdk_pixbuf_save(pixbuf, g_strdup_printf("%d.png", (int)win), "png", NULL, NULL);

    char* data_uri = get_data_uri_by_pixbuf(pixbuf);
    g_free(img);

    XFree(data);
    return data_uri;
}


GdkFilterReturn monitor_root_change(GdkXEvent* xevent, GdkEvent *event, gpointer _nouse)
{
    if (((XEvent*)xevent)->type == PropertyNotify) {
        XPropertyEvent* ev = xevent;
        if (ev->atom == ATOM_CLIENT_LIST) {
            update_task_list(ev->display, ev->window);
        } else if (ev->atom == ATOM_ACTIVE_WINDOW) {
            update_active_window(ev->display, ev->window);
        }
    } 
}

GdkFilterReturn monitor_client_window(GdkXEvent* xevent, GdkEvent* event, Window win)
{
    XEvent* xev = xevent;
    if (xev->type == DestroyNotify) {
        g_hash_table_remove(_clients_table, GINT_TO_POINTER(win));
    } else if (xev->type == PropertyNotify) {
        XPropertyEvent* ev = xevent;
        if (ev->atom == ATOM_WINDOW_ICON) {
        } else if (ev->atom == ATOM_WINDOW_NAME) {
        } else if (ev->atom == ATOM_WINDOW_STATE) {
            gulong items = 0;
            void* data = get_window_property(_dsp, win, ATOM_WINDOW_STATE, &items);
            int state = X_FETCH_32(data, 0);
            switch (state) {
                case WithdrawnState:
                    js_post_message("task_withdraw", "{\"id\":%d}", (int)win);
                    break;
                case NormalState:
                    js_post_message("task_normal", "{\"id\":%d}", (int)win);
                    break;
            }

        }
    }
    return GDK_FILTER_CONTINUE;
}


void monitor_tasklist_and_activewindow()
{
    _dsp = GDK_DISPLAY_XDISPLAY(gdk_display_get_default());
    _init_atoms();

    _clients_table = g_hash_table_new_full(g_direct_hash, g_direct_equal, NULL, (GDestroyNotify)client_free);

    GdkWindow* root = gdk_get_default_root_window();
    gdk_window_set_events(root, GDK_PROPERTY_CHANGE_MASK | gdk_window_get_events(root));

    gdk_window_add_filter(root, monitor_root_change, NULL);

    GdkDisplay* display = gdk_display_get_default();
    update_task_list(GDK_DISPLAY_XDISPLAY(display), GDK_WINDOW_XID(root));
}

//JS_EXPORT
void emit_update_active_window()
{
    //TODO: need this?
}
void emit_update_task_list()
{
    g_hash_table_remove_all(_clients_table);

    GdkDisplay* display = gdk_display_get_default();
    GdkWindow* root = gdk_get_default_root_window();
    update_task_list(GDK_DISPLAY_XDISPLAY(display), GDK_WINDOW_XID(root));
}
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
