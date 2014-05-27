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
#include "notification_area/na-tray-manager.h"
#include "X_misc.h"
#include "dwebview.h"
#include "dock_config.h"

#define TRAY_LEFT_LINE_PATH "/usr/share/deepin-system-tray/src/image/system/tray_left_line.png"
#define TRAY_RIGHT_LINE_PATH "/usr/share/deepin-system-tray/src/image/system/tray_right_line.png"

#define CLAMP_WIDTH(w) (((w) < 16) ? 16 : (w))
#define DEFAULT_HEIGHT 16
#define DEFAULT_INTERVAL 4
#define DOCK_HEIGHT 30
#define NA_BASE_Y (gdk_screen_height() - DOCK_HEIGHT + (DOCK_HEIGHT - DEFAULT_HEIGHT)/2)
static GHashTable* _icons = NULL;
static gint _na_width = 0;

#define FCITX_TRAY_ICON "fcitx"
static GdkWindow* _fcitx_tray = NULL;
static gint _fcitx_tray_width = 0;

#define DEEPIN_TRAY_ICON "DeepinTrayIcon"
static GdkWindow* _deepin_tray = NULL;
static gint _deepin_tray_width = 0;
static gboolean _TRY_ICON_INIT = FALSE;

PRIVATE void _update_deepin_try_position();
PRIVATE void _update_fcitx_try_position();
PRIVATE void _update_notify_area_width();
gboolean draw_tray_icons(GtkWidget* w, cairo_t *cr);

GdkWindow* get_icon_window(GdkWindow* wrapper)
{
    return g_object_get_data(G_OBJECT(wrapper), "wrapper_child") ? : wrapper;
}
GdkWindow* get_wrapper_window(GdkWindow* icon)
{
    return g_object_get_data(G_OBJECT(icon), "wrapper_parent") ? : icon;
}

GdkWindow* create_wrapper(GdkWindow* parent, Window tray_icon)
{
    gdk_flush();
    GdkWindow* icon = gdk_x11_window_foreign_new_for_display(gdk_display_get_default(), tray_icon);
    if (icon == NULL)
        return NULL;
    GdkVisual* visual = gdk_window_get_visual(icon);
    GdkWindow* wrapper = NULL;
    if (gdk_visual_get_depth(visual) == 24) {
        GdkWindowAttr attributes;
        attributes.width = DEFAULT_HEIGHT;
        attributes.height = DEFAULT_HEIGHT;
        attributes.window_type = GDK_WINDOW_CHILD;
        attributes.wclass = GDK_INPUT_OUTPUT;
        attributes.event_mask = GDK_ALL_EVENTS_MASK;
        attributes.visual = visual;
        wrapper = gdk_window_new(parent, &attributes, GDK_WA_VISUAL);
        //TODO: there should set color correspond by dock background color
        /*GdkColor color = {1, 0, 0, 1};*/
        /*gdk_window_set_background_rgba(wrapper, &color);*/

        XReparentWindow(gdk_x11_get_default_xdisplay(),
                tray_icon,
                GDK_WINDOW_XID(wrapper),
                0, 0);
        gdk_window_show(icon);
        g_object_set_data(G_OBJECT(wrapper), "wrapper_child", icon);
        g_object_set_data(G_OBJECT(icon), "wrapper_parent", wrapper);
    } else {
        wrapper = icon;
    }
    return wrapper;
}

void tray_icon_do_screen_size_change()
{
    if (_TRY_ICON_INIT) {
        _update_deepin_try_position();
        _update_fcitx_try_position();
        _update_notify_area_width();
    }
}

void safe_window_move_resize(GdkWindow* wrapper, int x, int y, int w, int h)
{
    XSelectInput(gdk_x11_get_default_xdisplay(), GDK_WINDOW_XID(wrapper), ExposureMask | VisibilityChangeMask | EnterWindowMask | LeaveWindowMask);
    gdk_window_move_resize(wrapper, x, y, w, h);
    GdkWindow* icon = g_object_get_data(G_OBJECT(wrapper), "wrapper_child");
    if (icon) {
        gdk_window_resize(icon, w, h);
    }
    gdk_window_set_events(wrapper, GDK_ENTER_NOTIFY_MASK | GDK_LEAVE_NOTIFY_MASK | GDK_VISIBILITY_NOTIFY_MASK);
}
void safe_window_move(GdkWindow* wrapper, int x, int y)
{
    XSelectInput(gdk_x11_get_default_xdisplay(), GDK_WINDOW_XID(wrapper), ExposureMask | VisibilityChangeMask | EnterWindowMask | LeaveWindowMask);
    gdk_window_move(wrapper, x, y);
    gdk_window_set_events(wrapper, GDK_ENTER_NOTIFY_MASK | GDK_LEAVE_NOTIFY_MASK | GDK_VISIBILITY_NOTIFY_MASK);
}

