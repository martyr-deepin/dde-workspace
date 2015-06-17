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

#include "dock_config.h"
#include <dwebview.h>
#include "dock.h"
#include "X_misc.h"
#include "xdg_misc.h"
#include "utils.h"
#include "i18n.h"
#include "dock_config.h"
#include "region.h"
#include "dock_hide.h"
#include "DBUS_dock.h"
#include "monitor.h"
#include "display_info.h"
#include "date_time.h"
#include "session_register.h"

#define DOCK_CONFIG "dock/config.ini"
#define DOCKED_ITEM_KEY_NAME "Position"
#define DOCKED_ITEM_GROUP_NAME "__Config__"
#define APPS_INI "dock/apps.ini"

static GtkWidget* container = NULL;
static GtkWidget* webview = NULL;

struct DisplayInfo dock;
GdkWindow* DOCK_GDK_WINDOW() { return gtk_widget_get_window(container); }
GdkWindow* GET_CONTAINER_WINDOW() { return DOCK_GDK_WINDOW(); }
GdkWindow* WEBVIEW_GDK_WINDOW() {return gtk_widget_get_window(webview);}

JS_EXPORT_API
void dock_change_workarea_height(double height);

PRIVATE
void _update_dock_size(gint16 x, gint16 y, guint16 w, guint16 h);
gboolean update_dock_size();
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


Window get_dock_window()
{
    g_assert(container != NULL);
    return GDK_WINDOW_XID(DOCK_GDK_WINDOW());
}


void container_size_workaround(GtkWidget* container, GdkRectangle* allocation)
{
    static GRWLock lock;
    g_rw_lock_writer_lock(&lock);
    update_primary_info(&dock);
    g_rw_lock_writer_unlock(&lock);
    if (gtk_widget_get_realized(container) && (dock.width != allocation->width || dock.height != allocation->height)) {
        GdkWindow* w = gtk_widget_get_window(container);
        GdkGeometry geo = {0};
        geo.min_width = 0;
        geo.min_height = 0;

        gdk_window_set_geometry_hints(w, &geo, GDK_HINT_MIN_SIZE);
        XSelectInput(gdk_x11_get_default_xdisplay(), GDK_WINDOW_XID(w), NoEventMask);
        gdk_window_move_resize(w, dock.x, dock.y, dock.width, dock.height);
        gdk_flush();
        gdk_window_set_events(w, gdk_window_get_events(w));

        g_warning("[%s] size workaround run fix (%d,%d) to (%d,%d)\n",
                  __func__,
                  allocation->width, allocation->height,
                  dock.width, dock.height);
    }
}


void webview_size_workaround(GtkWidget* container, GdkRectangle* allocation)
{
    static GRWLock lock;
    g_rw_lock_writer_lock(&lock);
    update_primary_info(&dock);
    g_rw_lock_writer_unlock(&lock);
    if (gtk_widget_get_realized(container) && (dock.width != allocation->width || dock.height != allocation->height)) {
        GdkWindow* w = gtk_widget_get_window(container);
        GdkGeometry geo = {0};
        geo.min_width = 0;
        geo.min_height = 0;

        gdk_window_set_geometry_hints(w, &geo, GDK_HINT_MIN_SIZE);
        XSelectInput(gdk_x11_get_default_xdisplay(), GDK_WINDOW_XID(w), NoEventMask);
        gdk_window_move_resize(w, 0, 0, dock.width, dock.height);
        gdk_flush();
        gdk_window_set_events(w, gdk_window_get_events(w));

        g_warning("[%s] size workaround run fix (%d,%d) to (%d,%d)\n",
                  __func__,
                  allocation->width, allocation->height,
                  dock.width, dock.height);
    }
}


gboolean is_compiz_plugin_valid()
{
    gboolean is_compiz_running = false;
    // !!! according to the document, the number of screens is always 1 since
    // v3.10.
    gint screen_num = 1;// gdk_display_get_n_screens(gdk_display_get_default());
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

        int noused G_GNUC_UNUSED;
        noused = system("sed -i 's/DockedItems/"DOCKED_ITEM_GROUP_NAME"/g' $HOME/.config/"APPS_INI);
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
        noused = system("sed -i 's/\\[wps\\]/\\[wps-office-wps\\]/g' $HOME/.config/"APPS_INI);
        noused = system("sed -i 's/\\[wpp\\]/\\[wps-office-wpp\\]/g' $HOME/.config/"APPS_INI);
        noused = system("sed -i 's/\\[et\\]/\\[wps-office-et\\]/g' $HOME/.config/"APPS_INI);
        g_key_file_unref(f);
    }

    g_free(version);

    g_key_file_unref(dock_config);
}


