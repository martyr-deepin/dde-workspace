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

extern int _dock_height;
extern void _change_workarea_height(int height);
extern GdkWindow* DOCK_GDK_WINDOW();
extern gboolean mouse_pointer_leave();
extern gboolean dock_has_maximize_client();
extern double dock_get_active_window();

#define GUARD_WINDOW_HEIGHT 1

enum Event {
    TriggerShow,
    TriggerHide,
    ShowNow,
    HideNow,
};
static gboolean _IN_TOGGLE_SHOW = FALSE;
PRIVATE void handle_event(enum Event ev);
PRIVATE void _cancel_detect_hide_mode();

enum State {
    StateShow,
    StateShowing,
    StateHidden,
    StateHidding,
} CURRENT_STATE = StateShow;


int dock_panel_width = 0;

gboolean dock_is_hidden()
{
    if (CURRENT_STATE == StateHidding)
        return TRUE;
    else
        return FALSE;
}

PRIVATE void set_state(enum State new_state)
{
    /*char* StateStr[] = { "StateShow", "StateShowing", "StateHidden", "StateHidding"};*/
    /*printf("from %s to %s\n", StateStr[CURRENT_STATE], StateStr[new_state]);*/
    CURRENT_STATE = new_state;
}


PRIVATE void enter_show()
{
    g_assert(CURRENT_STATE != StateShow);

    set_state(StateShow);
    _change_workarea_height(_dock_height);
    gdk_window_move(DOCK_GDK_WINDOW(), dock.x, dock.y);
}
PRIVATE void enter_hide()
{
    g_assert(CURRENT_STATE != StateHidden);

    set_state(StateHidden);
    _change_workarea_height(0);
    gdk_window_move(DOCK_GDK_WINDOW(), dock.x, dock.y+_dock_height);
    js_post_message("dock_hidden", NULL);
}

#define SHOW_HIDE_ANIMATION_STEP 10
#define SHOW_HIDE_ANIMATION_INTERVAL 40
PRIVATE gboolean do_hide_animation(int data);
PRIVATE gboolean do_show_animation(int data);
static guint _animation_show_id = 0;
static guint _animation_hide_id = 0;

PRIVATE void _cancel_animation()
{
    if (_animation_show_id != 0) {
        g_source_remove(_animation_show_id);
        _animation_show_id = 0;
    }
}
PRIVATE void enter_hidding()
{
    set_state(StateHidding);
    _cancel_animation();
    do_hide_animation(_dock_height);
    js_post_message("dock_hidden", NULL);
}
PRIVATE void enter_showing()
{
    set_state(StateShowing);
    _cancel_animation();
    do_show_animation(0);
}

PRIVATE void handle_event(enum Event ev)
{
    switch (CURRENT_STATE) {
    case StateShow: {
        switch (ev) {
        case TriggerShow:
            break;
        case TriggerHide:
            enter_hidding(); break;
        case ShowNow:
            break;
        case HideNow:
            enter_hide(); break;
        default:
            g_assert_not_reached();
        }
        break;
    }
    case StateShowing: {
        switch (ev) {
        case TriggerShow:
            break;
        case TriggerHide:
            enter_hidding(); break;
        case ShowNow:
            enter_show(); break;
        case HideNow:
            enter_hide(); break;
        default:
            g_assert_not_reached();
        }
        break;
    }
    case StateHidden: {
        switch (ev) {
        case TriggerShow:
            enter_showing(); break;
        case TriggerHide:
            break;
        case ShowNow:
            enter_show(); break;
        case HideNow:
            break;
        default:
            g_assert_not_reached();
        }
        break;
    }
    case StateHidding: {
        switch (ev) {
        case TriggerShow:
            enter_showing(); break;
        case TriggerHide:
            break;
        case ShowNow:
            enter_show(); break;
        case HideNow:
            enter_hide(); break;
        default:
            g_assert_not_reached();
        }
        break;
    }
    };
}



PRIVATE gboolean do_show_animation(int current_height)
{
    if (CURRENT_STATE != StateShowing) return FALSE;

    if (current_height <= _dock_height) {
        gdk_window_move(DOCK_GDK_WINDOW(), dock.x, dock.y + _dock_height - current_height);
        _change_workarea_height(current_height);
        _animation_show_id = g_timeout_add(SHOW_HIDE_ANIMATION_INTERVAL, (GSourceFunc)do_show_animation,
                GINT_TO_POINTER(current_height + SHOW_HIDE_ANIMATION_STEP));
    } else {
        handle_event(ShowNow);
    }
    return FALSE;
}

PRIVATE gboolean do_hide_animation(int current_height)
{
    if (CURRENT_STATE != StateHidding) return FALSE;

    if (current_height >= 0) {
        gdk_window_move(DOCK_GDK_WINDOW(), dock.x, dock.y + _dock_height - current_height);
        _change_workarea_height(current_height);
        _animation_hide_id = g_timeout_add(SHOW_HIDE_ANIMATION_INTERVAL, (GSourceFunc)do_hide_animation,
                GINT_TO_POINTER(current_height - SHOW_HIDE_ANIMATION_STEP));
    } else {
        handle_event(HideNow);
    }
    return FALSE;
}


PRIVATE gboolean do_hide_dock()
{
    handle_event(TriggerHide);
    return FALSE;
}
PRIVATE gboolean do_show_dock()
{
    handle_event(TriggerShow);
    return FALSE;
}

