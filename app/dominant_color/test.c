#include "jsextension.h"
#include "dwebview.h"
#include <gtk/gtk.h>
typedef void (*ClampFunc)(double* s, double* v);

void clamp1(double* s, double *v)
{
    *s = 0.15 + 0.1 * (*s);
    *v = 0.15 + 0.1 * (*v);
}

void draw_with_clamp(cairo_t* cr, GdkPixbuf* icon, ClampFunc c)
{
    gdk_cairo_set_source_pixbuf(cr, icon, 0, 0);
    cairo_paint(cr);
}

JS_EXPORT_API
void dominantcolor_draw1(JSValueRef canvas, const char* path, JSData* data)
{
    cairo_t* cr =  fetch_cairo_from_html_canvas(data->ctx, canvas);
    printf("get path %s\n", path);
    GdkPixbuf* pixbuf = gdk_pixbuf_new_from_file(path, NULL);
    if (pixbuf) {
        draw_with_clamp(cr, pixbuf, clamp1);
        g_object_unref(pixbuf);
    }
    canvas_custom_draw_did(cr, NULL);
}
JS_EXPORT_API
void dominantcolor_draw2(JSValueRef canvas, const char* path, JSData* data)
{
}
JS_EXPORT_API
void dominantcolor_draw3(JSValueRef canvas, const char* path, JSData* data)
{
}
JS_EXPORT_API
void dominantcolor_draw4(JSValueRef canvas, const char* path, JSData* data)
{
}
