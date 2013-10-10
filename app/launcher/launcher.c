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
#include <string.h>
#include <gtk/gtk.h>
#include <gio/gdesktopappinfo.h>
#include "launcher.h"
#include "xdg_misc.h"
#include "dwebview.h"
#include "dentry/entry.h"
#include "X_misc.h"
#include "i18n.h"
#include "category.h"
#include "launcher_category.h"
#include "background.h"
#include "file_monitor.h"
#include "item.h"
#include "DBUS_launcher.h"

#define DOCK_HEIGHT 30


PRIVATE GKeyFile* launcher_config = NULL;
PRIVATE GtkWidget* container = NULL;
PRIVATE GtkWidget* webview = NULL;
PRIVATE GSettings* dde_bg_g_settings = NULL;
PRIVATE gboolean is_js_already = FALSE;
PRIVATE gboolean is_launcher_shown = FALSE;

#ifndef NDEBUG
static gboolean is_daemonize = FALSE;
static gboolean not_exit = FALSE;
#endif


/**
 * @brief - key: the category id
 *          value: a list of applications id (md5 basename of path)
 */
PRIVATE GHashTable* _category_table = NULL;


PRIVATE
void _do_im_commit(GtkIMContext *context, gchar* str)
{
    JSObjectRef json = json_create();
    json_append_string(json, "Content", str);
    js_post_message("im_commit", json);
}


PRIVATE
void _update_size(GdkScreen *screen, GtkWidget* conntainer)
{
    gtk_widget_set_size_request(container, gdk_screen_width(), gdk_screen_height());
}


PRIVATE
void _on_realize(GtkWidget* container)
{
    GdkScreen* screen =  gdk_screen_get_default();
    _update_size(screen, container);
    g_signal_connect(screen, "size-changed", G_CALLBACK(_update_size), container);
    if (is_js_already)
        background_changed(dde_bg_g_settings, CURRENT_PCITURE, NULL);
}


DBUS_EXPORT_API
void launcher_show()
{
    is_launcher_shown = TRUE;
    GdkWindow* w = gtk_widget_get_window(container);
    gdk_window_show(w);
}


DBUS_EXPORT_API
void launcher_hide()
{
    is_launcher_shown = FALSE;
    GdkWindow* w = gtk_widget_get_window(container);
    gdk_window_hide(w);
}


DBUS_EXPORT_API
void launcher_toggle()
{
    if (is_launcher_shown) {
        launcher_hide();
    } else {
        launcher_show();
    }
}


DBUS_EXPORT_API
void launcher_quit()
{
    destroy_monitors();
    free_resources();
    g_key_file_free(launcher_config);
    g_object_unref(dde_bg_g_settings);
    g_hash_table_destroy(_category_table);
    gtk_main_quit();
}


#ifndef NDEBUG
void empty()
{ }
#endif


JS_EXPORT_API
void launcher_exit_gui()
{
#ifndef NDEBUG
    if (is_daemonize || not_exit) {
#endif

        launcher_hide();

#ifndef NDEBUG
    } else {
        launcher_quit();
    }
#endif
}


JS_EXPORT_API
void launcher_notify_workarea_size()
{
    js_post_message_simply("workarea_changed",
            "{\"x\":0, \"y\":0, \"width\":%d, \"height\":%d}",
            gdk_screen_width(), gdk_screen_height());
}


PRIVATE
void _append_to_category(const char* path, GList* cs)
{
    if (_category_table == NULL) {
        _category_table =
            g_hash_table_new_full(g_direct_hash, g_direct_equal, NULL,
                                  (GDestroyNotify)g_ptr_array_unref);
    }

    GPtrArray* l = NULL;

    for (GList* iter = g_list_first(cs); iter != NULL; iter = g_list_next(iter)) {
        gpointer id = iter->data;
        l = g_hash_table_lookup(_category_table, id);
        if (l == NULL) {
            l = g_ptr_array_new_with_free_func(g_free);
            g_hash_table_insert(_category_table, id, l);
        }

        g_ptr_array_add(l, g_strdup(path));
    }
}


PRIVATE
void _record_category_info(const char* id, GDesktopAppInfo* info)
{
    GList* categories = get_deepin_categories(info);
    _append_to_category(id, categories);
    g_list_free(categories);
}


PRIVATE
JSObjectRef _init_category_table()
{
    JSObjectRef items = json_array_create();
    GList* app_infos = g_app_info_get_all();

    GList* iter = app_infos;
    for (gsize i=0, skip=0; iter != NULL; i++, iter = g_list_next(iter)) {

        GAppInfo* info = iter->data;
        if (!g_app_info_should_show(info)) {
            skip++;
            continue;
        }

        char* id = dentry_get_id(info);
        _record_category_info(id, G_DESKTOP_APP_INFO(info));
        g_free(id);

        json_array_insert_nobject(items, i - skip,
                info, g_object_ref, g_object_unref);

        g_object_unref(info);
    }

    g_list_free(app_infos); //the element of GAppInfo should free by JSRunTime not here!

    return items;
}


