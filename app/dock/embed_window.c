#include <gtk/gtk.h>
#include <gdk/gdk.h>
#include <X11/X.h>
#include <X11/Xlib.h>
#include <gdk/gdkx.h>
#include "jsextension.h"
#include "dwebview.h"
#include "region.h"
#include <cairo.h>
#include "dock.h"
#include "dock_config.h"

#define __USE_BSD
#include <math.h>
#undef __USE_BSD

#define TRAY_ICON_SIZE 16

GdkWindow* GET_CONTAINER_WINDOW();

static void fix_reparent(GdkWindow* child, GdkWindow* parent);

#define SKIP_UNINIT(key) do {\
    if (__EMBEDED_WINDOWS__ == NULL) { \
        return;\
    }\
    if (g_hash_table_lookup(__EMBEDED_WINDOWS__, (gpointer)(Window)key) == NULL) {\
        return;\
    }\
}while(0)


enum _EmbedWindowType {
    EWTypeUnknown,
    EWTypePlugin,
    EWTypeTrayIcon,
};


GHashTable* __EMBEDED_WINDOWS__ = NULL;
GHashTable* __EMBEDED_WINDOWS_TARGET__ = NULL;
// key: xid, value: bool
GHashTable* __EMBEDED_WINDOWS_DRAWABLE__ = NULL;
GHashTable* __EMBEDED_WINDOWS_TYPE__ = NULL;

GdkWindow* get_wrapper(GdkWindow* win) { return g_object_get_data(G_OBJECT(win), "deepin_embed_window_wrapper"); }


GdkFilterReturn embed_window_configure_request(GdkXEvent* xevent G_GNUC_UNUSED,
                                      GdkEvent* event G_GNUC_UNUSED,
                                      gpointer data G_GNUC_UNUSED)
{
    XEvent* xev = (XEvent*)xevent;
    if (xev->type == ConfigureRequest) {
        XConfigureRequestEvent* xev = (XConfigureRequestEvent*)xevent;
        XResizeWindow(xev->display, xev->window, xev->width, xev->height);

        GdkWindow* find_embed_window(Window xid);
        GdkWindow* win = find_embed_window(xev->window);
        if (win == NULL) {
            g_warning("not find embeded window: %u", (guint32)(xev->window));
            return GDK_FILTER_CONTINUE;
        }

        JSObjectRef info = json_create();
        json_append_number(info, "XID", xev->window);
        json_append_number(info, "x", xev->x);
        json_append_number(info, "y", xev->y);
        json_append_number(info, "width", xev->width);
        json_append_number(info, "height",xev->height);
        js_post_message("embed_window_configure_request", info);
        return GDK_FILTER_TRANSLATE;
    } else if (xev->type == ConfigureNotify){
        XConfigureEvent* x = (XConfigureEvent*)xev;
        g_debug("window 0x%x configure notify", (unsigned)x->window);
    }

    return GDK_FILTER_CONTINUE;
}


void __init__embed__()
{
    if (__EMBEDED_WINDOWS__ == NULL) {
        void destroy_window(GdkWindow* child);
        __EMBEDED_WINDOWS__ = g_hash_table_new_full(g_direct_hash, g_direct_equal, NULL, (GDestroyNotify)destroy_window);
    }
    if (__EMBEDED_WINDOWS_TARGET__ == NULL) {
        __EMBEDED_WINDOWS_TARGET__ = g_hash_table_new(g_direct_hash, g_direct_equal);
    }
    if (__EMBEDED_WINDOWS_DRAWABLE__ == NULL) {
        __EMBEDED_WINDOWS_DRAWABLE__ = g_hash_table_new(g_direct_hash, g_direct_equal);
    }
    if (__EMBEDED_WINDOWS_TYPE__ == NULL) {
        __EMBEDED_WINDOWS_TYPE__ = g_hash_table_new(g_direct_hash, g_direct_equal);
    }
    XSelectInput(gdk_x11_get_default_xdisplay(),
                 GDK_WINDOW_XID(GET_CONTAINER_WINDOW()),
                 StructureNotifyMask|SubstructureNotifyMask|SubstructureRedirectMask);
    gdk_window_add_filter(GET_CONTAINER_WINDOW(), embed_window_configure_request, NULL);
}


