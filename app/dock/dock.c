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
#include <cairo.h>
#include <dwebview.h>
#include "dock.h"
#include "X_misc.h"
#include "xdg_misc.h"
#include "utils.h"
#include "tray.h"
#include "tasklist.h"
#include "i18n.h"
#include "dock_config.h"
#include "launcher.h"
#include "region.h"
#include "dock_hide.h"
#include "DBUS_dock.h"

#define DOCK_CONFIG "dock/config.ini"

static GtkWidget* container = NULL;
static GtkWidget* webview = NULL;

int _dock_height = 60;
GdkWindow* DOCK_GDK_WINDOW() { return gtk_widget_get_window(container); }

JS_EXPORT_API void dock_change_workarea_height(double height);

GdkWindow* get_dock_guard_window();

gboolean mouse_pointer_leave(int x, int y)
{
    gboolean is_contain = FALSE;
    static Display* dpy = NULL;
    static Window dock_window = 0;
    if (dpy == NULL) {
        dpy = GDK_DISPLAY_XDISPLAY(gdk_display_get_default());
        dock_window = GDK_WINDOW_XID(DOCK_GDK_WINDOW());
    }
    cairo_region_t* region = get_window_input_region(dpy, dock_window);
    is_contain = cairo_region_contains_point(region, x, y);
    cairo_region_destroy(region);
    return is_contain;
}

gboolean get_leave_enter_guard()
{
    static int _leave_enter_guard_id = -1;
    if (_leave_enter_guard_id == -1) {
        _leave_enter_guard_id = g_timeout_add(10, (GSourceFunc)get_leave_enter_guard, NULL);
        return TRUE;
    } else {
        g_source_remove(_leave_enter_guard_id);
        _leave_enter_guard_id = -1;
        return FALSE;
    }
}

gboolean leave_notify(GtkWidget* w G_GNUC_UNUSED, GdkEventCrossing* e, gpointer u G_GNUC_UNUSED)
{
    if (!get_leave_enter_guard())
        return FALSE;

    extern Window launcher_id;
    if (launcher_id != 0 && dock_get_active_window() == launcher_id) {
        dock_show_now();
        return FALSE;
    }

    if (e->detail == GDK_NOTIFY_NONLINEAR_VIRTUAL && !mouse_pointer_leave(e->x, e->y)) {
        if (GD.config.hide_mode == ALWAYS_HIDE_MODE && !is_mouse_in_dock()) {
            g_debug("always hide");
            dock_delay_hide(500);
        } else if (GD.config.hide_mode == INTELLIGENT_HIDE_MODE) {
            g_debug("intelligent leave_notify");
            dock_update_hide_mode();
        } else if (GD.config.hide_mode == AUTO_HIDE_MODE && dock_has_maximize_client() && !is_mouse_in_dock()) {
            g_debug("auto leave_notify");
            dock_hide_real_now();
        }
        js_post_signal("leave-notify");
    }
    return FALSE;
}
gboolean enter_notify(GtkWidget* w G_GNUC_UNUSED, GdkEventCrossing* e G_GNUC_UNUSED, gpointer u G_GNUC_UNUSED)
{
    if (!get_leave_enter_guard())
        return FALSE;

    if (GD.config.hide_mode == AUTO_HIDE_MODE) {
        dock_show_real_now();
    } else if (GD.config.hide_mode != NO_HIDE_MODE) {
        dock_delay_show(300);
    }
    return FALSE;
}

Window get_dock_window()
{
    g_assert(container != NULL);
    return GDK_WINDOW_XID(DOCK_GDK_WINDOW());
}

void size_workaround(GtkWidget* container, GdkRectangle* allocation)
{
    if (gtk_widget_get_realized(container) && (gdk_screen_width() != allocation->width || gdk_screen_height() != allocation->height)) {
        GdkWindow* w = DOCK_GDK_WINDOW();
        XSelectInput(gdk_x11_get_default_xdisplay(), GDK_WINDOW_XID(w), NoEventMask);
        gdk_window_move_resize(w, 0, 0, gdk_screen_width(), gdk_screen_height());
        gdk_flush();
        gdk_window_set_events(w, gdk_window_get_events(w));

        g_warning("size workaround run fix (%d,%d) to (%d,%d)\n",
                allocation->width, allocation->height,
                gdk_screen_width(), gdk_screen_height());
    }
}

