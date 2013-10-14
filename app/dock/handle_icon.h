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
#ifndef __HANDLE_ICON_H__
#define __HANDLE_ICON_H__

#include <glib.h>
#include <gdk-pixbuf/gdk-pixbuf.h>

#define BOARD_WIDTH 48
#define BOARD_HEIGHT 48
#define BOARD_OFFSET BOARD_HEIGHT - 50
#define BOARD_OFFSET BOARD_HEIGHT - 50
#define IMG_WIDTH 36
#define IMG_HEIGHT 36
#define MARGIN_LEFT ((BOARD_WIDTH-IMG_WIDTH)/2)
#define MARGIN_TOP ((BOARD_HEIGHT-IMG_HEIGHT)/2)


char* get_data_uri_by_surface(cairo_surface_t* surface);
char* handle_icon(GdkPixbuf* icon, gboolean);
void try_get_deepin_icon(const char* app_id, char** icon, int* operator_code);


#endif
