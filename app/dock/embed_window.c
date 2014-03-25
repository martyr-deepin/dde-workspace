#include <gtk/gtk.h>
#include <X11/X.h>
#include <gdk/gdkx.h>
#include "jsextension.h"
#include "dwebview.h"


GdkWindow* GET_CONTAINER_WINDOW();

#define SKIP_UNINIT(key) do {\
    if (__EMBEDED_WINDOWS__ == NULL) { \
	return;\
    }\
    if (g_hash_table_lookup(__EMBEDED_WINDOWS__, (gpointer)(Window)key) == NULL) {\
	return;\
    }\
}while(0)

GHashTable* __EMBEDED_WINDOWS__ = NULL;
GHashTable* __EMBEDED_WINDOWS_TARGET__ = NULL;

void __init__embed__()
{
    if (__EMBEDED_WINDOWS__ == NULL) {
	__EMBEDED_WINDOWS__ = g_hash_table_new(g_direct_hash, g_direct_equal);
    }
    if (__EMBEDED_WINDOWS_TARGET__ == NULL) {
	__EMBEDED_WINDOWS_TARGET__ = g_hash_table_new(g_direct_hash, g_direct_equal);
    }
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

	JSObjectRef info = json_create();
	json_append_number(info, "XID", xev->window);
	json_append_number(info, "x", xev->x);
	json_append_number(info, "y", xev->y);
	json_append_number(info, "width", xev->width);
	json_append_number(info, "height",xev->height);
	js_post_message("embed_window_configure_changed", info);

        return GDK_FILTER_REMOVE;
    } else if (xev->type == GenericEvent) {
	XGenericEvent* ge = xevent;
	if (ge->evtype == EnterNotify) {
	    JSObjectRef info = json_create();
	    json_append_number(info, "XID", ((XEnterWindowEvent*)xev)->window);
	    js_post_message("embed_window_enter", info);
	} else if (ge->evtype == LeaveNotify) {
	    JSObjectRef info = json_create();
	    json_append_number(info, "XID", ((XEnterWindowEvent*)xev)->window);
	    js_post_message("embed_window_leave", info);
	}
	return GDK_FILTER_REMOVE;
    } else if (xev->type == Expose) {
    }
    return GDK_FILTER_CONTINUE;
}

//JS_EXPORT_API
void exwindow_create(double xid, gboolean enable_resize)
{
    enable_resize = enable_resize;
    Window win = (Window)xid;
    __init__embed__();
    GdkDisplay* dpy = gdk_window_get_display(GET_CONTAINER_WINDOW());
    GdkWindow* child = gdk_x11_window_foreign_new_for_display(dpy, win);
    if (child != NULL) {
	g_hash_table_insert(__EMBEDED_WINDOWS__, (gpointer)win, child);

	gdk_window_reparent(child, GET_CONTAINER_WINDOW(), 0, 0);
	gdk_window_set_composited(child, TRUE);
	gdk_window_add_filter(child, __monitor_embed_window, NULL);
        gdk_window_show(child);
    }
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
    if (win != NULL) {
	gdk_window_move_resize(win, x, y, width, height);
    }
}

//JS_EXPORT_API
void exwindow_move(double xid, double x, double y)
{
    SKIP_UNINIT(xid);
    GdkWindow* win = (GdkWindow*)g_hash_table_lookup(__EMBEDED_WINDOWS__, (gpointer)(Window)xid);
    if (win != NULL) {
	gdk_window_move(win, x, y);
    }
}

//JS_EXPORT_API
void exwindow_hide(double xid)
{
    SKIP_UNINIT(xid);
    GdkWindow* win = (GdkWindow*)g_hash_table_lookup(__EMBEDED_WINDOWS__, (gpointer)(Window)xid);
    if (win != NULL) {
	gdk_window_hide(win);
    }
}

//JS_EXPORT_API
void exwindow_show(double xid)
{
    SKIP_UNINIT(xid);
    GdkWindow* win = (GdkWindow*)g_hash_table_lookup(__EMBEDED_WINDOWS__, (gpointer)(Window)xid);
    if (win != NULL) {
	gdk_window_show(win);
    } else {
        g_warning("window not found");
    }
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
            cairo_save(cr);
            gdk_window_show(window);
            gdk_window_flush(window);
            gdk_flush();
            // gdk_display_sync(gdk_display_get_default());
            // sleep(1);
            gdk_cairo_set_source_window(cr, window, 0, 0);
            g_warning("draw to canvas");
            cairo_paint(cr);

            cairo_surface_t* s = cairo_get_target(cr);
            cairo_surface_write_to_png(s, "/tmp/draw_to_canvas.png");

            cairo_restore(cr);

            canvas_custom_draw_did(cr, NULL);
        }
    }
}


gboolean draw_embed_windows(GtkWidget* _w, cairo_t *cr)
{
    _w = _w;
    if (__EMBEDED_WINDOWS__ == NULL) {
	return FALSE;
    }
    GHashTableIter iter;
    gpointer child = NULL;
    g_hash_table_iter_init (&iter, __EMBEDED_WINDOWS__);
    while (g_hash_table_iter_next (&iter, NULL, &child)) {
	GdkWindow* win = (GdkWindow*)child;
        Window xid = GDK_WINDOW_XID(child);
        gboolean has_target =
            GPOINTER_TO_INT(g_hash_table_lookup(__EMBEDED_WINDOWS_TARGET__,
                                                GINT_TO_POINTER(xid)));
        // g_warning("draw_target: %d", draw_target);
	if (win != NULL && !gdk_window_is_destroyed(win) &&
            gdk_window_is_visible(win) &&
            !has_target) {
	    int x = 0;
	    int y = 0;
	    gdk_window_get_geometry(win, &x, &y, NULL, NULL); //gdk_window_get_position will get error value when dock is hidden!
	    gdk_cairo_set_source_window(cr, win, x, y);
	    cairo_paint(cr);
            // cairo_surface_t* s = cairo_get_group_target(cr);
            // cairo_surface_write_to_png(s, "/tmp/t.png");
	}
    }
    return FALSE;
}


#undef SKIP_UNINIT

// destroy
// allocation change

