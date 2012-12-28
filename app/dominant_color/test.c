#include "jsextension.h"
#include "dwebview.h"
#include <gtk/gtk.h>
#include "calc.h"

cairo_surface_t* _board = NULL;
cairo_surface_t* _mask = NULL;
double _board_scale = .1;
double _mask_scale = .1;

void dominantcolor_set_board(const char* path)
{
    cairo_surface_destroy(_board);
    _board = cairo_image_surface_create_from_png(path);
    _board_scale = 48.0 / cairo_image_surface_get_width(_board);
}
void dominantcolor_set_mask(const char* path)
{
    cairo_surface_destroy(_mask);
    _mask = cairo_image_surface_create_from_png(path);
    _mask_scale = 48.0 / cairo_image_surface_get_width(_mask);
}

double _sb = 0.15;
double _sr = 0.1;
double _vb = 0.8;
double _vr = 0.1;
JS_EXPORT_API
void dominantcolor_set_range(double sb, double sr, double vb, double vr)
{
    _sb = sb;
    _sr = sr;
    _vb = vb;
    _vr = vr;
}

void clamp1(double* s, double *v)
{
    *s = _sb + _sr * (*s);
    *v = _vb + _vr * (*v);
}
void clamp2(double* s, double *v)
{
    *s = _sb - _sr * (*s);
    *v = _vb + _vr * (*v);
}
void clamp3(double* s, double *v)
{
    *s = _sb + _sr * (*s);
    *v = _vb - _vr * (*v);
}
void clamp4(double* s, double *v)
{
    *s = _sb - _sr * (*s);
    *v = _vb - _vr * (*v);
}


JSObjectRef dominantcolor_get_color(const char* path, double _method)
{
    double r, g, b;
    int method = _method;
    switch(method) {
        case 1:
            calc_dominant_color_by_path(path, &r, &g, &b, clamp1);
            break;
        case 2:
            calc_dominant_color_by_path(path, &r, &g, &b, clamp2);
            break;
        case 3:
            calc_dominant_color_by_path(path, &r, &g, &b, clamp3);
            break;
        case 4:
            calc_dominant_color_by_path(path, &r, &g, &b, clamp4);
            break;
    }
    JSObjectRef json = json_create();
    json_append_number(json, "r", r * 256);
    json_append_number(json, "g", g * 256);
    json_append_number(json, "b", b * 256);
    return json;
}


JS_EXPORT_API
void dominantcolor_draw1(JSValueRef canvas, const char* path, double size, JSData* data)
{
    if (_mask && _board) {
        cairo_t* cr =  fetch_cairo_from_html_canvas(data->ctx, canvas);
        GdkPixbuf* pixbuf = gdk_pixbuf_new_from_file_at_size(path, size, size, NULL);
        if (pixbuf) {
            double r, g, b;
            calc_dominant_color_by_path(path, &r, &g, &b, clamp1);

            cairo_save(cr);
            cairo_scale(cr, _board_scale, _board_scale);
            draw_board(cr, _board, _mask, r, g, b);
            cairo_restore(cr);

            gdk_cairo_set_source_pixbuf(cr,  pixbuf, 4, 4);
            cairo_paint(cr);
            g_object_unref(pixbuf);
        }
        canvas_custom_draw_did(cr, NULL);
    }
}

JS_EXPORT_API
void dominantcolor_draw2(JSValueRef canvas, const char* path, double size, JSData* data)
{
    if (_mask && _board) {
        cairo_t* cr =  fetch_cairo_from_html_canvas(data->ctx, canvas);
        GdkPixbuf* pixbuf = gdk_pixbuf_new_from_file_at_size(path, size, size, NULL);
        if (pixbuf) {
            double r, g, b;
            calc_dominant_color_by_path(path, &r, &g, &b, clamp2);

            cairo_save(cr);
            cairo_scale(cr, _board_scale, _board_scale);
            draw_board(cr, _board, _mask, r, g, b);
            cairo_restore(cr);

            gdk_cairo_set_source_pixbuf(cr,  pixbuf, 4, 4);
            cairo_paint(cr);
            g_object_unref(pixbuf);
        }
        canvas_custom_draw_did(cr, NULL);
    }
}
JS_EXPORT_API
void dominantcolor_draw3(JSValueRef canvas, const char* path, double size, JSData* data)
{
    if (_mask && _board) {
        cairo_t* cr =  fetch_cairo_from_html_canvas(data->ctx, canvas);
        GdkPixbuf* pixbuf = gdk_pixbuf_new_from_file_at_size(path, size, size, NULL);
        if (pixbuf) {
            double r, g, b;
            calc_dominant_color_by_path(path, &r, &g, &b, clamp3);

            cairo_save(cr);
            cairo_scale(cr, _board_scale, _board_scale);
            draw_board(cr, _board, _mask, r, g, b);
            cairo_restore(cr);

            gdk_cairo_set_source_pixbuf(cr,  pixbuf, 4, 4);
            cairo_paint(cr);
            g_object_unref(pixbuf);
        }
        canvas_custom_draw_did(cr, NULL);
    }
}
JS_EXPORT_API
void dominantcolor_draw4(JSValueRef canvas, const char* path, double size, JSData* data)
{
    if (_mask && _board) {
        cairo_t* cr =  fetch_cairo_from_html_canvas(data->ctx, canvas);
        GdkPixbuf* pixbuf = gdk_pixbuf_new_from_file_at_size(path, size, size, NULL);
        if (pixbuf) {
            double r, g, b;
            calc_dominant_color_by_path(path, &r, &g, &b, clamp4);

            cairo_save(cr);
            cairo_scale(cr, _board_scale, _board_scale);
            draw_board(cr, _board, _mask, r, g, b);
            cairo_restore(cr);

            gdk_cairo_set_source_pixbuf(cr,  pixbuf, 4, 4);
            cairo_paint(cr);
            g_object_unref(pixbuf);
        }
        canvas_custom_draw_did(cr, NULL);
    }
}
