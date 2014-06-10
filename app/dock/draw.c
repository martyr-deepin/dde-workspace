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
#include <glib/gstdio.h>
#include "dwebview.h"
#include "dock_config.h"
#include "pixbuf.h"
#include "dominant_color.h"

#include <math.h>

//c99 didn't define M_PI and so on.
#ifndef M_PI_2
#define M_PI_2 1.57079632679489661923
#endif


GdkPixbuf* image_path(char const* name, double width, double height)
{
    char* path = g_strdup_printf(RESOURCE_DIR"dock/%s", name);
    GError* error = NULL;
    GdkPixbuf* img = gdk_pixbuf_new_from_file_at_scale(path, width, height, FALSE, &error);
    if (error != NULL) {
        g_warning("[%s] load file failed: %s", __func__, error->message);
        g_clear_error(&error);
    }
    g_free(path);
    return img;
}


JS_EXPORT_API
void dock_draw_panel(JSValueRef canvas,
                     char const* left_image,
                     char const* middle_image,
                     char const* right_image,
                     double panel_width,
                     double margin_width,
                     double panel_height
                     )
{
    cairo_t* cr =  fetch_cairo_from_html_canvas(get_global_context(), canvas);

    if (cr == NULL) {
        g_warning("[%s] get cairo failed, maybe canvas is not ready or "
                  "gets 0 width or 0 height.", __func__);
        return;
    }

    double middle_width = panel_width - margin_width * 2;
    if ((margin_width <= 0 && margin_width != -1)
        || (middle_width <= 0 && middle_width != -1)) {
        g_warning("[%s] width is invalid: margin_width: %lf, middle width: %lf",
                  __func__, margin_width, middle_width);
        return;
    }

    GdkPixbuf* left = image_path(left_image, margin_width, panel_height);
    GdkPixbuf* middle = image_path(middle_image, middle_width, panel_height);
    GdkPixbuf* right = image_path(right_image, margin_width, panel_height);

    if (left == NULL || middle == NULL || right == NULL) {
        g_warning("[%s] load image failed", __func__);
        return ;
    }

    cairo_save(cr);

    cairo_set_operator(cr, CAIRO_OPERATOR_CLEAR);
    cairo_paint(cr);
    cairo_set_operator(cr, CAIRO_OPERATOR_OVER);

    gdk_cairo_set_source_pixbuf(cr, left, 1, 0);
    cairo_paint(cr);

    gdk_cairo_set_source_pixbuf(cr, middle, margin_width + 1, 0);
    cairo_paint(cr);

    gdk_cairo_set_source_pixbuf(cr, right, panel_width - margin_width + 1, 0);
    cairo_paint(cr);
    cairo_restore(cr);

    canvas_custom_draw_did(cr, NULL);

    g_object_unref(left);
    g_object_unref(middle);
    g_object_unref(right);
}

void draw_app_icon(JSValueRef canvas, double id, double number)
{
    (void)canvas;
    (void)id;
    (void)number;
}

