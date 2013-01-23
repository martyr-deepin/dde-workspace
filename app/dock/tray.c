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

#define DEFAULT_HEIGHT 16
#define DEFAULT_INTERVAL 4
static GHashTable* _icons = NULL;
static gint _na_width = 0;
static gint _s_width = 0;
static gint _s_height = 0;
static GdkWindow* _deepin_tray = NULL;
static gint _deepin_tray_width = 0;
#define DEEPIN_TRAY_ICON "DeepinTrayIcon"

static void accumulate_na_width(GdkWindow* icon, gpointer width)
{
    g_assert(icon != _deepin_tray);
    _na_width += gdk_window_get_width(icon) + DEFAULT_INTERVAL;
    gdk_window_flush(icon);
    gint _na_base_x = _s_width - _na_width - DEFAULT_INTERVAL;
    gdk_window_move_resize(icon, _na_base_x, _s_height - 23, GPOINTER_TO_INT(width), DEFAULT_HEIGHT);
}

static void update_notify_area_width()
{
    _na_width = _deepin_tray_width;
    g_hash_table_foreach(_icons, (GHFunc)accumulate_na_width, NULL);
    js_post_message_simply("tray_icon_area_changed", "{\"width\":%d}", _na_width + 2 *DEFAULT_INTERVAL);
}


static GdkFilterReturn
monitor_remove(GdkXEvent* xevent, GdkEvent* event, gpointer data)
{
    XEvent* xev = xevent;
    if (xev->type == DestroyNotify) {
        g_hash_table_remove(_icons, data);
        if (_deepin_tray == data) {
            _deepin_tray == NULL;
            _deepin_tray_width = 0;
        }
        update_notify_area_width();
    } else if (xev->type == ConfigureNotify) {
        int width = GPOINTER_TO_INT(g_hash_table_lookup(_icons, data));
        int new_width = ((XConfigureEvent*)xev)->width;
        if (width != new_width) {
            if (data == _deepin_tray) {
                if (_deepin_tray_width != new_width) {
                    gdk_window_move_resize(_deepin_tray, _s_width - new_width - DEFAULT_INTERVAL, _s_height - 23, new_width, DEFAULT_HEIGHT);
                    _deepin_tray_width = new_width;
                    update_notify_area_width();
                }
            } else {
                g_hash_table_insert(_icons, data, GINT_TO_POINTER(gdk_window_get_width(data)));
                update_notify_area_width();
            }
        }
    }
    return GDK_FILTER_CONTINUE;
}

void tray_icon_added (NaTrayManager *manager, Window child, GtkWidget* container)
{
    GdkWindow* icon = gdk_x11_window_foreign_new_for_display(gdk_display_get_default(), child);
    if (icon == NULL) {
        g_debug("icon id:%d = 0 (invalide)\n", (int)child);
        return;
    }

    gdk_window_reparent(icon, gtk_widget_get_window(container), 0, 870);
    gdk_window_set_events(icon, GDK_VISIBILITY_NOTIFY_MASK); //add this mask so, gdk can handle GDK_SELECTION_CLEAR event to destroy this gdkwindow.
    gdk_window_add_filter(icon, monitor_remove, icon);
    gdk_window_set_composited(icon, TRUE);

    int width = gdk_window_get_width(icon) * 1.0 / gdk_window_get_height(icon) * DEFAULT_HEIGHT;
    gint _na_base_x = _s_width - _na_width - 20;
    gdk_window_resize(icon, width, DEFAULT_HEIGHT);
    gdk_window_show(icon);

    char *re_class = NULL;
    get_wmclass(icon, &re_class, NULL);
    if (g_strcmp0(re_class, DEEPIN_TRAY_ICON) == 0) {
        if (_deepin_tray == NULL) {
            _deepin_tray = icon;
            _deepin_tray_width = gdk_window_get_width(icon);
        }
    } else {
        g_hash_table_insert(_icons, icon, GINT_TO_POINTER(width));
    }
    g_free(re_class);
    update_notify_area_width();

}


void tray_init(GtkWidget* container)
{
    _icons = g_hash_table_new(g_direct_hash, g_direct_equal);
    GdkScreen* screen = gdk_screen_get_default();
    NaTrayManager* tray_manager = NULL;
    tray_manager = na_tray_manager_new();
    _s_width = gdk_screen_get_width(screen);
    _s_height = gdk_screen_get_height(screen);
    //TODO: update _na_base_y
    na_tray_manager_manage_screen(tray_manager, screen);

    g_signal_connect(tray_manager, "tray_icon_added", G_CALLBACK(tray_icon_added), container);
}

static void 
draw_tray_icon(GdkWindow* icon, gpointer no_use, cairo_t* cr)
{
    g_assert(GDK_IS_WINDOW(icon));
    if (!gdk_window_is_destroyed(icon)) {
        int x = 0;
        int y = 0;
        gdk_window_get_position(icon, &x, &y);
        cairo_save(cr);
        gdk_cairo_set_source_window(cr, icon, x, y);
        cairo_paint(cr);
        cairo_restore(cr);
    }
}

gboolean draw_tray_icons(GtkWidget* w, cairo_t *cr)
{
    if (_icons != NULL) {
        g_hash_table_foreach(_icons, (GHFunc)draw_tray_icon, cr);
        if (_deepin_tray)
            draw_tray_icon(_deepin_tray, NULL, cr);
    }
    return TRUE;
}