PRIVATE void accumulate_na_width(GdkWindow* wrapper, gpointer width)
{
    g_assert(wrapper != _deepin_tray && wrapper != _fcitx_tray);
    int icon_width = gdk_window_get_width(wrapper);
    _na_width += icon_width + 2 * DEFAULT_INTERVAL;
    gdk_window_flush(wrapper);
    gint _na_base_x = gdk_screen_width() - _na_width - DEFAULT_INTERVAL;
    if (icon_width != GPOINTER_TO_INT(width))
        safe_window_move_resize(wrapper, _na_base_x, NA_BASE_Y, GPOINTER_TO_INT(width), DEFAULT_HEIGHT);
    else {
        safe_window_move(wrapper, _na_base_x, NA_BASE_Y);
    }
}

void _update_notify_area_width()
{
    if (_fcitx_tray)
        _na_width = _deepin_tray_width + _fcitx_tray_width + DEFAULT_INTERVAL;
    else
        _na_width = _deepin_tray_width - DEFAULT_INTERVAL + _fcitx_tray_width;
    g_hash_table_foreach(_icons, (GHFunc)accumulate_na_width, NULL);
    JSObjectRef width = json_create();
    json_append_number(width, "width", _na_width + 2 * DEFAULT_INTERVAL);
    js_post_message("tray_icon_area_changed", width);
}
void _update_deepin_try_position()
{
    if (_deepin_tray) {
        safe_window_move_resize(_deepin_tray,
                gdk_screen_width() - _deepin_tray_width - DEFAULT_INTERVAL,
                NA_BASE_Y, _deepin_tray_width, DEFAULT_HEIGHT);
        _update_notify_area_width();
    }
    _update_fcitx_try_position();
}
void _update_fcitx_try_position()
{
    if (_fcitx_tray) {
        safe_window_move_resize(_fcitx_tray,
                gdk_screen_width() - _deepin_tray_width - _fcitx_tray_width - 2 * DEFAULT_INTERVAL,
                NA_BASE_Y,
                _fcitx_tray_width, DEFAULT_HEIGHT);
        _update_notify_area_width();
    }
}

PRIVATE GdkFilterReturn
monitor_icon_event(GdkXEvent* xevent, GdkEvent* event, GdkWindow* wrapper);
void destroy_wrapper(GdkWindow* wrapper)
{
    GdkWindow* icon = get_icon_window(wrapper);
    gdk_window_remove_filter(icon, (GdkFilterFunc)monitor_icon_event, wrapper);
    if (icon != wrapper) {
        gdk_window_destroy(wrapper); //this will decrements wrapper's reference count, don't repeat call g_object_unref
        g_object_unref(icon);
    } else {
        g_object_unref(icon);
    }
}

PRIVATE GdkFilterReturn
monitor_icon_event(GdkXEvent* xevent, GdkEvent* event G_GNUC_UNUSED, GdkWindow* wrapper)
{
    XEvent* xev = xevent;
    if (xev->type == DestroyNotify) {
        if (_deepin_tray == wrapper ) {
            destroy_wrapper(_deepin_tray);
            _deepin_tray = NULL;
            _deepin_tray_width = 0;
            _update_fcitx_try_position();
        } else if (_fcitx_tray == wrapper) {
            destroy_wrapper(_fcitx_tray);
            _fcitx_tray = NULL;
            _fcitx_tray_width = 0;
            _update_notify_area_width();
        } else {
            g_hash_table_remove(_icons, wrapper);
            destroy_wrapper(wrapper);
            _update_notify_area_width();
        }
        return GDK_FILTER_CONTINUE;
    } else if (xev->type == ConfigureNotify) {
        XConfigureEvent* xev = (XConfigureEvent*)xevent;
        int new_width = ((XConfigureEvent*)xev)->width;
        if (wrapper == _deepin_tray) {
            _deepin_tray_width = CLAMP_WIDTH(new_width);
            _update_deepin_try_position();
        } else if (wrapper == _fcitx_tray) {
            _fcitx_tray_width = CLAMP_WIDTH(new_width);
            _update_fcitx_try_position();
        } else if (wrapper != _deepin_tray && wrapper != _fcitx_tray) {
            int new_height = ((XConfigureEvent*)xev)->height;
            g_hash_table_insert(_icons, wrapper, GINT_TO_POINTER(CLAMP_WIDTH((new_width * 1.0 / new_height * DEFAULT_HEIGHT))));
            _update_notify_area_width();
        }
        return GDK_FILTER_REMOVE;
    } else if (xev->type == GenericEvent) {
        GdkWindow* parent = gdk_window_get_parent(wrapper);
        XGenericEvent* ge = xevent;
        if (ge->evtype == EnterNotify) {
            g_object_set_data(G_OBJECT(wrapper), "is_mouse_in", GINT_TO_POINTER(TRUE));
            gdk_window_invalidate_rect(parent, NULL, TRUE);
        } else if (ge->evtype == LeaveNotify) {
            g_object_set_data(G_OBJECT(wrapper), "is_mouse_in", GINT_TO_POINTER(FALSE));
            gdk_window_invalidate_rect(parent, NULL, TRUE);
        }
        return GDK_FILTER_REMOVE;
    }
    return GDK_FILTER_CONTINUE;
}

