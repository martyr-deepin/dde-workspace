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
#ifndef __TRAY_HIDE_H__
#define __TRAY_HIDE_H__

#include <glib.h>


enum State {
    StateShow,
    StateShowing,
    StateHidden,
    StateHidding,
};


enum State get_tray_state();
void tray_delay_show(int delay);
void tray_delay_hide(int delay);
void tray_show_now();
void tray_hide_now();
void tray_hide_real_now();
void tray_show_real_now();

void tray_toggle_show();
void tray_update_hide_mode();

void update_tray_guard_window_position(double width);

gboolean is_mouse_in_tray();
gboolean tray_is_always_shown();

#endif
