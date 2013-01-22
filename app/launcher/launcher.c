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


gboolean prevent_exit(GtkWidget* w, GdkEvent* e)
{
    return TRUE;
}

GtkWidget* container = NULL;

void _make_maximize()
{

}

gboolean draw_bg(GtkWidget* w, cairo_t* cr)
{
    char* bg_path = g_build_filename(g_get_tmp_dir(), ".deepin_background_gaussian.png", NULL);
    cairo_surface_t* _background = cairo_image_surface_create_from_png(bg_path);
    g_free(bg_path);

    if (cairo_surface_status(_background) == CAIRO_STATUS_SUCCESS) {
        cairo_set_source_surface(cr, _background, 0, 0);
        cairo_paint(cr);
    } else {
        cairo_set_operator(cr, CAIRO_OPERATOR_CLEAR);
        cairo_paint(cr);
    }
    cairo_surface_destroy(_background);
    return FALSE;
}

void do_im_commit(GtkIMContext *context, gchar* str)
{
    JSObjectRef json = json_create();
    json_append_string(json, "Content", str);
    js_post_message("im_commit", json);
}

void update_size(GdkScreen *screen, GtkWidget* conntainer)
{
    gtk_widget_set_size_request(container, gdk_screen_get_width(screen), gdk_screen_get_height(screen));
}

void on_realize(GtkWidget* container)
{

    GdkScreen* screen = gdk_screen_get_default();
    update_size(screen, container);
    g_signal_connect(screen, "size-changed", G_CALLBACK(update_size), container);
}

gboolean do_lost_focus(GtkWidget  *widget, GdkEventAny *event)
{
    JSObjectRef json = json_create();
    json_append_number(json, "xid", (double)GDK_WINDOW_XID(event->window));
    /*js_post_message("lost_focus", json);*/
}

int main(int argc, char* argv[])
{
    if (is_application_running("launcher.app.deepin")) {
        g_warning("anther instance of application launcher is running...\n");
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

    g_signal_connect(container, "realize", G_CALLBACK(on_realize), NULL);
    g_signal_connect(webview, "draw", G_CALLBACK(draw_bg), NULL);
    g_signal_connect(webview, "focus-out-event", G_CALLBACK(do_lost_focus), NULL);
    g_signal_connect (container, "destroy", G_CALLBACK (gtk_main_quit), NULL);

    gtk_widget_realize(container);
    GdkWindow* gdkwindow = gtk_widget_get_window(container);
    GdkRGBA rgba = { 0, 0, 0, 0.0 };
    gdk_window_set_background_rgba(gdkwindow, &rgba);

    gdk_window_set_skip_taskbar_hint(gdkwindow, TRUE);

    GtkIMContext* im_context = gtk_im_multicontext_new();
    gtk_im_context_set_client_window(im_context, gdkwindow);
    GdkRectangle area = {0, 1700, 100, 30};
    gtk_im_context_set_cursor_location(im_context, &area);
    gtk_im_context_focus_in(im_context);
    g_signal_connect(im_context, "commit", G_CALLBACK(do_im_commit), NULL); 

    /*monitor_resource_file("launcher", webview);*/
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
void append_to_category(const char* path, int* cs)
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

void fill_cat(char* path, GString* content)
{
    g_string_append_printf(content, "\"%s\",", path);
}

JS_EXPORT_API
char* launcher_get_items_by_category(double _id)
{
    int id = _id;
    GPtrArray* l = g_hash_table_lookup(_category_table, GINT_TO_POINTER(id));
    if (l == NULL)
        return g_strdup("[]");
    GString* content = g_string_new("[");
    g_ptr_array_foreach(l, (GFunc)fill_cat, content);
    g_string_overwrite(content, content->len-1, "]");
    return g_string_free(content, FALSE);
}

static
void record_category_info(const char* id, GDesktopAppInfo* info)
{
   int* cs = get_deepin_categories(g_desktop_app_info_get_categories(info));
   append_to_category(id, cs);
   g_free(cs);
   /*printf("%s get %s\n", id, c);*/
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
        record_category_info(id, G_DESKTOP_APP_INFO(info));
        g_free(id);

        json_array_append_nobject(items, i - skip, 
                info, g_object_ref, g_object_unref);

        g_object_unref(info);
    }

    g_list_free(app_infos); //the element of GAppInfo should free by JSRunTime not here!

    return items;
}

JS_EXPORT_API
gboolean launcher_is_contain_key(GDesktopAppInfo* info, const char* key)
{
    const char* path = g_desktop_app_info_get_filename(info);
    if (g_strrstr(path, key))
        return TRUE;

    const char* name = g_app_info_get_name((GAppInfo*)info);
    if (name && g_strrstr(name, key))
        return TRUE;

    const char* dname = g_app_info_get_display_name((GAppInfo*)info);
    if (dname && g_strrstr(dname, key))
        return TRUE;

    const char* desc = g_app_info_get_description((GAppInfo*)info);
    if (desc && g_strrstr(desc, key))
        return TRUE;

    const char* exec = g_app_info_get_executable((GAppInfo*)info);
    if (exec && g_strrstr(exec, key))
        return TRUE;

    const char* gname = g_desktop_app_info_get_generic_name(info);
    if (gname && g_strrstr(gname, key))
        return TRUE;

    const char* const* keys = g_desktop_app_info_get_keywords(info);
    if (keys != NULL) {
        size_t n = g_strv_length((char**)keys);
        for (size_t i=0; i<n; i++) {
            if (g_strrstr(keys[i], key))
                return TRUE;
        }
    }

    return FALSE;
}

JS_EXPORT_API
char* launcher_get_categories()
{
    /*return g_strdup("[]");*/
    GString* info_str = NULL;
    info_str = g_string_new("[");

    const GPtrArray* infos = get_all_categories_array();
    if (infos == NULL) {
        return g_strdup("["
        "{\"ID\": 0,"
        " \"Name\": \"Internet\""
        "},"
        "{\"ID\": 1,"
        " \"Name\": \"Media\""
        "},"
        "{\"ID\": 2,"
        " \"Name\": \"Game\""
        "},"
        "{\"ID\": 3,"
        " \"Name\": \"Graphics\""
        "},"
        "{\"ID\": 4,"
        " \"Name\": \"Office\""
        "},"
        "{\"ID\": 5,"
        " \"Name\": \"Industry\""
        "},"
        "{\"ID\": 6,"
        " \"Name\": \"Education\""
        "},"
        "{\"ID\": 7,"
        " \"Name\": \"Development\""
        "},"
        "{\"ID\": 8,"
        " \"Name\": \"Wine\""
        "},"
        "{\"ID\": 9,"
        " \"Name\": \"General\""
        "},"
        "{\"ID\": 10,"
        " \"Name\": \"Other\""
        "}]");
    }
    for (int i=0; i<infos->len; i++) {
        if (g_hash_table_lookup(_category_table, GINT_TO_POINTER(i)))
            g_string_append_printf(info_str, "{\"ID\":%d, \"Name\":\"%s\"},", i, (char*)g_ptr_array_index(infos, i));
    }

    if (info_str->len > 1) {
        g_string_overwrite(info_str, info_str->len - 1, "]");
        return g_string_free(info_str, FALSE);
    } else {
        g_string_free(info_str, TRUE);
        return g_strdup("[]");
    }
}

GFile* launcher_get_desktop_entry()
{
    char* desktop = get_desktop_dir(FALSE);
    GFile* r = g_file_new_for_path(desktop);
    g_free(desktop);
    return r;
}
