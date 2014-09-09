/**
 * Copyright (c) 2011 ~ 2014 Deepin, Inc.
 *               2011 ~ 2014 snyh
 *
 * Author:      snyh <snyh@snyh.org>
 *              bluth <yuanchenglu001@gmail.com>
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

#include <sys/stat.h>

#include <glib.h>
#include <glib/gstdio.h>
#include <gtk/gtk.h>
#include <cairo/cairo-xlib.h>

#include <shadow.h>
#include <crypt.h>
#include <string.h>

#include "xdg_misc.h"
#include "X_misc.h"
#include "pixbuf.h"
#include "i18n.h"
#include "dentry/entry.h"
#include "inotify_item.h"
#include "dcore.h"
#include <dwebview.h>
#include "utils.h"
#include "desktop_utils.h"
#include "session_register.h"
#include "DBUS_desktop.h"
#include "display_info.h"
#include "desktop.h"

#define DESKTOP_CONFIG "desktop/config.ini"
#define DESKTOP_SCHEMA_ID "com.deepin.dde.desktop"
#define DOCK_SCHEMA_ID "com.deepin.dde.dock"

#define HIDE_MODE_KEY "hide-mode"
#define HIDE_MODE_KEEPSHOWING 0
#define HIDE_MODE_KEEPHIDDEN 1
#define HIDE_MODE_AUTOHIDDEN 2

#define DISPLAY_MODE_KEY "display-mode"
#define FASHION_MODE 0
#define EFFICIENT_MODE 1
#define CLASSIC_MODE 2

#define FASHION_DOCK_HEIGHT 68
#define EFFICIENT_DOCK_HEIGHT 48
#define CLASSIC_DOCK_HEIGHT 36

#define SHOW_COMPUTER_ICON "show-computer-icon"
#define SHOW_TRASH_ICON "show-trash-icon"
#define ENABLED_PLUGINS "enabled-plugins"

#define APP_DEFAULT_ICON "application-default-icon"

extern void monitor_and_update_proxy();

PRIVATE
GSettings* desktop_gsettings = NULL;
GSettings* dock_gsettings = NULL;

PRIVATE GtkWidget* container = NULL;
PRIVATE GtkWidget* webview = NULL;
PRIVATE GtkIMContext* im_context = NULL;

struct DisplayInfo primaryInfo;
PRIVATE int dock_height = 0;

extern void install_monitor();
PRIVATE
void setup_root_window_watcher(GtkWidget* widget, GSettings* dock_gsettings);
PRIVATE
void unwatch_workarea_changes(GtkWidget* widget);

//store xids belong desktop to helper find "Focus Changed"
PRIVATE Window __DESKTOP_XID[3]= {0};

PRIVATE
GFile* _get_useable_file(const char* basename);


DBUS_EXPORT_API
void desktop_item_update()
{
    GError* err = NULL;
    GDBusConnection* conn = g_bus_get_sync(G_BUS_TYPE_SESSION, NULL, &err);
    if (err != NULL) {
        g_warning("%s", err->message);
        g_error_free(err);
        return;
    }
    g_dbus_connection_emit_signal(conn,
                                  NULL,
                                  "/com/deepin/dde/desktop",
                                  "com.deepin.dde.desktop",
                                  "ItemUpdate",
                                  NULL,
                                  &err
                                  );
    g_object_unref(conn);
    if (err != NULL) {
        g_warning("desktop emit ItemUpdate signal failed: %s", err->message);
        g_error_free(err);
    }
}

DBUS_EXPORT_API
void desktop_richdir_create_signal()
{
    GError* err = NULL;
    GDBusConnection* conn = g_bus_get_sync(G_BUS_TYPE_SESSION, NULL, &err);
    if (err != NULL) {
        g_warning("%s", err->message);
        g_error_free(err);
        return;
    }
    g_dbus_connection_emit_signal(conn,
                                  NULL,
                                  "/com/deepin/dde/desktop",
                                  "com.deepin.dde.desktop",
                                  "RichdirCreate",
                                  NULL,
                                  &err
                                  );
    g_object_unref(conn);
    if (err != NULL) {
        g_warning("desktop emit RichdirCreate signal failed: %s", err->message);
        g_error_free(err);
    }
}


JS_EXPORT_API
JSObjectRef desktop_get_desktop_entries()
{
    JSObjectRef array = json_array_create();
    GDir* dir = g_dir_open(DESKTOP_DIR(), 0, NULL);

    const char* file_name = NULL;
    for (int i=0; NULL != (file_name = g_dir_read_name(dir));) {
        if(desktop_file_filter(file_name))
            continue;
        char* path = g_build_filename(DESKTOP_DIR(), file_name, NULL);
        Entry* e = dentry_create_by_path(path);
        g_free(path);
        json_array_insert_nobject(array, i++, e, g_object_ref, g_object_unref);
        g_object_unref(e);
    }
    g_dir_close(dir);
    return array;
}

JS_EXPORT_API
char* desktop_get_rich_dir_name(GFile* dir)
{
    char* name = g_file_get_basename(dir);
    char* ret = g_strdup(name+DEEPIN_RICH_DIR_LEN);
    g_free(name);
    return ret;
}

JS_EXPORT_API
void desktop_set_rich_dir_name(GFile* dir, const char* name)
{
    char* new_name = g_strconcat(DEEPIN_RICH_DIR, name, NULL);
    dentry_set_name(dir, new_name);
    g_free(new_name);
}

char* dentry_get_icon_path(Entry* e);
JS_EXPORT_API
char* desktop_get_rich_dir_icon(GFile* _dir)
{
    char* icons[4] = {NULL, NULL, NULL, NULL};
    char* bad_icons[4] = {NULL, NULL, NULL, NULL};

    char* dir_path = g_file_get_path(_dir);
    GDir* dir = g_dir_open(dir_path, 0, NULL);
    const char* child_name = NULL;
    int i=0, j=0;
    for (; NULL != (child_name = g_dir_read_name(dir));) {
        if (g_str_has_suffix(child_name, ".desktop")) {
            char* path = g_build_filename(dir_path, child_name, NULL);
            Entry* entry = dentry_create_by_path(path);
            char* icon_path = dentry_get_icon_path(entry);
            if (icon_path == NULL)
            {
                g_warning("richdir dentry %d get_icon is null use %s.png instead",i,APP_DEFAULT_ICON);
                icon_path = dcore_get_theme_icon(APP_DEFAULT_ICON, 48);
                g_debug("icon_path %d :---%s---",i,icon_path);
            }
            icons[i++] = icon_path;
            g_object_unref(entry);
            g_free(path);
        } else if (j<4) {
            char* path = g_build_filename(dir_path, child_name, NULL);
            Entry* entry = dentry_create_by_path(path);
            bad_icons[j++] = dentry_get_icon_path(entry);
            g_object_unref(entry);
            g_free(path);
        }

        if (i >= 4) break;
    }
    g_dir_close(dir);
    g_free(dir_path);
    char* ret = generate_directory_icon(
            icons[0] ? icons[0] : bad_icons[0],
            icons[1] ? icons[1] : bad_icons[1],
            icons[2] ? icons[2] : bad_icons[2],
            icons[3] ? icons[3] : bad_icons[3]);
    for (int i=0; i<4; i++) {
        g_free(icons[i]);
        g_free(bad_icons[i]);
    }
    return ret;
}

JS_EXPORT_API
GFile* desktop_create_rich_dir(ArrayContainer fs)
{
    char* group_name = dentry_get_rich_dir_group_name(fs);
    char* temp_name = g_strconcat (DEEPIN_RICH_DIR, _(group_name), NULL);
    g_free(group_name);
    g_debug ("create_rich_dir: %s", temp_name);

    GFile* dir = _get_useable_file(temp_name);
    g_free(temp_name);

    g_file_make_directory(dir, NULL, NULL);
    dentry_move(fs, dir, TRUE);
    desktop_richdir_create_signal();

    return dir;
}

JS_EXPORT_API
const char* desktop_get_desktop_path()
{
    return DESKTOP_DIR();
}


GFile* _get_useable_file(const char* basename)
{
    GFile* dir = g_file_new_for_path(DESKTOP_DIR());

    char* name = g_strdup(basename);
    GFile* child = g_file_get_child(dir, name);
    for (int i=0; g_file_query_exists(child, NULL); i++) {
        g_object_unref(child);
        g_free(name);
        name = g_strdup_printf("%s(%d)", basename, i);
        child = g_file_get_child(dir, name);
    }

    g_object_unref(dir);
    return child;
}


GFile* _get_useable_file_templates(const char* basename,const char* name_add_before)
{
    GFile* dir = g_file_new_for_path(DESKTOP_DIR());

    char* name = g_strdup(basename);
    GFile* child = g_file_get_child(dir, name);
    for (int i=0; g_file_query_exists(child, NULL); i++) {
        g_object_unref(child);
        g_free(name);
        name = g_strdup_printf("%s(%d)%s",name_add_before, i,basename);
        child = g_file_get_child(dir, name);
    }

    g_object_unref(dir);
    return child;
}

JS_EXPORT_API
GFile* desktop_new_file(const char* name_add_before)
{
    GFile* file = _get_useable_file_templates(_("New file"),name_add_before);
    GFileOutputStream* stream =
        g_file_create(file, G_FILE_CREATE_NONE, NULL, NULL);
    if (stream)
        g_object_unref(stream);
    return file;
}

JS_EXPORT_API
GFile* desktop_new_directory(const char* name_add_before)
{
    GFile* dir = _get_useable_file_templates(_("New directory"),name_add_before);
    g_file_make_directory(dir, NULL, NULL);
    //TODO: detect create status..
    return dir;
}

JS_EXPORT_API
gboolean desktop_get_config_boolean(const char* key_name)
{
    gboolean retval = g_settings_get_boolean(desktop_gsettings, key_name);

    return retval;
}
JS_EXPORT_API
gboolean desktop_set_config_boolean(const char* key_name,gboolean value)
{
    gboolean retval = g_settings_set_boolean(desktop_gsettings, key_name,value);
    return retval;
}

PRIVATE
int get_workarea_height(int primary_height)
{
    int area_heigth = primary_height;
    int  hide_mode = g_settings_get_enum (dock_gsettings, HIDE_MODE_KEY);
    if (hide_mode == HIDE_MODE_KEEPSHOWING){
        int  display_mode = g_settings_get_enum (dock_gsettings, DISPLAY_MODE_KEY);
        switch(display_mode)
        {
            case FASHION_MODE:
                dock_height = FASHION_DOCK_HEIGHT;
                break;
            case EFFICIENT_MODE:
                dock_height = EFFICIENT_DOCK_HEIGHT;
                break;
            case CLASSIC_MODE:
                dock_height = CLASSIC_DOCK_HEIGHT;
                break;
            default:
                dock_height = EFFICIENT_DOCK_HEIGHT;
                break;
        }
    }else{
        dock_height = 0;
    }
    area_heigth = primary_height - dock_height;
    return area_heigth;
}

PRIVATE gboolean update_workarea_size()
{
    update_display_info(&primaryInfo);
    if (primaryInfo.width == 0 || primaryInfo.height == 0) {
        g_timeout_add(200, (GSourceFunc)update_workarea_size, NULL);
        return G_SOURCE_REMOVE;
    }
    int height = get_workarea_height(primaryInfo.height);
    JSObjectRef workarea_info = json_create();
    json_append_number(workarea_info, "x", 0);
    json_append_number(workarea_info, "y", 0);
    json_append_number(workarea_info, "width", primaryInfo.width);
    json_append_number(workarea_info, "height", height);
    g_debug("[%s]:workarea_changed signal:%d*%d(%d,%d)",__func__,primaryInfo.width,height,primaryInfo.x,primaryInfo.y);
    js_post_message("workarea_changed", workarea_info);
    return G_SOURCE_REMOVE;
}

PRIVATE void dock_hide_mode_changed(GSettings* settings G_GNUC_UNUSED)
{
    update_workarea_size();
}

PRIVATE void dock_display_mode_changed(GSettings* settings)
{
    int  display_mode = g_settings_get_enum (settings, DISPLAY_MODE_KEY);
    g_debug ("[%s]: %d",__func__ ,display_mode);
    update_workarea_size ();
    switch(display_mode)
    {
        case FASHION_MODE:
            desktop_set_config_boolean(SHOW_COMPUTER_ICON,false);
            desktop_set_config_boolean(SHOW_TRASH_ICON,false);
            break;
        case EFFICIENT_MODE:
            desktop_set_config_boolean(SHOW_COMPUTER_ICON,true);
            desktop_set_config_boolean(SHOW_TRASH_ICON,true);
            break;
        case CLASSIC_MODE:
            desktop_set_config_boolean(SHOW_COMPUTER_ICON,true);
            desktop_set_config_boolean(SHOW_TRASH_ICON,true);
            break;
        default:
            break;
    }
}

PRIVATE void dock_config_changed(GSettings* settings, char* key, gpointer usr_data G_GNUC_UNUSED)
{
    g_debug ("dock config changed key:%s",key);
    if (0 == g_strcmp0(key, HIDE_MODE_KEY)){
        dock_hide_mode_changed(settings);
    }else if (0 == g_strcmp0(key, DISPLAY_MODE_KEY)){
        dock_display_mode_changed(settings);
    }
    return;
}


PRIVATE void desktop_config_changed(GSettings* settings G_GNUC_UNUSED,
                                    char* key,
                                    gpointer usr_data G_GNUC_UNUSED)
{
    g_debug ("desktop config changed key:%s",key);
    JSObjectRef info = json_create();
    json_append_string(info, "key", key);
    js_post_message ("desktop_config_changed",info);
}

extern GHashTable* enabled_plugins;
extern GHashTable* disabled_plugins;
extern GHashTable* plugins_state;
#define SCHEMA_KEY_ENABLED_PLUGINS "enabled-plugins"
enum PluginState {
    DISABLED_PLUGIN,
    ENABLED_PLUGIN,
    UNKNOWN_PLUGIN
};


extern void get_enabled_plugins(GSettings* gsettings, char const* key);

PRIVATE
void _change_to_json(gpointer key, gpointer value, gpointer user_data)
{
    json_append_number((JSObjectRef)user_data, key, GPOINTER_TO_INT(value));
}


PRIVATE void desktop_plugins_changed(GSettings* settings, char* key G_GNUC_UNUSED, gpointer user_data G_GNUC_UNUSED)
{
    extern gchar * get_schema_id(GSettings* gsettings);
    extern void _init_state(gpointer key, gpointer value, gpointer user_data);

    g_hash_table_foreach(plugins_state, _init_state, plugins_state);
    get_enabled_plugins(settings, ENABLED_PLUGINS);

    JSObjectRef json = json_create();
    char* current_gsettings_schema_id = get_schema_id(settings);
    char* desktop_gsettings_schema_id = get_schema_id(desktop_gsettings);
    if (0 == g_strcmp0(current_gsettings_schema_id, desktop_gsettings_schema_id))
        json_append_string(json, "app_name", "desktop");

    g_free(desktop_gsettings_schema_id);
    g_free(current_gsettings_schema_id);

    g_hash_table_foreach(plugins_state, _change_to_json, (gpointer)json);
    js_post_message("plugins_changed", json);
}


JS_EXPORT_API
char* desktop_get_data_dir()
{
    return g_strdup (DATA_DIR);
}


JS_EXPORT_API
gboolean desktop_file_exist_in_desktop(char* name)
{
    GDir* dir = g_dir_open(DESKTOP_DIR(), 0, NULL);
    gboolean result = false;
    const char* file_name = NULL;
    while (NULL != (file_name = g_dir_read_name(dir))) {
        if(desktop_file_filter(file_name))
            continue;
        if(0 == g_strcmp0(name,file_name))
        {
            result = true;
        }

    }
    g_dir_close(dir);
    return result;
}



//TODO: connect gtk_icon_theme changed.
gboolean prevent_exit(GtkWidget* w G_GNUC_UNUSED, GdkEvent* e G_GNUC_UNUSED)
{
    return true;
}

void send_lost_focus()
{
    js_post_signal("lost_focus");
}

void send_get_focus()
{
    js_post_signal("get_focus");
}

DBUS_EXPORT_API
void desktop_focus_changed(gboolean focused)
{
    if(TRUE == focused)
        send_get_focus();
    else
        send_lost_focus();
}

PRIVATE
G_GNUC_UNUSED
void _do_im_commit(GtkIMContext *context G_GNUC_UNUSED, gchar* str)
{
    JSObjectRef json = json_create();
    json_append_string(json, "Content", str);
    js_post_message("im_commit", json);
}

JS_EXPORT_API
void desktop_set_position_input(double x , double y)
{
    int width = 100;
    int height = 30;
    GdkRectangle area = {(int)x, (int)y, width, height};

    gtk_im_context_focus_in(im_context);
    GdkWindow* gdkwindow = gtk_widget_get_window(container);
    gtk_im_context_set_client_window(im_context, gdkwindow);
    gtk_im_context_set_cursor_location(im_context, &area);
}

JS_EXPORT_API
gboolean desktop_check_version_equal_set(const char* version_set)
{
    GKeyFile* desktop_config = NULL;
    gboolean result = FALSE;
    if (desktop_config == NULL)
        desktop_config = load_app_config(DESKTOP_CONFIG);

    GError* err = NULL;
    gchar* version = g_key_file_get_string(desktop_config, "main", "version", &err);
    if (err != NULL) {
        g_warning("[%s] read version failed from config file: %s", __func__, err->message);
        g_error_free(err);
        g_key_file_set_string(desktop_config, "main", "version", DESKTOP_VERSION);
        save_app_config(desktop_config, DESKTOP_CONFIG);
        g_message("desktop version : %s ",version);
    }
    else{
        if (0 == g_strcmp0(version,version_set))
            result = TRUE;
        else{
            result = FALSE;
            g_key_file_set_string(desktop_config, "main", "version", version_set);
            save_app_config(desktop_config, DESKTOP_CONFIG);
            g_message("desktop version from %s update to %s",version,version_set);
        }
    }

    if (version != NULL)
        g_free(version);
    g_key_file_unref(desktop_config);
    desktop_config = NULL;

    return result;
}

JS_EXPORT_API
void desktop_force_get_input_focus()
{
    force_get_input_focus(webview);
}

PRIVATE
void move_to_primary_unrealized(GtkWidget* container)
{
    GdkGeometry geo = {0};
    geo.min_height = 0;
    geo.min_width = 0;
    update_display_info(&primaryInfo);
    g_debug("[%s] primaryInfo: %dx%d(%d, %d)", __func__, primaryInfo.width, primaryInfo.height, primaryInfo.x, primaryInfo.y);
    gtk_window_set_geometry_hints(GTK_WINDOW(container), NULL, &geo, GDK_HINT_MIN_SIZE);
    gtk_widget_set_size_request(container, primaryInfo.width, primaryInfo.height);
    gtk_window_move(GTK_WINDOW(container), primaryInfo.x, primaryInfo.y);
}


PRIVATE
void move_to_primary_realized(GtkWidget* container)
{
    GdkGeometry geo = {0};
    geo.min_height = 0;
    geo.min_width = 0;
    update_display_info(&primaryInfo);
    g_debug("[%s] primaryInfo: %dx%d(%d, %d)", __func__, primaryInfo.width, primaryInfo.height, primaryInfo.x, primaryInfo.y);
    if (gtk_widget_get_realized(container)) {
        GdkWindow* gdk = gtk_widget_get_window(container);
        gdk_window_set_geometry_hints(gdk, &geo, GDK_HINT_MIN_SIZE);
        gdk_window_move_resize(gdk, primaryInfo.x, primaryInfo.y,primaryInfo.width,primaryInfo.height );
        gdk_window_flush(gdk);
    }
    update_workarea_size();
}



PRIVATE
void primary_changed_handler(GDBusConnection* conn G_GNUC_UNUSED,
                             const gchar* sender_name G_GNUC_UNUSED,
                             const gchar* object_path G_GNUC_UNUSED,
                             const gchar* interface_name G_GNUC_UNUSED,
                             const gchar* signal_name G_GNUC_UNUSED,
                             GVariant* parameters G_GNUC_UNUSED,
                             gpointer data G_GNUC_UNUSED
                             )
{
    move_to_primary_realized(container);
}

int main(int argc, char* argv[])
{
    if (argc == 2 && 0 == g_strcmp0(argv[1], "-d")){
        g_setenv("G_MESSAGES_DEBUG", "all", FALSE);
    }
    if (is_application_running(DESKTOP_ID_NAME)) {
        g_warning("another instance of application desktop is running...\n");
        return 0;
    }

    singleton(DESKTOP_ID_NAME);

    //remove  option -f
    parse_cmd_line (&argc, &argv);
    init_i18n();
    gtk_init(&argc, &argv);
    monitor_and_update_proxy();

    g_log_set_default_handler((GLogFunc)log_to_file, "dde-desktop");

    set_default_theme("Deepin");
    set_desktop_env_name("Deepin");

    container = create_web_container(FALSE, FALSE);
    move_to_primary_unrealized(container);
    g_signal_connect(container, "delete-event", G_CALLBACK(prevent_exit), NULL);

    webview = d_webview_new_with_uri(GET_HTML_PATH("desktop"));
    gdk_error_trap_push();

    gtk_window_set_skip_pager_hint(GTK_WINDOW(container), TRUE);
    gtk_container_add(GTK_CONTAINER(container), GTK_WIDGET(webview));

    gtk_widget_realize(container);
    gtk_widget_realize(webview);
    g_signal_connect (webview, "draw", G_CALLBACK(erase_background), NULL);
    g_signal_connect (webview, "button-press-event", G_CALLBACK(force_get_input_focus), NULL);

    listen_primary_changed_signal(primary_changed_handler, &primaryInfo, NULL);
    GdkScreen* screen = gtk_window_get_screen(GTK_WINDOW(container));
    g_signal_connect(screen, "size-changed", G_CALLBACK(move_to_primary_realized), container);

    set_wmspec_desktop_hint(gtk_widget_get_window(container));

    GdkWindow* fw = webkit_web_view_get_forward_window(webview);
    gdk_window_stick(fw);

    gtk_widget_show_all(container);
    g_signal_connect (container , "destroy", G_CALLBACK (gtk_main_quit), NULL);

    GdkWindow* gdkwindow = gtk_widget_get_window(container);
    GdkRGBA rgba = { 0, 0, 0, 0.0 };
    gdk_window_set_background_rgba(gdkwindow, &rgba);

    // webview_input = gtk_widget_get_window(webview);

    g_object_get(webview,"im_context",&im_context,NULL);

    setup_desktop_dbus_service ();


#ifndef NDEBUG
    monitor_resource_file("desktop", webview);
#endif

    __DESKTOP_XID[0] = GDK_WINDOW_XID(gtk_widget_get_window(container));
    __DESKTOP_XID[1] = GDK_WINDOW_XID(gtk_widget_get_window(webview));
    __DESKTOP_XID[2] = GDK_WINDOW_XID(fw);
    gtk_main();
    unwatch_workarea_changes(container);
    return 0;
}


PRIVATE GdkFilterReturn watch_root_window(GdkXEvent *gxevent, GdkEvent* event G_GNUC_UNUSED, gpointer user_data)
{
    XPropertyEvent *xevt = (XPropertyEvent*)gxevent;

    if (xevt->type == PropertyNotify) {
    //TODO: cache the atom of "_NET_WORKAREA" and "_NET_ACTIVE_WINDOW"
    //
    if (xevt->atom == gdk_x11_get_xatom_by_name("_NET_WORKAREA")) {
        g_message("GET _NET_WORKAREA change on rootwindow");
        dock_gsettings = user_data;
        //TODO:check if the change caused by dde-dock
        //if FALSE then update_workarea_size
        //or dont update_workarea_size in dock_display_mode_changed and dock_hide_mode_changed function
        update_workarea_size ();
        return GDK_FILTER_CONTINUE;
    } else if (xevt->atom == gdk_x11_get_xatom_by_name("_NET_ACTIVE_WINDOW")) {
        Window active_window=0;
        gboolean state = False;
        if ((state = get_atom_value_by_name(xevt->display, xevt->window, "_NET_ACTIVE_WINDOW", &active_window, get_atom_value_for_index,0))) {
        static gboolean has_focus= False;

        for (size_t i=0; i < sizeof(__DESKTOP_XID)/sizeof(Window); i++) {
            if (__DESKTOP_XID[i] == active_window) {
            has_focus = True;
            desktop_focus_changed(has_focus);
            return GDK_FILTER_CONTINUE;
            }
        }

        has_focus = False;
        desktop_focus_changed(has_focus);
        }
    }
    }
    return GDK_FILTER_CONTINUE;
}

void setup_root_window_watcher(GtkWidget* widget, GSettings* dock_gsettings)
{

    GdkScreen *gscreen = gtk_widget_get_screen(widget);
    GdkWindow *groot = gdk_screen_get_root_window(gscreen);
    gdk_window_set_events(groot, gdk_window_get_events(groot) | GDK_PROPERTY_CHANGE_MASK);
    //TODO: remove this filter when unrealize
    gdk_window_add_filter(groot, watch_root_window, dock_gsettings);
}

void unwatch_workarea_changes(GtkWidget* widget)
{
    GdkScreen *gscreen = gtk_widget_get_screen(widget);
    GdkWindow *groot = gdk_screen_get_root_window(gscreen);
    gdk_window_remove_filter(groot, watch_root_window, NULL);
}

static gboolean __init__ = FALSE;

JS_EXPORT_API
void desktop_emit_webview_ok()
{
    if (!__init__) {
        __init__ = TRUE;
        install_monitor();

        //desktop, dock GSettings
        dock_gsettings = g_settings_new (DOCK_SCHEMA_ID);
        g_signal_connect (dock_gsettings, "changed::hide-mode",
                          G_CALLBACK(dock_config_changed), NULL);
        g_signal_connect (dock_gsettings, "changed::display-mode",
                          G_CALLBACK(dock_config_changed), NULL);

        desktop_gsettings = g_settings_new (DESKTOP_SCHEMA_ID);
        g_signal_connect (desktop_gsettings, "changed::show-computer-icon",
                          G_CALLBACK(desktop_config_changed), NULL);
        g_signal_connect (desktop_gsettings, "changed::show-trash-icon",
                          G_CALLBACK(desktop_config_changed), NULL);
        g_signal_connect(desktop_gsettings, "changed::enabled-plugins",
                         G_CALLBACK(desktop_plugins_changed), NULL);

        setup_root_window_watcher(container, dock_gsettings);
    }
    dock_display_mode_changed(dock_gsettings);
    dde_session_register();
}


