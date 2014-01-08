/**
 * Copyright (c) 2011 ~ 2012 Deepin, Inc.
 *               2011 ~ 2012 snyh
 *               2013 ~ 2013 Liqiang Lee
 *
 * Author:      snyh <snyh@snyh.org>
 * Maintainer:  snyh <snyh@snyh.org>
 *              Liqiang Lee <liliqiang@linuxdeepin.com>
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
#include "dominant_color.h"
#include "dock_config.h"

#include <math.h>
#include <glib.h>

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
    if (*s <= 0) {
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

void set_default_rgb(double* r, double *g, double *b)
{
    hsv2rgb(200/360.0, 0.5, 0.8, r, g, b);
}

typedef void (*ClampFunc)(double*, double*);

void calc(guchar* data, guint length, int skip, double *r, double *g, double *b)
{
    long long a_r = 0;
    long long a_g = 0;
    long long a_b = 0;
    long count = 0;
    for (guint i=0; i<length; i += skip) {
        if (skip == 4 && data[i+3] < 125) {
            continue;
        }
        a_r += data[i];
        a_g += data[i+1];
        a_b += data[i+2];
        count++;
    }
    if (count == 0) {
        set_default_rgb(r, g, b);
        return;
    }
    double h, s, v;
    rgb2hsv(a_r / count, a_g / count, a_b / count, &h, &s, &v);
    hsv2rgb(h, 0.5, 0.8, r, g, b);
    if (s < 0.05) {
        set_default_rgb(r, g, b);
    }
}

void calc_dominant_color_by_pixbuf(GdkPixbuf* pixbuf, double *r, double *g, double *b)
{
    g_assert(pixbuf != NULL);
    guint size = 0;
    guchar* buf = gdk_pixbuf_get_pixels_with_length(pixbuf, &size);
    if (size == 0) {
        g_warning("Get an zero length valid pixbuf!!!\n");
        set_default_rgb(r, g, b);
    } else {
        calc(buf, size, gdk_pixbuf_get_n_channels(pixbuf), r, g, b);
    }
}

