#include <gtk/gtk.h>
#include <math.h>
#include "calc.h"

void rgb2hsv(int r, int g, int b, double *h, double* s, double* v)
{
    int min_rgb = MIN(r, MIN(g, b));
    int max_rgb = MAX(r, MAX(g, b));
    int delta_rgb = max_rgb - min_rgb;

    *v = max_rgb / 256.0;

    if (max_rgb != 0) {
        *s = (max_rgb - min_rgb) * 1.0 / max_rgb;
    } else {
        *s = 0;
    }

    double _h = 0; 
    if (s <= 0) {
        _h = 0;
    } else if (delta_rgb != 0){

        if (max_rgb == r) {
            _h = (g - b) * 1.0 / delta_rgb;
        } else if (max_rgb == g) {
            _h = 2.0 + (b -r ) * 1.0 / delta_rgb;
        } else {
            _h = 4.0 + (r -g ) * 1.0 / delta_rgb;
        }
        _h *= 60.0;

        if (_h < 0.0)
            _h += 360.0;
        _h /= 360;
    } else {
        _h = 0;
    }
    *h = _h;
}

void hsv2rgb(double h, double s, double v, double* r, double*g, double *b)
{
    if (s <= 0.0) {
       *r = *g = *b = 0;
    } else {
        int k = 0;
        if (h == 1.0) h = 0.0;
        h *= 6.0;
        k = floor(h);
        double f = h - k;
        double aa = v * (1 - s);
        double bb = v * (1 - (s * f));
        double cc = v * (1 - (s * (1 - f)));

        switch (k) {
            case 0: *r = v;  *g = cc; *b = aa ; break;
            case 1: *r = bb; *g = v; *b = aa; break;
            case 2: *r = aa; *g = v; *b = cc; break;
            case 3: *r = aa; *g = bb; *b = v; break;
            case 4: *r = cc; *g = aa; *b = v; break;
            case 5: *r = v; *g = aa; *b = bb; break;
        }
    }
}

void calc(guchar* data, guint length, int skip, double *r, double *g, double *b, ClampFunc func)
{
    long long a_r = 0;
    long long a_g = 0;
    long long a_b = 0;
    for (guint i=0; i<length; i += skip) {
        a_r += data[i];
        a_g += data[i+1];
        a_b += data[i+2];
    }
    long count = length / skip;
    double h, s, v;
    rgb2hsv(a_r / count, a_g / count, a_b / count, &h, &s, &v);
    func(&s, &v);
    hsv2rgb(h, s, v, r, g, b);
}

void calc_dominant_color_by_path(const char* path, double *r, double *g, double *b, ClampFunc func)
{
    GdkPixbuf* pixbuf = gdk_pixbuf_new_from_file(path, NULL);
    if (path != NULL) {
        int width = gdk_pixbuf_get_width(pixbuf);
        int stride = gdk_pixbuf_get_rowstride(pixbuf);
        guint size = 0;
        guchar* buf = gdk_pixbuf_get_pixels_with_length(pixbuf, &size);
        calc(buf, size, stride / width, r, g, b, func);
        g_object_unref(pixbuf);
    } else {
        *r = 0;
        *g = 0;
        *b = 0;
    }
}

void draw_board(cairo_t* cr, cairo_surface_t* img, cairo_surface_t* mask, double r, double g, double b)
{

    cairo_save(cr);
    cairo_set_operator(cr, CAIRO_OPERATOR_CLEAR);
    cairo_paint(cr);
    cairo_restore(cr);

    cairo_save(cr);
    cairo_set_source_rgb(cr, r, g, b);
    cairo_mask_surface(cr, mask, 0, 0);
    cairo_clip(cr);
    cairo_paint(cr);
    cairo_restore(cr);

    cairo_set_source_surface(cr, img, 5, 5);
    cairo_paint(cr);
}
