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
#include "xdg_misc.h"
#include <gtk/gtk.h>
#include "dwebview.h"
#include "dentry/entry.h"
#include "utils.h"
#include "X_misc.h"
#include "i18n.h"
#include "category.h"
#include <gio/gdesktopappinfo.h>
#define DOCK_HEIGHT 30


static
GtkWidget* container = NULL;

static
void _set_launcher_background(GdkWindow* win)
{
    char* bg_path = g_build_filename(g_get_tmp_dir(), ".deepin_background_gaussian.png", NULL);
    cairo_surface_t* _background = cairo_image_surface_create_from_png(bg_path);
    g_free(bg_path);

    if (cairo_surface_status(_background) == CAIRO_STATUS_SUCCESS) {
        cairo_pattern_t* pt = cairo_pattern_create_for_surface(_background);
        gdk_window_hide(win);
        gdk_window_set_background_pattern(win, pt);
        gdk_window_show(win);
    } else {
        g_assert_not_reached();
    }
    cairo_surface_destroy(_background);
}

static
void _do_im_commit(GtkIMContext *context, gchar* str)
{
    JSObjectRef json = json_create();
    json_append_string(json, "Content", str);
    js_post_message("im_commit", json);
}

static
void _update_size(GdkScreen *screen, GtkWidget* conntainer)
{
    gtk_widget_set_size_request(container, gdk_screen_get_width(screen), gdk_screen_get_height(screen));
}

static
void _on_realize(GtkWidget* container)
{
    GdkScreen* screen = gdk_screen_get_default();
    _update_size(screen, container);
    g_signal_connect(screen, "size-changed", G_CALLBACK(_update_size), container);
}

int main(int argc, char* argv[])
{
    if (is_application_running("launcher.app.deepin")) {
        g_warning("another instance of application launcher is running...\n");
        return 0;
    }

    init_i18n();
    gtk_init(&argc, &argv);
    container = create_web_container(FALSE, TRUE);
    gtk_window_set_decorated(GTK_WINDOW(container), FALSE);
    gtk_window_set_wmclass(GTK_WINDOW(container), "dde-launcher", "DDELauncher");

    set_default_theme("Deepin");
    set_desktop_env_name("Deepin");

    GtkWidget *webview = d_webview_new_with_uri(GET_HTML_PATH("launcher"));

    gtk_container_add(GTK_CONTAINER(container), GTK_WIDGET(webview));

    g_signal_connect(container, "realize", G_CALLBACK(_on_realize), NULL);
    g_signal_connect (container, "destroy", G_CALLBACK(gtk_main_quit), NULL);

    gtk_widget_realize(container);
    gtk_widget_realize(webview);

    _set_launcher_background(gtk_widget_get_window(webview));

    GdkWindow* gdkwindow = gtk_widget_get_window(container);
    GdkRGBA rgba = {0, 0, 0, 0.0 };
    gdk_window_set_background_rgba(gdkwindow, &rgba);

    gdk_window_set_skip_taskbar_hint(gdkwindow, TRUE);

    GtkIMContext* im_context = gtk_im_multicontext_new();
    gtk_im_context_set_client_window(im_context, gdkwindow);
    GdkRectangle area = {0, 1700, 100, 30};
    gtk_im_context_set_cursor_location(im_context, &area);
    gtk_im_context_focus_in(im_context);
    g_signal_connect(im_context, "commit", G_CALLBACK(_do_im_commit), NULL);

    /* monitor_resource_file("launcher", webview); */
    gtk_widget_show_all(container);
    gtk_main();
    return 0;
}

JS_EXPORT_API
void launcher_exit_gui()
{
    gtk_main_quit();
}

JS_EXPORT_API
void launcher_notify_workarea_size()
{
    GdkScreen* screen = gdk_screen_get_default();
    js_post_message_simply("workarea_changed",
            "{\"x\":0, \"y\":0, \"width\":%d, \"height\":%d}",
            gdk_screen_get_width(screen),
            gdk_screen_get_height(screen)
            );
}

static GHashTable* _category_table = NULL;

