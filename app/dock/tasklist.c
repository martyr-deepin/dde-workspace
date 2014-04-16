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
#include "X_misc.h"
#include "pixbuf.h"
#include "utils.h"
#include "xid2aid.h"
#include "dock_config.h"
#include "dominant_color.h"
#include "handle_icon.h"
#include "dock_hide.h"
#include "region.h"
#include "xdg_misc.h"
#include "DBUS_dock.h"

#include <gtk/gtk.h>
#include <gdk/gdkx.h>
#include <X11/Xatom.h>
#include <string.h>

PRIVATE Display* _dsp = NULL;
PRIVATE Atom ATOM_DEEPIN_SCREEN_VIEWPORT;


PRIVATE
void _init_atoms()
{
    ATOM_DEEPIN_SCREEN_VIEWPORT = gdk_x11_get_xatom_by_name("DEEPIN_SCREEN_VIEWPORT");
}

typedef struct _Workspace Workspace;
struct _Workspace {
    int x, y;
};

static Workspace current_workspace = {0, 0};

PRIVATE
void _update_current_viewport(Workspace* vp)
{
    gulong n_item;
    gpointer data = get_window_property(_dsp, GDK_ROOT_WINDOW(), ATOM_DEEPIN_SCREEN_VIEWPORT, &n_item);
    if (data == NULL)
        return;
    vp->x = X_FETCH_32(data, 0);
    vp->y = X_FETCH_32(data, 1);
    XFree(data);

    dock_update_hide_mode();
}


GdkFilterReturn monitor_root_change(GdkXEvent* xevent,
                                    GdkEvent *event G_GNUC_UNUSED,
                                    gpointer _nouse G_GNUC_UNUSED)
{
    switch (((XEvent*)xevent)->type) {
    case PropertyNotify: {
        XPropertyEvent* ev = xevent;
        if (ev->atom == ATOM_DEEPIN_SCREEN_VIEWPORT) {
            _update_current_viewport(&current_workspace);
        }
    }
    }

    //NOTO: what's time should be we call this?
    //dock_update_hide_mode();
    return GDK_FILTER_CONTINUE;
}


void init_task_list()
{
    _dsp = GDK_DISPLAY_XDISPLAY(gdk_display_get_default());
    _init_atoms();

    GdkWindow* root = gdk_get_default_root_window();
    gdk_window_set_events(root, GDK_PROPERTY_CHANGE_MASK | gdk_window_get_events(root));

    gdk_window_add_filter(root, monitor_root_change, NULL);
}