void destroy_window(GdkWindow* win)
{
    GdkFilterReturn __monitor_embed_window(GdkXEvent *xevent, GdkEvent* ev, gpointer data);
    gdk_window_remove_filter(win, __monitor_embed_window, NULL);

    GdkWindow* wrapper = get_wrapper(win);
    if (wrapper) {
        gdk_window_destroy(wrapper);
    }

    Window xid = GDK_WINDOW_XID(win);
    if (__EMBEDED_WINDOWS_TYPE__ != NULL) {
        g_hash_table_remove(__EMBEDED_WINDOWS_TYPE__, (gpointer)xid);
    }
    if (__EMBEDED_WINDOWS_TARGET__ != NULL) {
        g_hash_table_remove(__EMBEDED_WINDOWS_TARGET__, (gpointer)xid);
    }
    if (__EMBEDED_WINDOWS_DRAWABLE__ != NULL) {
        g_hash_table_remove(__EMBEDED_WINDOWS_DRAWABLE__, (gpointer)xid);
    }
    g_object_unref(win);

}


GdkWindow* find_embed_window(Window xid)
{
    return (GdkWindow*)g_hash_table_lookup(__EMBEDED_WINDOWS__, (gpointer)xid);
}

GdkFilterReturn __monitor_embed_window(GdkXEvent *xevent, GdkEvent* ev, gpointer data)
{
    ev = ev;
    data  = data;
    XEvent* xev = xevent;
    if (xev->type == DestroyNotify) {
        Window xid = ((XDestroyWindowEvent*)xevent)->window;
        g_hash_table_remove(__EMBEDED_WINDOWS__, (gpointer)xid);

        JSObjectRef info = json_create();
        json_append_number(info, "XID", xid);
        js_post_message("embed_window_destroyed", info);
        return GDK_FILTER_CONTINUE;
    } else if (xev->type == ConfigureNotify) {
        XConfigureEvent* xev = (XConfigureEvent*)xevent;

        GdkWindow* win = (GdkWindow*)g_hash_table_lookup(__EMBEDED_WINDOWS__, (gpointer)xev->window);
        if (win != NULL) {
            GdkWindow *wrapper = get_wrapper(win);
            if (wrapper) {
                //TODO: seems no effect at this time
                gdk_window_resize(wrapper, xev->width, xev->height);
            }
            JSObjectRef info = json_create();
            json_append_number(info, "XID", xev->window);
            json_append_number(info, "x", xev->x);
            json_append_number(info, "y", xev->y);
            json_append_number(info, "width", xev->width);
            json_append_number(info, "height",xev->height);
            js_post_message("embed_window_configure_changed", info);
        }
        return GDK_FILTER_CONTINUE;
    } else if (xev->type == GenericEvent) {
        XGenericEvent* ge = xevent;
        if (ge->evtype == EnterNotify) {
            JSObjectRef info = json_create();
            // wrong xid is gotten from XEnterWindowEvent
            json_append_number(info, "XID", GDK_WINDOW_XID(((GdkEventMotion*)ev)->window));
            js_post_message("embed_window_enter", info);
        } else if (ge->evtype == LeaveNotify) {
            JSObjectRef info = json_create();
            json_append_number(info, "XID", GDK_WINDOW_XID(((GdkEventMotion*)ev)->window));
            js_post_message("embed_window_leave", info);
        }
        return GDK_FILTER_REMOVE;
    }
    return GDK_FILTER_CONTINUE;
}