void update_dock_color()
{
    /*if (GD.is_webview_loaded)*/
        /* js_post_signal("dock_color_changed"); */
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
                                                         ", because "
                                                         "Compiz is not "
                                                         "enabled."));
            gtk_dialog_run(GTK_DIALOG(dialog));
            gtk_widget_destroy(dialog);
            exit(2);
        }

        inited = TRUE;
        init_config();
    }

    g_warning("[%s]", __func__);

    GRWLock lock;
    g_rw_lock_init(&lock);  // non-static GRWLock must init and clear.
    g_rw_lock_writer_lock(&lock);
    update_primary_info(&dock);
    g_rw_lock_writer_unlock(&lock);
    g_rw_lock_clear(&lock);

    _update_dock_size(dock.x, dock.y, dock.width, dock.height);
    gtk_widget_show_all(container);

    GD.is_webview_loaded = TRUE;

    if (GD.config.hide_mode == ALWAYS_HIDE_MODE) {
        // dock_hide_now();
    } else {
    }
    dde_session_register();
}

void _change_workarea_height(int height)
{
    static int saved_height = -1;
    if (saved_height == height) {
        g_warning("workarea is already %d", height);
        //NOTE: saved_height is useful due to the really workarea value may be changed
        //by other guys.
        /*return;*/
    }
    saved_height = height;

    // update_primary_info(&dock);
    int workarea_width = (dock.width - GD.dock_panel_width) / 2;
    int workarea_start = dock.x + workarea_width;
    // NB: minus 1 to avoid struct cross screens.
    int workarea_end = MAX(workarea_start, dock.x + dock.width - workarea_width - 1);
    if (GD.config.hide_mode == NO_HIDE_MODE ) {
        g_message("NO_HIDE_MODE, set workarea height to %d", height);
    } else {
        g_message("HIDE_MODE, set workarea height to 0");
    }
    set_struct_partial(DOCK_GDK_WINDOW(),
                       ORIENTATION_BOTTOM,
                       height,
                       workarea_start,
                       workarea_end);
}


gboolean workaround_change_workarea_height(int height)
{
    int workarea_height = gdk_screen_height() - dock.height - dock.y + height;
    if (workarea_height < 0 || workarea_height > gdk_screen_height()) {
        //don't used this invalid value caused by gdk_screen_height() hasn't update.
        g_warning("Err: workaround_change_workarea_height: %d = %d - %d -%d + %d\n",
                workarea_height, gdk_screen_height(), dock.height, dock.y, height);
        gdk_flush();
        g_timeout_add(1000, (GSourceFunc)workaround_change_workarea_height, GINT_TO_POINTER(height));
    } else {
        g_debug("OK: workaround_change_workarea_height: %d = %d - %d - %d + %d\n",
                workarea_height, gdk_screen_height(), dock.height, dock.y, height);
        _change_workarea_height(workarea_height);
        // cannot use workarea_height to initialize the y axis and dock height.
        init_region(DOCK_GDK_WINDOW(), 0, dock.height - GD.dock_height, dock.width, GD.dock_height);
    }
    return FALSE;
}


void update_workarea()
{
    if (GD.config.hide_mode == NO_HIDE_MODE ) {
        workaround_change_workarea_height(GD.dock_height);
    } else {
        workaround_change_workarea_height(0);
    }
}


JS_EXPORT_API
void dock_change_workarea_height(double height)
{
    gdk_flush();
    workaround_change_workarea_height((int)height);
}

JS_EXPORT_API
void dock_toggle_launcher(gboolean show)
{
    if (show) {
        run_command("dde-launcher");
    } else {
        dbus_launcher_hide();
        js_post_signal("launcher_destroy");
    }
}

DBUS_EXPORT_API
void dock_show_inspector()
{
    dwebview_show_inspector(webview);
}


DBUS_EXPORT_API
void dock_bus_message_notify(gchar* appid, gchar* itemid)
{
    JSObjectRef info = json_create();
    json_append_string(info, "appid", appid);
    json_append_string(info, "itemid", itemid);
    js_post_message("message_notify", info);
}


gboolean update_dock_size()
{
    g_debug("[%s]", __func__);
    _update_dock_size(dock.x, dock.y, dock.width, dock.height);
    return G_SOURCE_REMOVE;
}


void _update_dock_size(gint16 x, gint16 y, guint16 w, guint16 h)
{
    GdkGeometry geo = {0};
    geo.min_width = 0;
    geo.min_height = 0;

    gdk_window_set_geometry_hints(WEBVIEW_GDK_WINDOW(), &geo, GDK_HINT_MIN_SIZE);
    gdk_window_set_geometry_hints(DOCK_GDK_WINDOW(), &geo, GDK_HINT_MIN_SIZE);
    gdk_flush();

    g_debug("[%s] %dx%d(%d, %d)", __func__, w, h, x, y);
    gdk_window_move_resize(DOCK_GDK_WINDOW(), x, y, w, h);
    gdk_window_move_resize(WEBVIEW_GDK_WINDOW(), 0, 0, w, h);

    gdk_window_flush(WEBVIEW_GDK_WINDOW());
    gdk_window_flush(DOCK_GDK_WINDOW());

    dock_change_workarea_height(GD.dock_height);
}


