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
#include "notification_area/na-tray-manager.h"
#include "X_misc.h"
#include "dwebview.h"
#include "dock_config.h"

extern int screen_width;
extern int screen_height;


#define TRAY_LEFT_LINE_PATH "/usr/share/deepin-system-tray/src/image/system/tray_left_line.png"
#define TRAY_RIGHT_LINE_PATH "/usr/share/deepin-system-tray/src/image/system/tray_right_line.png"

#define DEFAULT_HEIGHT 16
#define DEFAULT_INTERVAL 4
#define DOCK_HEIGHT 30
#define NA_BASE_Y (screen_height - DOCK_HEIGHT + (DOCK_HEIGHT - DEFAULT_HEIGHT)/2)
static GHashTable* _icons = NULL;
static gint _na_width = 0;

#define FCITX_TRAY_ICON "fcitx"
static GdkWindow* _fcitx_tray = NULL;
static gint _fcitx_tray_width = 0;

#define DEEPIN_TRAY_ICON "DeepinTrayIcon"
static GdkWindow* _deepin_tray = NULL;
static gint _deepin_tray_width = 0;
static gboolean _TRY_ICON_INIT = FALSE;

static void _update_deepin_try_position();
static void _update_fcitx_try_position();
static void _update_notify_area_width();

void tray_icon_do_screen_size_change()
{
    if (_TRY_ICON_INIT) {
        _update_deepin_try_position();
        _update_fcitx_try_position();
        _update_notify_area_width();
    }
}

static void accumulate_na_width(GdkWindow* icon, gpointer width)
{
    g_assert(icon != _deepin_tray && icon != _fcitx_tray);
    int icon_width = gdk_window_get_width(icon);
    _na_width += icon_width + 2 * DEFAULT_INTERVAL;
    gdk_window_flush(icon);
    gint _na_base_x = screen_width - _na_width - DEFAULT_INTERVAL;
    if (icon_width != GPOINTER_TO_INT(width))
        gdk_window_move_resize(icon, _na_base_x, NA_BASE_Y, GPOINTER_TO_INT(width), DEFAULT_HEIGHT);
    else
        gdk_window_move(icon, _na_base_x, NA_BASE_Y);
}

void _update_notify_area_width()
{
    if (_fcitx_tray)
        _na_width = _deepin_tray_width + _fcitx_tray_width + DEFAULT_INTERVAL;
    else
        _na_width = _deepin_tray_width - DEFAULT_INTERVAL + _fcitx_tray_width;
    g_hash_table_foreach(_icons, (GHFunc)accumulate_na_width, NULL);
    js_post_message_simply("tray_icon_area_changed", "{\"width\":%d}", _na_width + 2 *DEFAULT_INTERVAL);
}
void _update_deepin_try_position()
{
    if (_deepin_tray) {
        gdk_window_move_resize(_deepin_tray,
                screen_width - _deepin_tray_width - DEFAULT_INTERVAL,
                NA_BASE_Y, _deepin_tray_width, DEFAULT_HEIGHT);
        _update_notify_area_width();
    }
}
void _update_fcitx_try_position()
{
    if (_fcitx_tray) {
        gdk_window_move_resize(_fcitx_tray,
                screen_width - _deepin_tray_width - _fcitx_tray_width - 2 * DEFAULT_INTERVAL,
                NA_BASE_Y,
                _fcitx_tray_width, DEFAULT_HEIGHT);
        _update_notify_area_width();
    }
}

static GdkFilterReturn
monitor_icon_event(GdkXEvent* xevent, GdkEvent* event, gpointer data)
{
    XEvent* xev = xevent;
    if (xev->type == DestroyNotify) {
        if (_deepin_tray == data) {
            _deepin_tray = NULL;
            _deepin_tray_width = 0;
            _update_fcitx_try_position();
        } else if (_fcitx_tray == data) {
            _fcitx_tray = NULL;
            _fcitx_tray_width = 0;
            _update_notify_area_width();
        } else {
            g_hash_table_remove(_icons, data);
            _update_notify_area_width();
        }
    } else if (xev->type == ConfigureNotify) {
        int width = GPOINTER_TO_INT(g_hash_table_lookup(_icons, data));
        int new_width = ((XConfigureEvent*)xev)->width;
        int new_height = ((XConfigureEvent*)xev)->height;
        if (width != new_width) {
            if (data == _deepin_tray) {
                if (_deepin_tray_width != new_width) {
                    _deepin_tray_width = new_width;
                    _update_deepin_try_position();
                    _update_fcitx_try_position();
                }
            } else if (data == _fcitx_tray) {
                if (_fcitx_tray_width != new_width) {
                    _fcitx_tray_width = new_width;
                    _update_fcitx_try_position();
                }
            } else {
                g_hash_table_insert(_icons, data, GINT_TO_POINTER((int)(new_width * 1.0 / new_height * DEFAULT_HEIGHT)));
                _update_notify_area_width();
            }
        }
    } else if (xev->type == GenericEvent) {
        XGenericEvent* ge = xevent;
        if (ge->evtype == EnterNotify) {
            GdkWindow* win = ((GdkEventAny*)event)->window;
            GdkWindow* par = gdk_window_get_parent(win);
            g_object_set_data(G_OBJECT(win), "is_mouse_in", GINT_TO_POINTER(TRUE));
            gdk_window_invalidate_rect(par, NULL, TRUE);
        } else if (ge->evtype == LeaveNotify) {
            GdkWindow* win = ((GdkEventAny*)event)->window;
            GdkWindow* par = gdk_window_get_parent(win);
            g_object_set_data(G_OBJECT(win), "is_mouse_in", GINT_TO_POINTER(FALSE));
            gdk_window_invalidate_rect(par, NULL, TRUE);
        }
        return GDK_FILTER_TRANSLATE;
    }
    return GDK_FILTER_CONTINUE;
}

