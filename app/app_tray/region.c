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


GdkWindow* _win = NULL;


void set_region(double x, double y, double width, double height)
{
    cairo_rectangle_int_t tmp = {(int)x, (int)y, (int)width, (int)height};
    cairo_region_t* _region = cairo_region_create_rectangle(&tmp);
    g_warning("%dx%d (%d, %d)", tmp.width, tmp.height, tmp.x, tmp.y);
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

