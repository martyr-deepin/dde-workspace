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

extern void _change_workarea_height(int height);
extern GdkWindow* DOCK_GDK_WINDOW();
extern gboolean mouse_pointer_leave();
extern gboolean dock_has_maximize_client();
extern double dock_get_active_window();
guint update_hide_state_timer = 0;

#define GUARD_WINDOW_HEIGHT 1


GdkWindow* get_dock_guard_window()
{
    // update_display_info(&dock);
    static GdkWindow* guard_window = NULL;
    if (guard_window == NULL) {
        GdkWindowAttr attributes;
        attributes.width = dock.width - 10;
        attributes.height = GUARD_WINDOW_HEIGHT;
        attributes.window_type = GDK_WINDOW_TEMP;
        attributes.wclass = GDK_INPUT_OUTPUT;
#ifdef NDEBUG
        attributes.wclass = GDK_INPUT_ONLY;
#endif
        attributes.event_mask = GDK_ENTER_NOTIFY_MASK;
        /*attributes.event_mask = GDK_ALL_EVENTS_MASK;*/

        guard_window = gdk_window_new(NULL, &attributes, 0);
#ifdef NDEBUG
        GdkRGBA rgba = { 0, 0, 0, 0 };
#else
        GdkRGBA rgba = { 233, 233, 233, 1 };
#endif
        set_wmspec_dock_hint(guard_window);
        gdk_window_set_background_rgba(guard_window, &rgba);

        gdk_window_show_unraised(guard_window);
    }
    return guard_window;
}


gboolean update_hide_state_delay()
{
    if (!dock_is_hovered()) {
        dbus_dock_daemon_update_hide_state();
    }
    update_hide_state_timer = 0;
    return G_SOURCE_REMOVE;
}


void cancel_update_state_request()
{
    if (update_hide_state_timer != 0) {
        g_source_remove(update_hide_state_timer);
        update_hide_state_timer = 0;
    }
}


void _update_hide_state(int delay G_GNUC_UNUSED)
{
    cancel_update_state_request();
    update_hide_state_timer = g_timeout_add(delay, update_hide_state_delay, NULL);
}


void update_hide_state()
{
    _update_hide_state(100);
}


PRIVATE GdkFilterReturn _monitor_guard_window(GdkXEvent* xevent,
        GdkEvent* event G_GNUC_UNUSED, gpointer data G_GNUC_UNUSED)
{
    XEvent* xev = xevent;
    XGenericEvent* e = xevent;


    if (xev->type == GenericEvent) {
        if (e->evtype == EnterNotify) {
            g_debug("enter guard window");
            _update_hide_state(500);
        } else if (e->evtype == LeaveNotify) {
            g_debug("leave guard window");
            update_hide_state();
        }
    }
    return GDK_FILTER_CONTINUE;
}

void update_dock_guard_window_position(double width)
{
    GdkWindow* win = get_dock_guard_window();
    if (width == 0)
        width = dock.width;
    GD.dock_panel_width = width;
    gdk_window_move_resize(win,
                           dock.x + (dock.width - width) / 2,
                           dock.y + dock.height - GUARD_WINDOW_HEIGHT,
                           width,
                           GUARD_WINDOW_HEIGHT);
}

JS_EXPORT_API
void dock_update_guard_window_width(double width)
{
    update_dock_guard_window_position(width);
}

void init_dock_guard_window()
{
    GdkWindow* win = get_dock_guard_window();
    gdk_window_add_filter(win, _monitor_guard_window, NULL);
    update_dock_guard_window_position(dock.width);
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

