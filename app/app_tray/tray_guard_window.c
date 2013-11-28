/**
 * Copyright (c) 2011 ~ 2013 Deepin, Inc.
 *               2013 ~ 2013 Liqiang Lee
 *
 * Author:      Liqiang Lee <liliqiang@linuxdeepin.com>
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
#include "tray_guard_window.h"
#include "tray_hide.h"
#include "X_misc.h"


GdkWindow* get_tray_guard_window()
{
    static GdkWindow* guard_window = NULL;
    if (guard_window == NULL) {
        GdkWindowAttr attributes;
        attributes.width = 1;
        attributes.height = GUARD_WINDOW_HEIGHT;
        attributes.window_type = GDK_WINDOW_TEMP;
        attributes.wclass = GDK_INPUT_OUTPUT;
#ifdef NDEBUG
        attributes.wclass = GDK_INPUT_ONLY;
#endif
        attributes.event_mask = GDK_ENTER_NOTIFY_MASK;
        //attributes.event_mask = GDK_ALL_EVENTS_MASK;

        guard_window =  gdk_window_new(NULL, &attributes, 0);
        GdkRGBA rgba = { 0, 0, 0, 0.6 };
        set_wmspec_dock_hint(guard_window);
        gdk_window_set_background_rgba(guard_window, &rgba);

        gdk_window_show_unraised(guard_window);
    }
    return guard_window;
}


static GdkFilterReturn _monitor_tray_guard_window(GdkXEvent* xevent,
        GdkEvent* event, gpointer data)
{
    XEvent* xev = xevent;
    XGenericEvent* e = xevent;


    if (xev->type == GenericEvent) {
        if (e->evtype == EnterNotify) {
            g_debug("[%s] EnterNotify", __func__);
            if (gdk_window_get_width(TRAY_GDK_WINDOW()) > 16) {
                tray_delay_show(100);
            }
        } else if (e->evtype == LeaveNotify) {
            g_debug("[%s] LeaveNotify", __func__);
            tray_delay_hide(100);
        }
    }

    return GDK_FILTER_CONTINUE;
}


void init_tray_guard_window()
{
    static gboolean is_inited = FALSE;
    if (!is_inited) {
        GdkWindow* win = get_tray_guard_window();
        gdk_window_add_filter(win, _monitor_tray_guard_window, NULL);
        update_tray_guard_window_position(1);
        is_inited = TRUE;
    }
}


void update_tray_guard_window_position(double width)
{
    if (width == 0)
        width = 1;

    g_debug("[%s] new width of guard window: %lf", __func__, width);
    GdkWindow* win = get_tray_guard_window();
    gdk_window_move_resize(win,
                           (gdk_screen_width() - width) / 2,
                           0,
                           width,
                           GUARD_WINDOW_HEIGHT);
}