GdkWindow* wrapper(Window xid, enum _EmbedWindowType type)
{
    GdkDisplay* dpy = gdk_window_get_display(GET_CONTAINER_WINDOW());
    GdkWindow* child = gdk_x11_window_foreign_new_for_display(dpy, xid);
    if (child == NULL) {
        return NULL;
    }
    int mask = GDK_ENTER_NOTIFY_MASK | GDK_LEAVE_NOTIFY_MASK | GDK_VISIBILITY_NOTIFY_MASK;
    gdk_window_set_events(child, mask);
    GdkWindow* parent = NULL;
    gint width = TRAY_ICON_SIZE, height = TRAY_ICON_SIZE;
    gdk_window_get_geometry(child, NULL, NULL, &width, &height);

    GdkVisual* visual = gdk_window_get_visual(child);
    if (gdk_visual_get_depth(visual) == 24) {
        GdkWindowAttr attr={0};
        attr.width = width;
        attr.width = width;
        attr.window_type = GDK_WINDOW_CHILD;
        attr.wclass = GDK_INPUT_OUTPUT;
        attr.event_mask = mask;
        attr.visual = visual;
        parent = gdk_window_new(GET_CONTAINER_WINDOW(), &attr, GDK_WA_VISUAL);
        g_object_set_data(G_OBJECT(child), "deepin_embed_window_wrapper", parent);

        fix_reparent(child, parent);
    } else {
        parent = child;
    }

    gdk_window_add_filter(child, __monitor_embed_window, NULL);
    gdk_window_show(child);

    g_hash_table_insert(__EMBEDED_WINDOWS__, (gpointer)xid, child);
    g_hash_table_insert(__EMBEDED_WINDOWS_TYPE__, (gpointer)xid, GINT_TO_POINTER(type));
    g_hash_table_insert(__EMBEDED_WINDOWS_DRAWABLE__, (gpointer)xid, (gpointer)TRUE);
    return parent;
}

//JS_EXPORT_API
void exwindow_create(double xid, gboolean enable_resize, double type)
{
    //TODO: handle this flag with SubStructureNotify
    enable_resize = enable_resize;
    Window win = (Window)xid;
    __init__embed__();
    GdkWindow* p = wrapper(win, (enum _EmbedWindowType)type);
    g_return_if_fail(p != NULL);

    fix_reparent(p, GET_CONTAINER_WINDOW());

    gdk_window_set_composited(p, TRUE);
    gdk_window_show(p);
}

//Window manager implemented with libmutter will cause reparent
//failed but without any error.
//Using an newly opened xdisplay instead of gdk_x11_get_default_display
//could workaround this.
static void fix_reparent(GdkWindow* child, GdkWindow* parent)
{
    gdk_window_reparent(child, parent, 0, 0);
    Display* dpy= XOpenDisplay(NULL);
    XReparentWindow(dpy,
            GDK_WINDOW_XID(child), GDK_WINDOW_XID(parent),
            0, 0);
    XFlush(dpy);
    XCloseDisplay(dpy);
}

JSValueRef exwindow_window_size(double xid)
{
    Window win = (Window)xid;
    GdkDisplay* dpy = gdk_window_get_display(GET_CONTAINER_WINDOW());
    GdkWindow* w = gdk_x11_window_foreign_new_for_display(dpy, win);
    gint width = 0, height = 0;
    if (w != NULL) {
        gdk_window_get_geometry(w, NULL, NULL, &width, &height);
    }
    JSObjectRef o = json_create();
    json_append_number(o, "width", width);
    json_append_number(o, "height", height);
    return o;
}


//JS_EXPORT_API
void exwindow_move_resize(double xid, double x, double y, double width, double height)
{
    SKIP_UNINIT(xid);
    GdkWindow* win = (GdkWindow*)g_hash_table_lookup(__EMBEDED_WINDOWS__, (gpointer)(Window)xid);
    g_return_if_fail(win != NULL);

    GdkWindow* wrapper = get_wrapper(win);
    if (wrapper) {
        gdk_window_move_resize(wrapper, (int)x, (int)y, (guint)width, (guint)height);
        gdk_window_move_resize(win, 0, 0, (guint)width, (guint)height);
    } else {
        gdk_window_move_resize(win, (int)x, (int)y, (guint)width, (guint)height);
    }
}

