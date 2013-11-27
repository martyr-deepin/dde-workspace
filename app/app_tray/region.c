/**
 * Copyright (c) 2011 ~ 2013 Deepin, Inc.
 *               2013 ~ 2013 Liqiang Lee
 *
 * Author:      snyh <snyh@snyh.org>
 * Maintainer:  Liqiang Lee <liliqiang@linuxdeepin.com>
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

#include "main.h"
#include "region.h"
#include "tray.h"
#include <math.h>


GdkWindow* _win = NULL;


void set_region(double _x, double _y, double _width, double _height)
{
    int x = (int)_x, y = (int)_y, width = (int)_width, height = (int)_height;

    cairo_surface_t* surface = cairo_image_surface_create(CAIRO_FORMAT_ARGB32, gdk_screen_width(), height);
    cairo_t* cr = cairo_create(surface);

    cairo_save(cr);
    cairo_translate(cr, (gdk_screen_width() - width)/2, 0);
    cairo_new_path(cr);
    cairo_line_to(cr, width, 0);
    cairo_line_to(cr, width, height - TRAY_CORNER_RADIUS);
    cairo_arc(cr,
              width - TRAY_CORNER_RADIUS,
              height - TRAY_CORNER_RADIUS,
              TRAY_CORNER_RADIUS,
              0,
              M_PI * .5
              );
    cairo_line_to(cr, TRAY_CORNER_RADIUS, height);
    cairo_arc(cr,
              TRAY_CORNER_RADIUS,
              height - TRAY_CORNER_RADIUS,
              TRAY_CORNER_RADIUS,
              M_PI * .5,
              M_PI
              );
    cairo_line_to(cr, 0, 0);
    cairo_close_path(cr);
    cairo_set_source_rgba(cr, 0, 1, 0, 1);
    cairo_fill(cr);
    cairo_clip(cr);
    cairo_restore(cr);

    cairo_destroy(cr);

    /* cairo_surface_write_to_png(surface, "/tmp/test.png"); */
    cairo_region_t* _region = gdk_cairo_region_create_from_surface(surface);
    cairo_surface_destroy(surface);

    gdk_window_input_shape_combine_region(_win, _region, 0, 0);
    gdk_window_shape_combine_region(_win, _region, 0, 0);
    cairo_region_destroy(_region);
}


void init_region(GdkWindow* win, double x, double y, double width, double height)
{
    _win = win;
    set_region(x, y, width, height);
}


void update_tray_region(double width)
{
    int x = (gdk_screen_width() - width) / 2;
    set_region(x, 0, width, TRAY_HEIGHT);
}