static
void _append_to_category(const char* path, int* cs)
{
    if (cs == NULL) {
        //TODO add to default other category
        g_debug("%s hasn't categories info\n", path);
        return;
    }

    if (_category_table == NULL) {
        //TODO new_with_full
        _category_table = g_hash_table_new(g_direct_hash, g_direct_equal);
    }

    while (*cs != CATEGORY_END_TAG) {
        gpointer id = GINT_TO_POINTER(*cs);
        GPtrArray* l = g_hash_table_lookup(_category_table, id);
        if (l == NULL) {
            l = g_ptr_array_new_with_free_func(g_free);
            g_hash_table_insert(_category_table, id, l);
        }
        g_ptr_array_add(l, g_strdup(path));

        cs++;
    }
}

JS_EXPORT_API
JSObjectRef launcher_get_items_by_category(double _id)
{
    JSObjectRef items = json_array_create();

    int id = _id;
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

static
void _record_category_info(const char* id, GDesktopAppInfo* info)
{
   int* cs = get_deepin_categories(g_desktop_app_info_get_categories(info));
   _append_to_category(id, cs);
   g_free(cs);
}

JS_EXPORT_API
JSObjectRef launcher_get_items()
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
double launcher_is_contain_key(GDesktopAppInfo* info, const char* key)
{
    double weight = 0.0;

    /* desktop file information */
    const char* path = g_desktop_app_info_get_filename(info);
    if (g_strrstr(path, key)) {
        weight += 0.3;
    }

    const char* gname = g_desktop_app_info_get_generic_name(info);
    if (gname && g_strrstr(gname, key)) {
        weight += 0.01;
    }

    const char* const* keys = g_desktop_app_info_get_keywords(info);
    if (keys != NULL) {
        size_t n = g_strv_length((char**)keys);
        for (size_t i=0; i<n; i++) {
            if (g_strrstr(keys[i], key)) {
                weight += 0.1;
            }
        }
    }

    const char* categories = g_desktop_app_info_get_categories(info);
    if (categories && g_strrstr(categories, key)) {
        weight += 0.01;
    }

    /* application information */
    const char* name = g_app_info_get_name((GAppInfo*)info);
    if (name && g_strrstr(name, key)) {
        weight += 0.1;
    }

    const char* dname = g_app_info_get_display_name((GAppInfo*)info);
    if (dname && g_strrstr(dname, key)) {
        weight += 0.05;
    }

    const char* desc = g_app_info_get_description((GAppInfo*)info);
    if (desc && g_strrstr(desc, key)) {
        weight += 0.01;
    }

    const char* exec = g_app_info_get_executable((GAppInfo*)info);
    if (exec && g_strrstr(exec, key)) {
        weight += 0.05;
    }

    return weight;
}

static
void print(gpointer data, gpointer user_data)
{
    printf("%s\n", (const char*)data);
}

JS_EXPORT_API
JSObjectRef launcher_get_categories()
{
    JSContextRef cxt = get_global_context();
    JSObjectRef categories = json_array_create();

    const GPtrArray* infos = get_all_categories_array();
    if (infos == NULL) {
        const char* names[] = {"Internet", "Media", "Game", "Graphics", "Office",
            "Industry", "Education", "Development", "Wine", "General", "Other"};
        const int category_num = sizeof(names) / sizeof(const char*);

        for (int i = 0; i < category_num; ++i) {
            JSObjectRef item = json_create();
            json_append_number(item, "ID", i);
            json_append_string(item, "Name", names[i]);
            json_array_insert(categories, i, item);
        }
        return categories;
    }

    for (int i=0, j = 0; i < infos->len; i++) {
        if (g_hash_table_lookup(_category_table, GINT_TO_POINTER(i))) {
            const char* category_name = (const char*)g_ptr_array_index(infos, i);
            JSObjectRef item = json_create();
            json_append_number(item, "ID", i);
            json_append_string(item, "Name", category_name);
            json_array_insert(categories, j++, item);
        }
    }

    return categories;
}

JS_EXPORT_API
GFile* launcher_get_desktop_entry()
{
    char* desktop = get_desktop_dir(FALSE);
    GFile* r = g_file_new_for_path(desktop);
    g_free(desktop);
    return r;
}