//JS_EXPORT_API
void exwindow_move(double xid, double x, double y)
{
    SKIP_UNINIT(xid);
    GdkWindow* win = (GdkWindow*)g_hash_table_lookup(__EMBEDED_WINDOWS__, (gpointer)(Window)xid);
    g_return_if_fail(win != NULL);

    GdkWindow* wrapper = get_wrapper(win);
    if (wrapper) {
        gdk_window_move(wrapper, (int)x, (int)y);
        gdk_window_move(win, 0, 0);
    } else {
        gdk_window_move(win, (int)x, (int)y);
    }
}

static gboolean draw_ew = TRUE;

//JS_EXPORT_API
void exwindow_undraw_all()
{
    draw_ew = FALSE;
}

//JS_EXPORT_API
void exwindow_undraw(double _xid)
{
    Window xid = (Window)_xid;
    SKIP_UNINIT(xid);
    g_hash_table_replace(__EMBEDED_WINDOWS_DRAWABLE__, (gpointer)xid, (gpointer)FALSE);
    GdkWindow* win = GDK_WINDOW(g_hash_table_lookup(__EMBEDED_WINDOWS__, (gpointer)xid));
    g_return_if_fail(win != NULL);

    GdkWindow *wrapper = get_wrapper(win);
    cairo_rectangle_int_t rect = {0,0,1,1};
    if (wrapper == NULL) {
        set_input_region(win, &rect);
    } else {
        set_input_region(wrapper, &rect);
    }
}


//JS_EXPORT_API
void exwindow_hide(double xid)
{
    SKIP_UNINIT(xid);
    GdkWindow* win = (GdkWindow*)g_hash_table_lookup(__EMBEDED_WINDOWS__, (gpointer)(Window)xid);
    g_return_if_fail(win != NULL);

    GdkWindow* wrapper = get_wrapper(win);
    if (wrapper) {
        gdk_window_hide(wrapper);
    } else {
        gdk_window_hide(win);
    }
}

//JS_EXPORT_API
void exwindow_show(double xid)
{
    draw_ew = TRUE;
    SKIP_UNINIT(xid);
    GdkWindow* win = (GdkWindow*)g_hash_table_lookup(__EMBEDED_WINDOWS__, (gpointer)(Window)xid);
    g_return_if_fail(win != NULL);

    GdkWindow* wrapper = get_wrapper(win);
    GdkWindow* valid_window = (wrapper == NULL ? win : wrapper);

    gboolean drawable = GPOINTER_TO_INT(g_hash_table_lookup(__EMBEDED_WINDOWS_DRAWABLE__, (gpointer)(Window)xid));

    if (!drawable) {
        // TODO:
        // this is just working for tray icons now.
        // other window may undraw in the future.
        g_hash_table_replace(__EMBEDED_WINDOWS_DRAWABLE__, (gpointer)(Window)xid, (gpointer)TRUE);
        cairo_rectangle_int_t rect = {0,0,TRAY_ICON_SIZE,TRAY_ICON_SIZE};
        set_input_region(valid_window, &rect);
    }

    gdk_window_show(valid_window);
}


void exwindow_draw_to_canvas(double _xid, JSValueRef canvas)
{
    Window xid = (Window)_xid;

    cairo_t* cr =  fetch_cairo_from_html_canvas(get_global_context(), canvas);

    g_hash_table_insert(__EMBEDED_WINDOWS_TARGET__, (gpointer)xid,
                            GINT_TO_POINTER((cr != NULL)));

    if (cr != NULL){
        GdkWindow* window = g_hash_table_lookup(__EMBEDED_WINDOWS__, (gpointer)xid);
        if (window != NULL) {
            gdk_window_show(window);
            gdk_window_flush(window);
            gdk_flush();
            // gdk_display_sync(gdk_display_get_default());
            // sleep(1);
            gdk_cairo_set_source_window(cr, window, 0, 0);
            g_warning("draw to canvas");
            cairo_paint(cr);

            /*cairo_surface_t* s = cairo_get_target(cr);*/
            /*cairo_surface_write_to_png(s, "/tmp/draw_to_canvas.png");*/

            canvas_custom_draw_did(cr, NULL);
        }
    }
}