JS_EXPORT_API
JSObjectRef launcher_get_items_by_category(double _id)
{
    int id = _id;
    if (id == ALL_CATEGORY_ID)
        return _init_category_table();

    JSObjectRef items = json_array_create();

    GPtrArray* l = g_hash_table_lookup(_category_table, GINT_TO_POINTER(id));
    if (l == NULL) {
        return items;
    }

    JSContextRef cxt = get_global_context();
    for (int i = 0; i < l->len; ++i) {
        const char* path = g_ptr_array_index(l, i);
        json_array_insert(items, i, jsvalue_from_cstr(cxt, path));
    }

    return items;
}


PRIVATE
gboolean _pred(const gchar* lhs, const gchar* rhs)
{
    return g_strrstr(lhs, rhs) != NULL;
}


typedef gboolean (*Prediction)(const gchar*, const gchar*);


PRIVATE
double _get_weight(const char* src, const char* key, Prediction pred, double weight)
{
    if (src == NULL) {
        return 0.0;
    }

    char* k = g_utf8_casefold(src, -1);
    double ret = pred(k, key) ? weight : 0.0;
    g_free(k);
    return ret;
}

#define FILENAME_WEIGHT 0.3
#define GENERIC_NAME_WEIGHT 0.01
#define KEYWORD_WEIGHT 0.1
#define CATEGORY_WEIGHT 0.01
#define NAME_WEIGHT 0.01
#define DISPLAY_NAME_WEIGHT 0.1
#define DESCRIPTION_WEIGHT 0.01
#define EXECUTABLE_WEIGHT 0.05

JS_EXPORT_API
double launcher_is_contain_key(GDesktopAppInfo* info, const char* key)
{
    double weight = 0.0;

    /* desktop file information */
    const char* path = g_desktop_app_info_get_filename(info);
    char* basename = g_path_get_basename(path);
    *strchr(basename, '.') = '\0';
    weight += _get_weight(basename, key, _pred, FILENAME_WEIGHT);
    g_free(basename);

    const char* gname = g_desktop_app_info_get_generic_name(info);
    weight += _get_weight(gname, key, _pred, GENERIC_NAME_WEIGHT);

    const char* const* keys = g_desktop_app_info_get_keywords(info);
    if (keys != NULL) {
        size_t n = g_strv_length((char**)keys);
        for (size_t i=0; i<n; i++) {
            weight += _get_weight(keys[i], key, _pred, KEYWORD_WEIGHT);
        }
    }

    const char* categories = g_desktop_app_info_get_categories(info);
    if (categories) {
        gchar** category_names = g_strsplit(categories, ";", -1);
        gsize len = g_strv_length(category_names) - 1;
        for (gsize i = 0; i < len; ++i) {
            weight += _get_weight(category_names[i], key, _pred, CATEGORY_WEIGHT);
        }
        g_strfreev(category_names);
    }

    /* application information */
    const char* name = g_app_info_get_name((GAppInfo*)info);
    weight += _get_weight(name, key, _pred, NAME_WEIGHT);

    const char* dname = g_app_info_get_display_name((GAppInfo*)info);
    weight += _get_weight(dname, key, _pred, DISPLAY_NAME_WEIGHT);

    const char* desc = g_app_info_get_description((GAppInfo*)info);
    weight += _get_weight(desc, key, _pred, DESCRIPTION_WEIGHT);

    const char* exec = g_app_info_get_executable((GAppInfo*)info);
    weight += _get_weight(exec, key, _pred, EXECUTABLE_WEIGHT);

    return weight;
}


PRIVATE
void _insert_category(JSObjectRef categories, int array_index, int id, const char* name)
{
    JSObjectRef item = json_create();
    json_append_number(item, "ID", id);
    json_append_string(item, "Name", name);
    json_array_insert(categories, array_index, item);
}


PRIVATE
void _record_categories(JSObjectRef categories, const char* names[], int num)
{
    int index = 1;
    for (int i = 0; i < num; ++i) {
        if (g_hash_table_lookup(_category_table, GINT_TO_POINTER(i)))
            _insert_category(categories, index++, i, names[i]);
    }

    if (g_hash_table_lookup(_category_table, GINT_TO_POINTER(OTHER_CATEGORY_ID))) {
        int other_category_id = num - 1;
        _insert_category(categories, index, OTHER_CATEGORY_ID, names[other_category_id]);
    }
}


JS_EXPORT_API
JSObjectRef launcher_get_categories()
{
    JSObjectRef categories = json_array_create();

    _insert_category(categories, 0, ALL_CATEGORY_ID, ALL);

    const char* names[] = {
        INTERNET, MULTIMEDIA, GAMES, GRAPHICS, PRODUCTIVITY,
        INDUSTRY, EDUCATION, DEVELOPMENT, SYSTEM, UTILITIES,
        OTHER
    };

    int category_num = 0;
    const GPtrArray* infos = get_all_categories_array();

    if (infos == NULL) {
        category_num = G_N_ELEMENTS(names);
    } else {
        category_num = infos->len;
        for (int i = 0; i < category_num; ++i) {
            char* name = g_ptr_array_index(infos, i);

            extern int find_category_id(const char* category_name);
            int id = find_category_id(name);
            int index = id == OTHER_CATEGORY_ID ? category_num - 1 : id;

            names[index] = name;
        }
    }

    _record_categories(categories, names, category_num);
    return categories;
}