gboolean is_compiz_plugin_valid()
{
    gboolean is_compiz_running = false;
    gint screen_num = 1;//gdk_display_get_n_screens(gdk_display_get_default());
    char buf[128] = {0};
    Display* dpy = XOpenDisplay(NULL);

    for (int i = 0; i < screen_num; ++i) {
        sprintf(buf, "_NET_WM_CM_S%d", i);
        Atom cm_sn_atom = XInternAtom(dpy, buf, 0);
        Window current_cm_sn_owner = XGetSelectionOwner(dpy, cm_sn_atom);
        is_compiz_running = is_compiz_running || (None != current_cm_sn_owner);
    }

    return is_compiz_running;
}


static
void is_compiz_valid(GdkScreen* screen, gpointer data G_GNUC_UNUSED)
{
    if (!gdk_screen_is_composited(screen)) {
        GtkWidget* dialog = gtk_message_dialog_new(NULL, GTK_DIALOG_MODAL,
                                                   GTK_MESSAGE_ERROR,
                                                   GTK_BUTTONS_OK,
                                                   "compiz is dead");
        gtk_dialog_run(GTK_DIALOG(dialog));
        gtk_widget_destroy(dialog);
        exit(1);
    }
}

void check_compiz_validity()
{
    g_signal_connect(G_OBJECT(gdk_screen_get_default()), "composited-changed",
                     G_CALLBACK(is_compiz_valid), NULL);
}

void update_dock_size(GdkScreen* screen G_GNUC_UNUSED, GtkWidget* webview)
{
    GdkGeometry geo = {0};
    geo.min_width = 0;
    geo.min_height = 0;

    gdk_window_set_geometry_hints(gtk_widget_get_window(webview), &geo, GDK_HINT_MIN_SIZE);
    gdk_window_set_geometry_hints(DOCK_GDK_WINDOW(), &geo, GDK_HINT_MIN_SIZE);
    gdk_window_move_resize(gtk_widget_get_window(webview), 0, 0, gdk_screen_width(), gdk_screen_height());
    gdk_window_move_resize(DOCK_GDK_WINDOW(), 0, 0, gdk_screen_width(), gdk_screen_height());
    gdk_window_flush(gtk_widget_get_window(webview));
    gdk_window_flush(DOCK_GDK_WINDOW());

    dock_change_workarea_height(_dock_height);

    init_region(DOCK_GDK_WINDOW(), 0, gdk_screen_height() - _dock_height, gdk_screen_width(), _dock_height);

    tray_icon_do_screen_size_change();
    update_dock_guard_window_position();
}