gboolean draw_embed_windows(GtkWidget* _w, cairo_t *cr)
{
    if (!draw_ew)
        return FALSE;
    _w = _w;
    if (__EMBEDED_WINDOWS__ == NULL || g_hash_table_size(__EMBEDED_WINDOWS__) == 0) {
        return FALSE;
    }

    GHashTableIter iter;
    gpointer child = NULL;
    g_hash_table_iter_init (&iter, __EMBEDED_WINDOWS__);
    while (g_hash_table_iter_next (&iter, NULL, &child)) {
        GdkWindow* win = (GdkWindow*)child;
        GdkWindow* wrapper = get_wrapper(win);
        if (wrapper) {
            win = wrapper;
        }

        Window xid = GDK_WINDOW_XID(child);
        gboolean drawable = GPOINTER_TO_INT(g_hash_table_lookup(__EMBEDED_WINDOWS_DRAWABLE__, GINT_TO_POINTER(xid)));
        gboolean has_target =
            GPOINTER_TO_INT(g_hash_table_lookup(__EMBEDED_WINDOWS_TARGET__,
                                                GINT_TO_POINTER(xid)));
        enum _EmbedWindowType type = GPOINTER_TO_INT(g_hash_table_lookup(__EMBEDED_WINDOWS_TYPE__, GINT_TO_POINTER(xid)));
        // g_warning("draw_target: %d", draw_target);
        if (win != NULL && drawable && !gdk_window_is_destroyed(win) &&
            gdk_window_is_visible(win) && !has_target) {
            int x = 0;
            int y = 0;
            int width, height;
            gdk_window_get_geometry(win, &x, &y, &width, &height); //gdk_window_get_position will get error value when dock is hidden!

            if (type == EWTypeTrayIcon) {
                if (GD.config.display_mode == FASHION_MODE) {
                    cairo_save(cr);
                    cairo_arc(cr, x + TRAY_ICON_SIZE/2.0, y + TRAY_ICON_SIZE/2.0, TRAY_ICON_SIZE/2.0, 0, 2*M_PI);
                    cairo_clip(cr);
                    gdk_cairo_set_source_window(cr, win, x, y);
                    cairo_paint(cr);
                    cairo_restore(cr);
                } else {
                    gdk_cairo_set_source_window(cr, win, x, y);
                    cairo_paint(cr);
                }
            } else if (EWTypePlugin == type) {
                gdk_cairo_set_source_window(cr, win, x, y);
                cairo_paint(cr);
            }
        }
    }

    return FALSE;
}


//JS_EXPORT_API
void exwindow_dismiss(double _xid)
{
    if (__EMBEDED_WINDOWS__ == NULL) {
        g_debug("[%s] __EMBEDED_WINDOWS__ is NULL", __func__);
        return;
    }

    Window xid = (Window)_xid;
    GdkWindow* w = find_embed_window(xid);
    if (w == NULL) {
        g_debug("[%s] no such a embeded window %d", __func__, (guint32)xid);
        return;
    }

    if (gdk_window_is_destroyed(w)) {
        g_debug("[%s] %d is destroyed", __func__, (guint32)xid);
        g_hash_table_remove(__EMBEDED_WINDOWS__, w);
        return;
    }

    int reparentSucces = XReparentWindow(gdk_x11_get_default_xdisplay(), GDK_WINDOW_XID(w), GDK_ROOT_WINDOW(), 0, 0);
    g_debug("reparent: %d", reparentSucces);

    g_hash_table_remove(__EMBEDED_WINDOWS__, w);
}


#undef SKIP_UNINIT

// destroy
// allocation change

