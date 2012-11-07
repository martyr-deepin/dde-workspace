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
#ifndef __X_MISC_H__
#define __X_MISC_H__

#include <gtk/gtk.h>
#include <gdk/gdkx.h>
void set_wmspec_desktop_hint(GdkWindow *window);
void set_wmspec_dock_hint(GdkWindow *window);

enum {
    ORIENTATION_LEFT,
    ORIENTATION_RIGHT,
    ORIENTATION_TOP,
    ORIENTATION_BOTTOM,
};
void set_struct_partial(GdkWindow* window, guint32 orientation, guint32 strut, guint32 begin, guint32 end);

void get_workarea_size(int screen_n, int desktop_n, int* x, int* y, int* width, int* height);

void watch_workarea_changes(GtkWidget* widget);

void unwatch_workarea_changes(GtkWidget* widget);

void get_wmclass (GdkWindow* xwindow, char **res_class, char **res_name);


void* get_window_property(Display* dsp, Window w, Atom pro, gulong* items);

#define X_FETCH_32(data, i) *((gulong*)data + i)
#define X_FETCH_16(data, i) *((short*)data + i)
#define X_FETCH_8(data, i) *((char*)data + i)


#endif
