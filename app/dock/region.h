/**
 * Copyright (c) 2011 ~ 2012 Deepin, Inc.
 *               2011 ~ 2012 snyh
 *
 * Author:      snyh <snyh@snyh.org>
 * Maintainer:  snyh <snyh@snyh.org>
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
#ifndef __REGION_H__
#define __REGION_H__

#include <gtk/gtk.h>

void init_region(GdkWindow* win, double x, double y, double width, double height);
void dock_set_region_origin(double x, double y);
void dock_require_region(double x, double y, double width, double height);
void dock_release_region(double x, double y, double width, double height);

gboolean dock_region_overlay(const cairo_rectangle_int_t* tmp);
void region_rectangles();
gboolean pointer_in_region(int x, int y);

#endif