static
void primary_changed_handler(GDBusConnection* conn G_GNUC_UNUSED,
                             const gchar* sender_name G_GNUC_UNUSED,
                             const gchar* object_path G_GNUC_UNUSED,
                             const gchar* interface_name G_GNUC_UNUSED,
                             const gchar* signal_name G_GNUC_UNUSED,
                             GVariant* parameters G_GNUC_UNUSED,
                             gpointer data G_GNUC_UNUSED
                             )
{
    static GRWLock lock;
    struct DisplayInfo* rect = (struct DisplayInfo*)data;

    g_rw_lock_writer_lock(&lock);
    g_variant_get(parameters, "((nnqq))", &rect->x, &rect->y, &rect->width, &rect->height);
    g_rw_lock_writer_unlock(&lock);

    _update_dock_size(rect->x, rect->y, rect->width, rect->height);
    js_post_signal("resolution-changed");
}


guint64 dock_xid()
{
    return (guint64)GDK_WINDOW_XID(DOCK_GDK_WINDOW());
}


void dock_quit()
{
    gtk_main_quit();
}


void notify_icon_theme_changed(GtkIconTheme* theme G_GNUC_UNUSED, gpointer data G_GNUC_UNUSED)
{
    js_post_signal("icon_theme_changed");
}


static void emit_use_24_hour_display_changed(int num)
{
    if (GD.is_webview_loaded) {
        JSObjectRef info = json_create();
        json_append_number(info, "hour_display", (double)num);
        js_post_message("use_24_hour_display_changed", info);
    }
}


int main(int argc, char* argv[])
{
    if (is_application_running(DOCK_ID_NAME)) {
        g_warning("another instance of dock is running...\n");
        return 1;
    }

    singleton(DOCK_ID_NAME);

    //remove  option -f
    parse_cmd_line (&argc, &argv);

    check_version();

    init_i18n();
    gtk_init(&argc, &argv);

    /* check_compiz_validity(); */

#ifdef NDEBUG
    g_setenv("G_MESSAGES_DEBUG", "all", FALSE);
#endif
    g_log_set_default_handler((GLogFunc)log_to_file, "dde-dock");

    set_desktop_env_name("Deepin");
    GtkIconTheme* theme = gtk_icon_theme_get_default();
    g_signal_connect(theme, "changed", G_CALLBACK(notify_icon_theme_changed), NULL);

    container = create_web_container(FALSE, TRUE);
    gtk_window_set_decorated(GTK_WINDOW(container), FALSE);

    gdk_error_trap_push(); //we need remove this, but now it can ignore all X error so we would'nt crash.

    webview = d_webview_new_with_uri(GET_HTML_PATH("dock"));
    gtk_container_add(GTK_CONTAINER(container), GTK_WIDGET(webview));
    gtk_widget_realize(webview);
    gtk_widget_realize(container);
    g_signal_connect(webview, "draw", G_CALLBACK(erase_background), NULL);

    extern gboolean draw_embed_windows(GtkWidget* w, cairo_t *cr);
    g_signal_connect_after(webview, "draw", G_CALLBACK(draw_embed_windows), NULL);


    g_signal_connect(container , "destroy", G_CALLBACK (gtk_main_quit), NULL);
    // g_signal_connect(container, "enter-notify-event", G_CALLBACK(enter_notify), NULL);
    // g_signal_connect(container, "leave-notify-event", G_CALLBACK(leave_notify), NULL);
    g_signal_connect(container, "size-allocate", G_CALLBACK(container_size_workaround), NULL);
    // g_signal_connect(webview, "size-allocate", G_CALLBACK(webview_size_workaround), NULL);

    gtk_widget_set_size_request(container, 1, 1);
    gtk_widget_set_size_request(webview, 1, 1);

    set_wmspec_dock_hint(DOCK_GDK_WINDOW());
    listen_primary_changed_signal(primary_changed_handler, &dock, NULL);

// #ifndef NDEBUG
//     monitor_resource_file("dock", webview);
// #endif

    /*gdk_window_set_debug_updates(TRUE);*/

    setup_dock_dbus_service();
    GFileMonitor* m G_GNUC_UNUSED = monitor_trash();
    listen_use_24_hour_changed(emit_use_24_hour_display_changed);

    gtk_widget_show_all(container);

    gtk_main();
    return 0;
}