static guint _delay_id = 0;
PRIVATE void _cancel_delay()
{
    if (_delay_id != 0) {
        g_source_remove(_delay_id);
        _delay_id = 0;
    }
}
void dock_delay_show(int delay_ms)
{
    _cancel_detect_hide_mode();
    if (CURRENT_STATE == StateHidding) {
        do_show_dock();
    } else {
        _cancel_delay();
        _delay_id = g_timeout_add(delay_ms, do_show_dock, NULL);
    }
}
void dock_delay_hide(int delay_ms)
{
    _cancel_detect_hide_mode();
    _cancel_delay();
    _delay_id = g_timeout_add(delay_ms, do_hide_dock, NULL);
}

void dock_show_now()
{
    _cancel_detect_hide_mode();
    handle_event(TriggerShow);
}
void dock_show_real_now()
{
    _cancel_detect_hide_mode();
    handle_event(ShowNow);
}
void dock_hide_now()
{
    _cancel_detect_hide_mode();
    handle_event(TriggerHide);
}
void dock_hide_real_now()
{
    _cancel_detect_hide_mode();
    handle_event(HideNow);
}

static guint _detect_hide_mode_id = 0;
PRIVATE void _cancel_detect_hide_mode()
{
    if (_detect_hide_mode_id != 0) {
        g_source_remove(_detect_hide_mode_id);
        _detect_hide_mode_id = 0;
    }
}

gboolean _do_toggle_show_clean()
{
    _IN_TOGGLE_SHOW = FALSE;
    dock_update_hide_mode();
    return FALSE;
}

DBUS_EXPORT_API
void dock_toggle_show()
{
    if (CURRENT_STATE == StateHidden || CURRENT_STATE == StateHidding) {
        handle_event(TriggerShow);
    } else if (CURRENT_STATE == StateShow || CURRENT_STATE == StateShowing) {
        handle_event(TriggerHide);
    }
    _IN_TOGGLE_SHOW = TRUE;
    _detect_hide_mode_id = g_timeout_add(3000, (GSourceFunc)_do_toggle_show_clean, NULL);
}


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
        attributes.wclass = GDK_INPUT_ONLY;
        attributes.event_mask = GDK_ENTER_NOTIFY_MASK;
        /*attributes.event_mask = GDK_ALL_EVENTS_MASK;*/

        guard_window =  gdk_window_new(NULL, &attributes, 0);
        GdkRGBA rgba = { 0, 0, 0, 0 };
        set_wmspec_dock_hint(guard_window);
        gdk_window_set_background_rgba(guard_window, &rgba);

        gdk_window_show_unraised(guard_window);
    }
    return guard_window;
}
PRIVATE GdkFilterReturn _monitor_guard_window(GdkXEvent* xevent,
        GdkEvent* event, gpointer data)
{
    NOUSED(event);
    NOUSED(data);
    XEvent* xev = xevent;
    XGenericEvent* e = xevent;


    if (xev->type == GenericEvent) {
        if (e->evtype == EnterNotify) {
            if (GD.config.hide_mode == AUTO_HIDE_MODE)
                dock_show_real_now();
            else if (GD.config.hide_mode != NO_HIDE_MODE)
                dock_delay_show(50);
        } else if (e->evtype == LeaveNotify) {
            if (GD.config.hide_mode == ALWAYS_HIDE_MODE)
                dock_delay_hide(50);
            else if (GD.config.hide_mode == AUTO_HIDE_MODE && dock_has_maximize_client() && !is_mouse_in_dock())
                dock_hide_real_now();
        }
    }
    return GDK_FILTER_CONTINUE;
}

void update_dock_guard_window_position(double width)
{
    GdkWindow* win = get_dock_guard_window();
    if (width == 0)
        width = dock.width;
    dock_panel_width = width;
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

JS_EXPORT_API
void dock_update_hide_mode()
{
    g_debug("%s", __func__);
    if (!GD.is_webview_loaded || _IN_TOGGLE_SHOW) return;
    _change_workarea_height(_dock_height);

    // extern Window launcher_id;
    // if (launcher_id != 0 && dock_get_active_window() == launcher_id) {
    //     dock_show_now();
    //     return;
    // }

    switch (GD.config.hide_mode) {
    case ALWAYS_HIDE_MODE: {
        g_debug("ALWAYS_HIDE_MODE");
        if (!is_mouse_in_dock()) {
            g_debug("mouse not in dock");
            dock_hide_now();
        }
        break;
    }
    case INTELLIGENT_HIDE_MODE: {
    //     if (!is_mouse_in_dock()) {
    //         g_debug("mouse not in dock");
    //         if (dock_has_overlay_client()) {
    //             dock_delay_hide(50);
    //         } else {
    //             dock_delay_show(50);
    //         }
    //     }
        break;
    }
    case AUTO_HIDE_MODE: {
        g_debug("AUTO_HIDE_MODE");
        if (!is_mouse_in_dock()) {
            g_debug("mouse not in dock");
            if (dock_has_maximize_client()) {
                dock_hide_real_now();
            } else {
                dock_show_real_now();
            }
        }
        break;
    }
    case NO_HIDE_MODE: {
        g_debug("NO_HIDE_MODE");
        dock_show_now();
        break;
    }
    }
}

