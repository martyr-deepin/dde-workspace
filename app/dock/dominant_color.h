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
#ifndef DOMINANT_COLOR_H_AHUGBX7Z
#define DOMINANT_COLOR_H_AHUGBX7Z

#include <gdk-pixbuf/gdk-pixbuf.h>
void calc_dominant_color_by_pixbuf(GdkPixbuf* pixbuf, double *r, double *g, double *b);
void rgb2hsv(int r, int g, int b, double *h, double* s, double* v);
void hsv2rgb(double h, double s, double v, double* r, double*g, double *b);

#endif /* end of include guard: DOMINANT_COLOR_H_AHUGBX7Z */

