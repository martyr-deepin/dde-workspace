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

#include <gtk/gtk.h>
#include <gdk/gdkx.h>

#include "config.h"
#include "main.h"
#include "tray_hide.h"
#include "tray_guard_window.h"
#include "X_misc.h"


#define SHOW_HIDE_ANIMATION_STEP 6
#define SHOW_HIDE_ANIMATION_INTERVAL 40


enum Event {
    TriggerShow,
    TriggerHide,
    ShowNow,
    HideNow,
};


static enum State CURRENT_STATE = StateShow;
static gboolean _IN_TOGGLE_SHOW = FALSE;
static guint _animation_show_id = 0;
static guint _animation_hide_id = 0;
static void handle_event(enum Event ev);
static void _cancel_detect_hide_mode();
static void _cancel_delay();
static gboolean do_hide_animation(int data);
static gboolean do_show_animation(int data);


enum State get_tray_state()
{
    return CURRENT_STATE;
}


gboolean tray_is_hidden()
{
    if (CURRENT_STATE == StateHidding || CURRENT_STATE == StateHidden)
        return TRUE;
    else
        return FALSE;
}


static void set_state(enum State new_state)
{
    /*char* StateStr[] = { "StateShow", "StateShowing", "StateHidden", "StateHidding"};*/
    /*printf("from %s to %s\n", StateStr[CURRENT_STATE], StateStr[new_state]);*/
    CURRENT_STATE = new_state;
}


static int get_x()
{
    return (apptray.width - gdk_window_get_width(TRAY_GDK_WINDOW())) / 2;
}


static void enter_show()
{
    g_assert(CURRENT_STATE != StateShow);

    set_state(StateShow);
    gdk_window_move(TRAY_GDK_WINDOW(), get_x(), 0);
}


static void enter_hide()
{
    g_assert(CURRENT_STATE != StateHidden);

    set_state(StateHidden);
    gdk_window_move(TRAY_GDK_WINDOW(), get_x(), -TRAY_HEIGHT);
}


static void _cancel_animation()
{
    if (_animation_show_id != 0) {
        g_source_remove(_animation_show_id);
        _animation_show_id = 0;
    }
}


static void enter_hidding()
{
    set_state(StateHidding);
    _cancel_animation();
    do_hide_animation(0);
}


static void enter_showing()
{
    set_state(StateShowing);
    _cancel_animation();
    do_show_animation(-TRAY_HEIGHT);
}


static void handle_event(enum Event ev)
{
    _cancel_delay();
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


static gboolean do_show_animation(int current_height)
{
    if (CURRENT_STATE != StateShowing) return FALSE;

    if (current_height < 0) {
        gdk_window_move(TRAY_GDK_WINDOW(), get_x(), current_height);
        _animation_show_id = g_timeout_add(SHOW_HIDE_ANIMATION_INTERVAL, (GSourceFunc)do_show_animation,
                GINT_TO_POINTER(current_height + SHOW_HIDE_ANIMATION_STEP));
    } else {
        handle_event(ShowNow);
    }
    return FALSE;
}


static gboolean do_hide_animation(int current_height)
{
    if (CURRENT_STATE != StateHidding) return FALSE;

    if (current_height >= -TRAY_HEIGHT) {
        gdk_window_move(TRAY_GDK_WINDOW(), get_x(), current_height);
        _animation_hide_id = g_timeout_add(SHOW_HIDE_ANIMATION_INTERVAL, (GSourceFunc)do_hide_animation,
                GINT_TO_POINTER(current_height - SHOW_HIDE_ANIMATION_STEP));
    } else {
        handle_event(HideNow);
    }
    return FALSE;
}


static gboolean do_hide_tray()
{
    handle_event(TriggerHide);
    return FALSE;
}


static gboolean do_show_tray()
{
    handle_event(TriggerShow);
    return FALSE;
}


static guint _delay_id = 0;
static void _cancel_delay()
{
    if (_delay_id != 0) {
        g_source_remove(_delay_id);
        _delay_id = 0;
    }
}


void tray_delay_show(int delay_ms)
{
    _cancel_detect_hide_mode();
    if (CURRENT_STATE == StateHidding) {
        do_show_tray();
    } else {
        _cancel_delay();
        _delay_id = g_timeout_add(delay_ms, do_show_tray, NULL);
    }
}


void tray_delay_hide(int delay_ms)
{
    _cancel_detect_hide_mode();
    _cancel_delay();
    _delay_id = g_timeout_add(delay_ms, do_hide_tray, NULL);
}


void tray_show_now()
{
    _cancel_detect_hide_mode();
    handle_event(TriggerShow);
}


DBUS_EXPORT_API
void tray_show_real_now()
{
    _cancel_detect_hide_mode();
    handle_event(ShowNow);
}


void tray_hide_now()
{
    _cancel_detect_hide_mode();
    handle_event(TriggerHide);
}


DBUS_EXPORT_API
void tray_hide_real_now()
{
    _cancel_detect_hide_mode();
    handle_event(HideNow);
}


static guint _detect_hide_mode_id = 0;
static void _cancel_detect_hide_mode()
{
    if (_detect_hide_mode_id != 0) {
        g_warning("[%s] cancel detect hide mode", __func__);
        g_source_remove(_detect_hide_mode_id);
        _detect_hide_mode_id = 0;
    }
}


gboolean _do_toggle_show_clean()
{
    _IN_TOGGLE_SHOW = FALSE;
    tray_update_hide_mode();
    return FALSE;
}


void tray_toggle_show()
{
    if (CURRENT_STATE == StateHidden || CURRENT_STATE == StateHidding) {
        handle_event(TriggerShow);
    } else if (CURRENT_STATE == StateShow || CURRENT_STATE == StateShowing) {
        handle_event(TriggerHide);
    }
    _IN_TOGGLE_SHOW = TRUE;
    _detect_hide_mode_id = g_timeout_add(3000, (GSourceFunc)_do_toggle_show_clean, NULL);
}


gboolean mouse_pointer_leave(int x, int y)
{
    gboolean is_contain = FALSE;
    static Display* dpy = NULL;
    static Window tray_window = 0;
    if (dpy == NULL) {
        dpy = GDK_DISPLAY_XDISPLAY(gdk_display_get_default());
        tray_window = GDK_WINDOW_XID(TRAY_GDK_WINDOW());
    }
    cairo_region_t* region = get_window_input_region(dpy, tray_window);
    is_contain = cairo_region_contains_point(region, x, y);
    cairo_region_destroy(region);
    return is_contain;
}


void get_mouse_position(int* x, int* y)
{
    GdkDeviceManager *device_manager;
    GdkDevice *pointer;

    device_manager = gdk_display_get_device_manager(gdk_display_get_default());
    pointer = gdk_device_manager_get_client_pointer(device_manager);
    gdk_device_get_position(pointer, NULL, x, y);
}


gboolean is_mouse_in_tray()
{
    int x = 0, y = 0;
    get_mouse_position(&x, &y);
    return mouse_pointer_leave(x, y);
}


void tray_update_hide_mode()
{
    if (_IN_TOGGLE_SHOW) return;

    if (!is_mouse_in_tray()) {
        g_debug("mouse not in tray");
        tray_hide_now();
    }
}