void check_version()
{
    GKeyFile* dock_config = load_app_config(DOCK_CONFIG);

    GError* err = NULL;
    gchar* version = g_key_file_get_string(dock_config, "main", "version", &err);
    if (err != NULL) {
        g_warning("[%s] read version failed from config file: %s", __func__, err->message);
        g_error_free(err);
        g_key_file_set_string(dock_config, "main", "version", DOCK_VERSION);
        save_app_config(dock_config, DOCK_CONFIG);
    }

    if (version != NULL && g_strcmp0(DOCK_VERSION, version) != 0) {
        g_key_file_set_string(dock_config, "main", "version", DOCK_VERSION);
        save_app_config(dock_config, DOCK_CONFIG);

        system("sed -i 's/DockedItems/"DOCKED_ITEM_GROUP_NAME"/g' $HOME/.config/"APPS_INI);
        GKeyFile* f = load_app_config(APPS_INI);
        gsize len = 0;
        char** list = g_key_file_get_groups(f, &len);
        for (guint i = 1; i < len; ++i) {
            /* g_key_file_set_string(f, list[i], "Type", DOCKED_ITEM_APP_TYPE); */
            if (g_strcmp0(list[i], "wps") == 0) {
                g_key_file_set_string(f, list[i], "Name", "Kingsoft Write");
                g_key_file_set_string(f, list[i], "CmdLine", "/usr/bin/wps %%f");
                g_key_file_set_string(f, list[i], "Icon", "wps-office-wpsmain");
                g_key_file_set_string(f, list[i], "Path", "/usr/share/aplications/wps-office-wps.desktop");
                g_key_file_set_string(f, list[i], "Terminal", "false");
            }
            if (g_strcmp0(list[i], "wpp") == 0) {
                g_key_file_set_string(f, list[i], "Name", "Kingsoft Presentation");
                g_key_file_set_string(f, list[i], "CmdLine", "/usr/bin/wpp %%f");
                g_key_file_set_string(f, list[i], "Icon", "wps-office-wppmain");
                g_key_file_set_string(f, list[i], "Path", "/usr/share/aplications/wps-office-wpp.desktop");
                g_key_file_set_string(f, list[i], "Terminal", "false");
            }
            if (g_strcmp0(list[i], "et") == 0) {
                g_key_file_set_string(f, list[i], "Name", "Kingsoft Spreadsheet");
                g_key_file_set_string(f, list[i], "CmdLine", "/usr/bin/et %%f");
                g_key_file_set_string(f, list[i], "Icon", "wps-office-etmain");
                g_key_file_set_string(f, list[i], "Path", "/usr/share/aplications/wps-office-et.desktop");
                g_key_file_set_string(f, list[i], "Terminal", "false");
            }
        }
        g_strfreev(list);

        list = g_key_file_get_string_list(f, DOCKED_ITEM_GROUP_NAME, DOCKED_ITEM_KEY_NAME, &len, &err);
        if (err != NULL) {
            g_error_free(err);
            len = 0;
            list = NULL;
        }
        for (guint i = 0; i < len; ++i) {
            if (g_strcmp0("wps", list[i]) == 0) {
                g_free(list[i]);
                list[i] = g_strdup("wps-office-wps");
            }
            if (g_strcmp0("wpp", list[i]) == 0) {
                g_free(list[i]);
                list[i] = g_strdup("wps-office-wpp");
            }
            if (g_strcmp0("et", list[i]) == 0) {
                g_free(list[i]);
                list[i] = g_strdup("wps-office-et");
            }
        }
        if (list != NULL) {
            g_key_file_set_string_list(f, DOCKED_ITEM_GROUP_NAME, DOCKED_ITEM_KEY_NAME, (const char* const*)list, len);
            g_strfreev(list);
        }
        save_app_config(f, APPS_INI);
        system("sed -i 's/\\[wps\\]/\\[wps-office-wps\\]/g' $HOME/.config/"APPS_INI);
        system("sed -i 's/\\[wpp\\]/\\[wps-office-wpp\\]/g' $HOME/.config/"APPS_INI);
        system("sed -i 's/\\[et\\]/\\[wps-office-et\\]/g' $HOME/.config/"APPS_INI);
        g_key_file_unref(f);
    }

    g_free(version);

    g_key_file_unref(dock_config);
}