void tray_icon_added (NaTrayManager *manager G_GNUC_UNUSED, Window child, GtkWidget* container)
{
    GdkWindow* wrapper = create_wrapper(gtk_widget_get_window(container), child);
    if (wrapper == NULL)
        return;
    GdkWindow* icon = get_icon_window(wrapper);
    g_assert(icon != NULL);

    gdk_window_reparent(wrapper, gtk_widget_get_window(container), 0, gdk_screen_height() - DOCK_HEIGHT);
    //add this mask so, gdk can handle GDK_SELECTION_CLEAR event to destroy this gdkwindow.
    gdk_window_set_events(icon, GDK_ENTER_NOTIFY_MASK | GDK_LEAVE_NOTIFY_MASK | GDK_VISIBILITY_NOTIFY_MASK);
    gdk_window_add_filter(icon, (GdkFilterFunc)monitor_icon_event, wrapper);
    gdk_window_set_composited(wrapper, TRUE);

    gdk_window_show(wrapper);

    char *re_class = NULL;
    get_wmclass(icon, &re_class, NULL);
    if (g_strcmp0(re_class, DEEPIN_TRAY_ICON) == 0) {
        _deepin_tray = wrapper;
        _deepin_tray_width = CLAMP_WIDTH(gdk_window_get_width(icon));
        _update_deepin_try_position();
    } else if (g_strcmp0(re_class, FCITX_TRAY_ICON) == 0) {
        _fcitx_tray = wrapper;
        _fcitx_tray_width = CLAMP_WIDTH(gdk_window_get_width(icon));
        _update_fcitx_try_position();

    } else {
        int width = gdk_window_get_width(icon) * 1.0 / gdk_window_get_height(icon) * DEFAULT_HEIGHT;
        gdk_window_resize(icon, width, DEFAULT_HEIGHT);
        g_hash_table_insert(_icons, wrapper, GINT_TO_POINTER(CLAMP_WIDTH(width)));
    }
    g_free(re_class);
    _update_notify_area_width();
}


void tray_init(GtkWidget* container)
{
    _icons = g_hash_table_new(g_direct_hash, g_direct_equal);
    GdkScreen* screen = gdk_screen_get_default();
    NaTrayManager* tray_manager = NULL;
    tray_manager = na_tray_manager_new();
    //TODO: update _na_base_y
    na_tray_manager_manage_screen(tray_manager, screen);

    g_signal_connect(tray_manager, "tray_icon_added", G_CALLBACK(tray_icon_added), container);
    g_signal_connect_after(container, "draw", G_CALLBACK(draw_tray_icons), NULL);
    _TRY_ICON_INIT = TRUE;
}

PRIVATE void
draw_tray_icon(GdkWindow* wrapper, gpointer no_use G_GNUC_UNUSED, cairo_t* cr)
{
    static cairo_surface_t* left = NULL;
    static cairo_surface_t* right = NULL;
    if (left == NULL)
        left = cairo_image_surface_create_from_png(TRAY_LEFT_LINE_PATH);
    if (right == NULL)
        right = cairo_image_surface_create_from_png(TRAY_RIGHT_LINE_PATH);

    GdkWindow* icon = get_icon_window(wrapper);
    g_assert(GDK_IS_WINDOW(wrapper));
    if (!gdk_window_is_destroyed(icon)) {
        gboolean is_in = GPOINTER_TO_INT(g_object_get_data(G_OBJECT(wrapper), "is_mouse_in"));
        int x = 0;
        int y = 0;
        gdk_window_get_geometry(wrapper, &x, &y, NULL, NULL); //gdk_window_get_position will get error value when dock is hidden!
        cairo_save(cr);
        if (wrapper == _deepin_tray || !is_in) {
            gdk_cairo_set_source_window(cr, icon, x, y);
            cairo_paint(cr);
        } else {
            if (cairo_surface_status(left) == CAIRO_STATUS_SUCCESS) {
                cairo_set_source_surface(cr, left, x - 4, y - 3);
                cairo_paint(cr);
            }
            gdk_cairo_set_source_window(cr, icon, x, y);
            cairo_paint(cr);
            if (cairo_surface_status(right) == CAIRO_STATUS_SUCCESS) {
                cairo_set_source_surface(cr, right, x + gdk_window_get_width(wrapper) + 2, y - 3);
                cairo_paint(cr);
            }
        }
        cairo_restore(cr);
    }
}

gboolean draw_tray_icons(GtkWidget* w G_GNUC_UNUSED, cairo_t *cr)
{
    if (_icons != NULL) {
        g_hash_table_foreach(_icons, (GHFunc)draw_tray_icon, cr);
        if (_deepin_tray)
            draw_tray_icon(_deepin_tray, NULL, cr);
        if (_fcitx_tray)
            draw_tray_icon(_fcitx_tray, NULL, cr);
    }
    return TRUE;
}

