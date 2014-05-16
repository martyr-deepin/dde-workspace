/**
 * Copyright (c) 2011 ~ 2013 Deepin, Inc.
 *               2011 ~ 2012 Liqiang Lee
 *               2013 ~ 2013 Liqiang Lee
 *
 * Author:      Liqiang Lee <liliqiang@linuxdeepin.com>
 * Maintainer:  Liqiang Lee <liliqiang@linuxdeepin.com>
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

#include <gtk/gtk.h>
#include "jsextension.h"
#include "special_window.h"
#include "../launcher/DBUS_launcher.h"
#include "utils.h"

extern Window active_client_id;
extern Window get_dock_window();

Window launcher_id = 0;

gboolean launcher_should_exit()
{
    gboolean is_launcher_sub_window = FALSE;
    Display* _dsp = GDK_DISPLAY_XDISPLAY(gdk_display_get_default());
    XClassHint ch = {NULL, NULL};
    if (XGetClassHint(_dsp, active_client_id, &ch)) {
        if (g_strcmp0(ch.res_name, "launcher") == 0) {
            is_launcher_sub_window = TRUE;
        }
        XFree(ch.res_name);
        XFree(ch.res_class);
    }
    return launcher_id != 0
        && active_client_id != get_dock_window()
        && active_client_id != launcher_id
        && !is_launcher_sub_window;
}

void close_launcher_window()
{
    dbus_launcher_hide();
    js_post_signal("launcher_destroy");
}

PRIVATE
GdkFilterReturn _monitor_launcher_window(GdkXEvent* xevent, GdkEvent* event G_GNUC_UNUSED, Window win G_GNUC_UNUSED)
{
    XEvent* xev = xevent;
    if (xev->type == DestroyNotify) {
        js_post_signal("launcher_destroy");
        launcher_id = 0;
    }
    return GDK_FILTER_CONTINUE;
}

void start_monitor_launcher_window(Display* dsp, Window w)
{
    launcher_id = w;
    GdkWindow* win = gdk_x11_window_foreign_new_for_display(gdk_x11_lookup_xdisplay(dsp), w);
    if (win == NULL)
        return;
    js_post_signal("launcher_running");

    g_assert(win != NULL);
    gdk_window_set_events(win, GDK_VISIBILITY_NOTIFY_MASK | gdk_window_get_events(win));
    gdk_window_add_filter(win, (GdkFilterFunc)_monitor_launcher_window, GINT_TO_POINTER(w));
}

