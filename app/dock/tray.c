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

#define DEFAULT_WIDTH 16
#define DEFAULT_INTERVAL 24
static GHashTable* _icons = NULL;

static JSObjectRef tray_icon_to_json(GdkWindow* icon);

static GdkFilterReturn
monitor_remove(GdkXEvent* xevent, GdkEvent* event, gpointer data)
{
    XEvent* xev = xevent;
    if (xev->type == DestroyNotify) {
        g_hash_table_remove(_icons, (GdkWindow*)data);
        JSObjectRef json = json_create();
        json_append_number(json, "id", GPOINTER_TO_INT(data));
        js_post_message("tray_icon_removed", json);
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

    gint x = g_hash_table_size(_icons) * DEFAULT_INTERVAL;
    gint y = 0;

    gint xy = y + (x  << 16);
    g_hash_table_insert(_icons, icon, GINT_TO_POINTER(xy)); 

    gdk_window_reparent(icon, gtk_widget_get_window(container), x, y);
    gdk_window_set_events(icon, GDK_VISIBILITY_NOTIFY_MASK); //add this mask so, gdk can handle GDK_SELECTION_CLEAR event to destroy this gdkwindow.
    gdk_window_add_filter(icon, monitor_remove, icon);
    gdk_window_set_composited(icon, TRUE);
    gdk_window_move_resize(icon, -100, -100, DEFAULT_WIDTH, DEFAULT_WIDTH);
    js_post_message("tray_icon_added", tray_icon_to_json(icon));
}

void tray_init(GtkWidget* container)
{
    GdkScreen* screen = gdk_screen_get_default();
    NaTrayManager* tray_manager = NULL;
    tray_manager = na_tray_manager_new();
    na_tray_manager_manage_screen(tray_manager, screen);

    _icons = g_hash_table_new(g_direct_hash, g_direct_equal);

    g_signal_connect(tray_manager, "tray_icon_added", G_CALLBACK(tray_icon_added), container);
}


JS_EXPORT_API
void dock_set_tray_icon_position(double _icon, double _x, double _y)
{
    GdkWindow* icon = (GdkWindow*)GINT_TO_POINTER((gint)_icon);
    if (g_hash_table_contains(_icons, icon)) {
        int x = (int) _x;
        int y = (int) _y;
        int xy = y + (x  << 16);
        g_hash_table_insert(_icons, icon, GINT_TO_POINTER(xy));
        gdk_window_move(icon, x, y);
        gdk_window_show(icon);

        GdkWindow* container = gdk_window_get_parent(icon);
        GdkRectangle rect;
        gdk_window_get_geometry(container, &(rect.x), &(rect.y), &(rect.width), &(rect.height));
        gdk_window_invalidate_rect(container, &rect, TRUE);
    } else {
        g_warning("Don't use invalid tray_icon ID\n");
    }
}


static JSObjectRef
tray_icon_to_json(GdkWindow* icon)
{
    char* res_class = NULL;
    char* res_name = NULL;
    get_wmclass(icon, &res_class, &res_name);

    JSObjectRef json = json_create();

    json_append_number(json, "id", GPOINTER_TO_INT(icon));
    json_append_string(json, "clss", res_class);
    json_append_string(json, "name", res_name);
    js_post_message("tray_icon_added", json);

    g_free(res_class);
    g_free(res_name);
    return json;
}

JS_EXPORT_API
JSObjectRef dock_get_tray_icon_list()
{
    JSObjectRef array = json_array_create();
    GHashTableIter iter;
    gpointer key;
    g_hash_table_iter_init(&iter, _icons);
    int index = 0;
    while (g_hash_table_iter_next(&iter, &key, NULL)) {
        json_array_append(array, index++, tray_icon_to_json((GdkWindow*)key));
    }
    return array;
}


static void 
draw_tray_icon(GdkWindow* icon, gint xy, cairo_t* cr)
{
    if (gdk_window_is_destroyed(icon)) {
        g_assert_not_reached();
    } else {
        gint x = xy >> 16;
        gint y = xy & 0xffff;
        gdk_cairo_set_source_window(cr, icon, x, y);
        cairo_paint(cr);
    }
}

gboolean draw_tray_icons(GtkWidget* w, cairo_t *cr, gpointer data)
{
    /*cairo_set_source_rgba(cr, 0, 0.8, 0, 0.2);*/
    /*cairo_paint(cr);*/
    g_hash_table_foreach(_icons, (GHFunc)draw_tray_icon, cr);
    return TRUE;
}
