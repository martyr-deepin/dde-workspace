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
#include "dock.h"
#include "dock_hide.h"
#include "region.h"
#include "dock_config.h"
#include "X_misc.h"
#include "jsextension.h"
#include <gtk/gtk.h>
#include <gdk/gdkx.h>
#include "DBUS_dock.h"

extern gboolean mouse_pointer_leave();


JS_EXPORT_API
void dock_update_panel_width(double width)
{
    GD.dock_panel_width = (int)width;
}


void get_mouse_position(int* x, int* y)
{
    GdkDeviceManager *device_manager;
    GdkDevice *pointer;

    device_manager = gdk_display_get_device_manager(gdk_display_get_default());
    pointer = gdk_device_manager_get_client_pointer(device_manager);
    gdk_device_get_position(pointer, NULL, x, y);
}

gboolean is_mouse_in_dock()
{
    int x = 0, y = 0;
    get_mouse_position(&x, &y);
    return mouse_pointer_leave(x, y);
}