void tray_icon_added (NaTrayManager *manager, Window child, GtkWidget* container)
{
    Display* dsp = GDK_DISPLAY_XDISPLAY(gdk_display_get_default());
    XSetWindowBackgroundPixmap(dsp, child, None);

    GdkWindow* icon = gdk_x11_window_foreign_new_for_display(gdk_display_get_default(), child);
    if (icon == NULL) {
        g_debug("icon id:%d = 0 (invalide)\n", (int)child);
        return;
    }

    gdk_window_reparent(icon, gtk_widget_get_window(container), 0, screen_height - DOCK_HEIGHT);
    //add this mask so, gdk can handle GDK_SELECTION_CLEAR event to destroy this gdkwindow.
    gdk_window_set_events(icon, GDK_ENTER_NOTIFY_MASK | GDK_LEAVE_NOTIFY_MASK | GDK_VISIBILITY_NOTIFY_MASK); 
    gdk_window_add_filter(icon, monitor_icon_event, icon);
    gdk_window_set_composited(icon, TRUE);

    int width = gdk_window_get_width(icon) * 1.0 / gdk_window_get_height(icon) * DEFAULT_HEIGHT;
    gdk_window_resize(icon, width, DEFAULT_HEIGHT);
    gdk_window_show(icon);

    char *re_class = NULL;
    get_wmclass(icon, &re_class, NULL);
    if (g_strcmp0(re_class, DEEPIN_TRAY_ICON) == 0) {
        _deepin_tray = icon;
        _deepin_tray_width = gdk_window_get_width(icon);
        _update_deepin_try_position();
    } else if (g_strcmp0(re_class, FCITX_TRAY_ICON) == 0) {
        _fcitx_tray = icon;
        _fcitx_tray_width = gdk_window_get_width(icon);
        _update_fcitx_try_position();

    } else {
        g_hash_table_insert(_icons, icon, GINT_TO_POINTER(width));
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
    _TRY_ICON_INIT = TRUE;
}

static void
draw_tray_icon(GdkWindow* icon, gpointer no_use, cairo_t* cr)
{
    static cairo_surface_t* left = NULL;
    static cairo_surface_t* right = NULL;
    if (left == NULL)
        left = cairo_image_surface_create_from_png(TRAY_LEFT_LINE_PATH);
    if (right == NULL)
        right = cairo_image_surface_create_from_png(TRAY_RIGHT_LINE_PATH);

    g_assert(GDK_IS_WINDOW(icon));
    if (!gdk_window_is_destroyed(icon)) {
        gboolean is_in = GPOINTER_TO_INT(g_object_get_data(G_OBJECT(icon), "is_mouse_in"));
        int x = 0;
        int y = 0;
        gdk_window_get_position(icon, &x, &y);
        cairo_save(cr);
        if (icon == _deepin_tray || !is_in) {
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
                cairo_set_source_surface(cr, right, x + gdk_window_get_width(icon) + 2, y - 3);
                cairo_paint(cr);
            }
        }
        cairo_restore(cr);
    }
}

gboolean draw_tray_icons(GtkWidget* w, cairo_t *cr)
{
    cairo_set_source_rgba(cr, 1, 0, 0, 0.3);
    /*cairo_paint(cr);*/
    if (_icons != NULL) {
        g_hash_table_foreach(_icons, (GHFunc)draw_tray_icon, cr);
        if (_deepin_tray)
            draw_tray_icon(_deepin_tray, NULL, cr);
        if (_fcitx_tray)
            draw_tray_icon(_fcitx_tray, NULL, cr);
    }
    return TRUE;
}
