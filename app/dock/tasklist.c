#include <gtk/gtk.h>
#include <gdk/gdkx.h>
#include <X11/Xatom.h>
#include "X_misc.h"
#include "pixbuf.h"

Atom ATOM_CLIENT_LIST;
Atom ATOM_ACTIVE_WINDOW;
Atom ATOM_NET_WM_ICON;

char* get_window_icon(Display *dsp, Window w);

void print_window(Display* dsp, Window w)
{
    XClassHint ch;
    XWMHints hits;
    XGetClassHint(dsp, w, &ch);
    printf("%s(0x%x)  ", ch.res_name, (int)w);
    get_window_icon(dsp, w);
    XFree(ch.res_name);
    XFree(ch.res_class);
}

void active_window_changed(Display* dsp, Window w)
{
    printf("Active Window changed: ");
    print_window(dsp, w);
    puts("\n");
}

void client_list_changed(Display* dsp, Window* cs, size_t n)
{
    printf("Client List:");
    for (int i=0; i<n; i++) {
        print_window(dsp, cs[i]);
    }
    printf("\n");
}

void update_task_list(Display* display, Window root)
{
    gulong items;
    void* data = get_window_property(display, root, ATOM_CLIENT_LIST, XA_WINDOW, &items);
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
    void* data = get_window_property(display, root, ATOM_ACTIVE_WINDOW, XA_WINDOW, &items);
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

char* get_window_icon(Display *dsp, Window win)
{
    gulong items;
    void* data = get_window_property(dsp, win, ATOM_NET_WM_ICON, XA_CARDINAL, &items);

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
        offset += 2 + width*height;
    }

    void* img = argb_to_rgba(p, w*h);
    XFree(data);

    GdkPixbuf* pixbuf = gdk_pixbuf_new_from_data(img, GDK_COLORSPACE_RGB, TRUE, 8, w, h, w*4, NULL, NULL);
    char* data_uri = get_data_uri_by_pixbuf(pixbuf);
    g_free(img);

    return data_uri;
}


void set_showing_desktop(gboolean value)
{
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


void monitor_tasklist_and_activewindow()
{
    ATOM_CLIENT_LIST = gdk_x11_get_xatom_by_name("_NET_CLIENT_LIST");
    ATOM_ACTIVE_WINDOW = gdk_x11_get_xatom_by_name("_NET_ACTIVE_WINDOW");
    ATOM_NET_WM_ICON = gdk_x11_get_xatom_by_name("_NET_WM_ICON");

    GdkWindow* root = gdk_get_default_root_window();
    gdk_window_set_events(root, GDK_PROPERTY_CHANGE_MASK | gdk_window_get_events(root));

    gdk_window_add_filter(root, monitor_root_change, NULL);

    GdkDisplay* display = gdk_display_get_default();
    update_task_list(GDK_DISPLAY_XDISPLAY(display), GDK_WINDOW_XID(root));
}


double get_active_window()
{
}
char* get_task_list()
{
}
void active_window(double id)
{
}
void show_desktop()
{
}