JS_EXPORT_API
GFile* launcher_get_desktop_entry()
{
    return g_file_new_for_path(DESKTOP_DIR());
}


JS_EXPORT_API
void launcher_webview_ok()
{
    background_changed(dde_bg_g_settings, CURRENT_PCITURE, NULL);
    is_js_already = TRUE;
}


PRIVATE
void daemonize()
{
    g_debug("daemonize");
    pid_t pid = 0;
    if ((pid = fork()) == -1) {
        g_warning("fork error");
        exit(0);
    } else if (pid != 0){
        exit(0);
    }

    setsid();

    if ((pid = fork()) == -1) {
        g_warning("fork error");
        exit(0);
    } else if (pid != 0){
        exit(0);
    }
}


JS_EXPORT_API
void launcher_clear()
{
    webkit_web_view_reload_bypass_cache((WebKitWebView*)webview);
}


void check_version()
{
    if (launcher_config == NULL)
        launcher_config = load_app_config(LAUNCHER_CONF);

    GError* err = NULL;
    gchar* version = g_key_file_get_string(launcher_config, "main", "version", &err);
    if (err != NULL) {
        g_warning("[%s] read version failed from config file: %s", __func__, err->message);
        g_error_free(err);
        g_key_file_set_string(launcher_config, "main", "version", LAUNCHER_VERSION);
        save_app_config(launcher_config, LAUNCHER_CONF);
    }

    if (version != NULL)
        g_free(version);
}


int main(int argc, char* argv[])
{
    if (argc == 2 && g_str_equal("-d", argv[1]))
        g_setenv("G_MESSAGES_DEBUG", "all", FALSE);

#ifndef NDEBUG
    if (argc == 2 && g_str_equal("-D", argv[1]))
        is_daemonize = TRUE;

    if (argc == 2 && g_str_equal("-f", argv[1])) {
        not_exit = TRUE;
    }
#endif

    if (is_application_running("launcher.app.deepin")) {
        g_warning(_("another instance of launcher is running...\n"));
        dbus_launcher_toggle();
        return 0;
    }

    signal(SIGKILL, launcher_quit);
    signal(SIGTERM, launcher_quit);

#ifndef NDEBUG
    if (is_daemonize)
#endif
        daemonize();

    check_version();

    init_i18n();
    gtk_init(&argc, &argv);
    container = create_web_container(FALSE, TRUE);
    gtk_window_set_decorated(GTK_WINDOW(container), FALSE);
    gtk_window_set_wmclass(GTK_WINDOW(container), "dde-launcher", "DDELauncher");

    set_default_theme("Deepin");
    set_desktop_env_name("Deepin");

    webview = d_webview_new_with_uri(GET_HTML_PATH("launcher"));

    gtk_container_add(GTK_CONTAINER(container), GTK_WIDGET(webview));

    g_signal_connect(container, "realize", G_CALLBACK(_on_realize), NULL);
    g_signal_connect (container, "destroy", G_CALLBACK(gtk_main_quit), NULL);
#ifndef NDEBUG
    g_signal_connect(container, "delete-event", G_CALLBACK(empty), NULL);
#endif
    dde_bg_g_settings = g_settings_new(SCHEMA_ID);
    g_signal_connect(dde_bg_g_settings, "changed::"CURRENT_PCITURE,
                     G_CALLBACK(background_changed), NULL);

    gtk_widget_realize(container);
    gtk_widget_realize(webview);

    GdkWindow* gdkwindow = gtk_widget_get_window(container);
    GdkRGBA rgba = {0, 0, 0, 0.0 };
    gdk_window_set_background_rgba(gdkwindow, &rgba);
    set_launcher_background(gtk_widget_get_window(webview), dde_bg_g_settings,
                            gdk_screen_width(), gdk_screen_height());

    gdk_window_set_skip_taskbar_hint(gdkwindow, TRUE);
    gdk_window_set_skip_pager_hint(gdkwindow, TRUE);

    GtkIMContext* im_context = gtk_im_multicontext_new();
    gtk_im_context_set_client_window(im_context, gdkwindow);
    GdkRectangle area = {0, 1700, 100, 30};
    gtk_im_context_set_cursor_location(im_context, &area);
    gtk_im_context_focus_in(im_context);
    g_signal_connect(im_context, "commit", G_CALLBACK(_do_im_commit), NULL);

    setup_launcher_dbus_service();

#ifndef NDEBUG
    monitor_resource_file("launcher", webview);
#endif

    add_monitors();
    gtk_widget_show_all(container);
    is_launcher_shown = TRUE;
    gtk_main();
    destroy_monitors();
    return 0;
}