int main(int argc, char* argv[])
{
    if (is_application_running(DOCK_ID_NAME)) {
        g_warning(_("another instance of dock is running...\n"));
        return 1;
    }

    singleton(DOCK_ID_NAME);

    //remove  option -f
    parse_cmd_line (&argc, &argv);

    check_version();

    init_i18n();
    gtk_init(&argc, &argv);

    /* check_compiz_validity(); */

/* #define DEBUG_REGION */
#ifndef NDEBUG
    g_log_set_default_handler((GLogFunc)log_to_file, "dock");
#endif
    set_desktop_env_name("Deepin");
    set_default_theme("Deepin");

    container = create_web_container(FALSE, TRUE);
    gtk_window_set_decorated(GTK_WINDOW(container), FALSE);

    gdk_error_trap_push(); //we need remove this, but now it can ignore all X error so we would'nt crash.

    webview = d_webview_new_with_uri(GET_HTML_PATH("dock"));

    gtk_container_add(GTK_CONTAINER(container), GTK_WIDGET(webview));

    g_signal_connect(container , "destroy", G_CALLBACK (gtk_main_quit), NULL);
#ifndef DEBUG_REGION
    g_signal_connect(webview, "draw", G_CALLBACK(erase_background), NULL);
#endif
#undef DEBUG_REGION
    g_signal_connect(container, "enter-notify-event", G_CALLBACK(enter_notify), NULL);
    g_signal_connect(container, "leave-notify-event", G_CALLBACK(leave_notify), NULL);
    g_signal_connect(container, "size-allocate", G_CALLBACK(size_workaround), NULL);


    GdkScreen* screen = gdk_screen_get_default();
    g_signal_connect_after(screen, "size-changed", G_CALLBACK(update_dock_size), webview);

    gtk_widget_realize(container);
    gtk_widget_realize(webview);
    gtk_window_move(GTK_WINDOW(container), 0, 0);
    gtk_widget_show_all(container);

    update_dock_size(screen, webview);

    set_wmspec_dock_hint(DOCK_GDK_WINDOW());

#ifndef NDEBUG
    monitor_resource_file("dock", webview);
#endif

    /*gdk_window_set_debug_updates(TRUE);*/

    GdkRGBA rgba = { 0, 0, 0, 0.0 };
    gdk_window_set_background_rgba(DOCK_GDK_WINDOW(), &rgba);

    setup_dock_dbus_service();
    gtk_main();
    return 0;
}

void update_dock_color()
{
    /*if (GD.is_webview_loaded)*/
        js_post_signal("dock_color_changed");
}

void update_dock_size_mode()
{
    if (GD.config.mini_mode) {
        js_post_signal("in_mini_mode");
    } else {
        js_post_signal("in_normal_mode");
    }
}

JS_EXPORT_API
void dock_emit_webview_ok()
{
    static gboolean inited = FALSE;
    if (!inited) {
        if (!is_compiz_plugin_valid()) {
            gtk_widget_hide(container);
            GtkWidget* dialog = gtk_message_dialog_new(NULL, GTK_DIALOG_MODAL,
                                                       GTK_MESSAGE_ERROR,
                                                       GTK_BUTTONS_OK,
                                                       _("Dock failed to start"
                                                         ", because the plugin"
                                                         " of compiz is not "
                                                         "enabled"));
            gtk_dialog_run(GTK_DIALOG(dialog));
            gtk_widget_destroy(dialog);
            exit(2);
        }

        inited = TRUE;
        init_config();
        init_launchers();
        init_task_list();
        tray_init(webview);
        update_dock_size_mode();
        init_dock_guard_window();
    } else {
        update_dock_apps();
        update_task_list();
        update_dock_size_mode();
        tray_icon_do_screen_size_change();
    }
    GD.is_webview_loaded = TRUE;
    if (GD.config.hide_mode == ALWAYS_HIDE_MODE) {
        dock_hide_now();
    } else {
    }
}

void _change_workarea_height(int height)
{
    if (GD.is_webview_loaded && GD.config.hide_mode == NO_HIDE_MODE ) {
        set_struct_partial(DOCK_GDK_WINDOW(), ORIENTATION_BOTTOM, height, 0, gdk_screen_width());
    } else {
        set_struct_partial(DOCK_GDK_WINDOW(), ORIENTATION_BOTTOM, 0, 0, gdk_screen_width());
    }
}

JS_EXPORT_API
void dock_change_workarea_height(double height)
{
    if ((int)height == _dock_height)
        return;

    if (height < 30)
        _dock_height = 30;
    else
        _dock_height = height;
    _change_workarea_height(height);
    init_region(DOCK_GDK_WINDOW(), 0, gdk_screen_height() - _dock_height, gdk_screen_width(), _dock_height);
}

JS_EXPORT_API
void dock_toggle_launcher(gboolean show)
{
    if (show) {
        run_command("launcher");
    } else {
        close_launcher_window();
    }
}

DBUS_EXPORT_API
void dock_show_inspector()
{
    dwebview_show_inspector(webview);
}

