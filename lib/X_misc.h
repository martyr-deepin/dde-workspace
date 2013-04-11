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

void get_wmclass (GdkWindow* xwindow, char **res_class, char **res_name);

cairo_region_t* get_window_input_region(Display* dpy, Window w);

void* get_window_property(Display* dsp, Window w, Atom pro, gulong* items);

gboolean has_atom_property(Display* dsp, Window w, Atom prop);

#define X_FETCH_32(data, i) *((gulong*)data + i)
#define X_FETCH_16(data, i) *((short*)data + i)
#define X_FETCH_8(data, i) *((char*)data + i)


#define GRAB_DEVICE(w) (gdk_device_grab(gdk_device_manager_get_client_pointer(gdk_display_get_device_manager(gdk_display_get_default())), w? w:gdk_get_default_root_window(), GDK_OWNERSHIP_WINDOW, TRUE, GDK_ALL_EVENTS_MASK, NULL, GDK_CURRENT_TIME))
#define UNGRAB_DEVICE() gdk_device_ungrab(gdk_device_manager_get_client_pointer(gdk_display_get_device_manager(gdk_display_get_default())), GDK_CURRENT_TIME)


void get_atom_value_by_index(gpointer data, gulong n_item, gpointer res, gulong index);
void get_atom_value_for_loop(gpointer data, gulong n_item, gpointer res, gulong start_index);

typedef void* CallbackFunc;
/**
 * For following 2 functions, pass -1 to index, the callback function will be
 * regarded as void (*f)(gpointer data, gulong n_item, gpointer res).
 *
 * This just works for self-defined functions.
 */
gboolean get_atom_value_by_atom(Display* dsp, Window id, Atom atom, gpointer res,
                                CallbackFunc callback, gulong index);
gboolean get_atom_value_by_name(Display* dsp, Window id, const char* name, gpointer res,
                                CallbackFunc callback, gulong index);
#endif
