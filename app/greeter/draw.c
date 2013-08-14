#include "glib.h"
#include "gdk/gdk.h"
#include "gdk/gdkx.h"
#include "cairo.h"

#include "dwebview.h"
#include "jsextension.h"
#include "camera.h"
#include "X_misc.h"


void callback(gpointer data, gulong n_item, gpointer res)
{
    *(char**)res = g_strdup(data);
}

void _draw_camera(JSValueRef canvas, double dest_width, double dest_height, JSData* data)
{
    if (JSValueIsNull(data->ctx, canvas)) {
        /* g_debug("draw with null canvas!"); */
        return;
    }

    /* g_warning("[_draw_camera] draw camera"); */
    Display* _dsp = GDK_DISPLAY_XDISPLAY(gdk_display_get_default());
    static GdkWindow* win = NULL;

    if (win == NULL) {
        gulong items;
        Atom ATOM_CLIENT_LIST = gdk_x11_get_xatom_by_name("_NET_CLIENT_LIST");
        void* xdata = get_window_property(_dsp, GDK_ROOT_WINDOW(), ATOM_CLIENT_LIST, &items);
        if (xdata == NULL) {
            return;
        }

        Window xid = 0;
        for (int i=0; i<items; i++) {
            xid = X_FETCH_32(xdata, i);

            char* name = NULL;
            get_atom_value_by_name(_dsp, xid, "_NET_WM_NAME", &name, callback, -1);

            if (name && g_str_equal(name, CAMERA)) {
                g_free(name);
                win = gdk_x11_window_foreign_new_for_display(gdk_display_get_default(), xid);
                gdk_window_iconify(win);  // to avoid the window being saw when quit login
                break;
            }

            g_free(name);
        }
        XFree(xdata);
        if (win == NULL) {
            /* g_warning("[_draw_camera] has no window to draw"); */
            return;
        }
    }

    gdk_window_iconify(win);  // to avoid the window being saw when quit login

    cairo_t* cr = fetch_cairo_from_html_canvas(data->ctx, canvas);
    cairo_save(cr);

    double width = gdk_window_get_width(win);
    double height = gdk_window_get_height(win);

    if (width > height) {
        double scale = dest_height/height;
        cairo_scale(cr, scale, scale);
        gdk_cairo_set_source_window(cr, win, 0, 0.5*(dest_height/scale-height));
    } else {
        double scale = dest_width/width;
        cairo_scale(cr, scale, scale);
        gdk_cairo_set_source_window(cr, win, 0.5*(dest_width/scale-width), 0);
    }

    cairo_paint(cr);
    cairo_restore(cr);

    canvas_custom_draw_did(cr, NULL);
}


JS_EXPORT_API
void greeter_draw_camera(JSValueRef canvas, double dest_width, double dest_height, JSData* data)
{
    _draw_camera(canvas, dest_width, dest_height, data);
}


JS_EXPORT_API
void lock_draw_camera(JSValueRef canvas, double width, double height, JSData* data)
{
    _draw_camera(canvas, width, height, data);
}
