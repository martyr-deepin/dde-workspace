/**
 * Copyright (c) 2011 ~ 2013 Deepin, Inc.
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
#include "dwebview.h"
#include "dock_config.h"

#include <math.h>

//c99 didn't define M_PI and so on.
#ifndef M_PI_2
#define M_PI_2 1.57079632679489661923
#endif

#define TO_DOUBLE(c) ( (c) / 255.0)
#define GET_R(c) TO_DOUBLE(c >> 24)
#define GET_G(c) TO_DOUBLE(c >> 16 & 0xff)
#define GET_B(c) TO_DOUBLE(c >> 8 & 0xff)
#define GET_A(c) ((c & 0xff) / 100.0)


GdkPixbuf* image_path(char const* name, double width, double height)
{
    char* path = g_strdup_printf(RESOURCE_DIR"dock/%s", name);
    g_warning("[%s] path %s", __func__, path);
    GdkPixbuf* img = gdk_pixbuf_new_from_file_at_scale(path, width, height, FALSE, NULL);
    g_assert(img != NULL);
    g_free(path);
    return img;
}


JS_EXPORT_API
void dock_draw_panel(JSValueRef canvas,
                     char const* left_image,
                     char const* middle_image,
                     char const* right_image,
                     double panel_width,
                     double side_width,
                     double panel_height
                     )
{
    cairo_t* cr =  fetch_cairo_from_html_canvas(get_global_context(), canvas);

    if (cr == NULL)
        g_warning("test");

    // g_warning("side width: %lf, panel_width: %lf, panel height: %lf", side_width, panel_width, panel_height);

    GdkPixbuf* left = image_path(left_image, side_width, panel_height);
    // GdkPixbuf* middle = image_path(middle_image, panel_width - side_width, panel_height);
    // GdkPixbuf* right = image_path(right_image, side_width, panel_height);

    cairo_save(cr);
    // gdk_cairo_set_source_pixbuf(cr, left, 0, 0);
    // cairo_paint(cr);
    // gdk_cairo_set_source_pixbuf(cr, middle, side_width, 0);
    // cairo_paint(cr);
    // gdk_cairo_set_source_pixbuf(cr, right, panel_width - side_width, 0);
    canvas_custom_draw_did(cr, NULL);
    g_object_unref(left);
    // g_object_unref(middle);
    // g_object_unref(right);
    return;
    int w = gdk_screen_get_width(gdk_screen_get_default());
    // TODO: may pass a w.

    cairo_save(cr);
    cairo_set_source_rgba(cr,
            GET_R(GD.config.color),
            GET_G(GD.config.color),
            GET_B(GD.config.color),
            GET_A(GD.config.color)
            );
    cairo_paint(cr);

    cairo_set_line_width(cr, 1);
    cairo_set_source_rgba(cr, 0, 0, 0, 0.2);
    cairo_move_to(cr, 0, 0.5);
    cairo_line_to(cr, w, 0.5);
    cairo_stroke(cr);

    cairo_set_source_rgba(cr, 1, 1, 1, 0.08);
    cairo_move_to(cr, 0, 1.5);
    cairo_line_to(cr, w, 1.5);
    cairo_stroke(cr);


    /*cairo_set_source_rgba(cr, 0, 0, 0, 0.05);*/

    /*int l = h-4-3;*/
    /*int b = w/2;*/
    /*double r = (b*b+l*l) / (2.0 * l);*/
    /*double e = asin(b / r);*/

    /*cairo_move_to(cr, w, 3);*/
    /*cairo_arc(cr, b, l-r , r, M_PI_2-e, M_PI_2+e);*/

    /*cairo_line_to(cr, 0, h);*/
    /*cairo_line_to(cr, w, h);*/
    /*cairo_line_to(cr, w, 3);*/
    /*cairo_close_path(cr);*/
    /*cairo_clip(cr);*/
    /*cairo_paint(cr);*/
    /*cairo_restore(cr);*/

    canvas_custom_draw_did(cr, NULL);
}

void draw_app_icon(JSValueRef canvas, double id, double number)
{
}

