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
#include "utils.h"
#include "X_misc.h"
#include "i18n.h"
#include "category.h"
#include <gio/gdesktopappinfo.h>


gboolean prevent_exit(GtkWidget* w, GdkEvent* e)
{
    return TRUE;
}

GtkWidget* container = NULL;
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
    gtk_widget_realize(container);

    set_default_theme("Deepin");
    set_desktop_env_name("GNOME");

    GtkWidget *webview = d_webview_new_with_uri(GET_HTML_PATH("launcher"));

    gtk_window_set_skip_pager_hint(GTK_WINDOW(container), TRUE);
    gtk_container_add(GTK_CONTAINER(container), GTK_WIDGET(webview));


    g_signal_connect (container , "destroy", G_CALLBACK (gtk_main_quit), NULL);

    gtk_window_maximize(GTK_WINDOW(container));

    gtk_widget_realize(container);
    GdkRGBA rgba = { 0, 0, 0, 0.0 };
    gdk_window_set_background_rgba(gtk_widget_get_window(container), &rgba);
    watch_workarea_changes(container);
    gtk_widget_show_all(container);
    gtk_main();
    /*unwatch_workarea_changes(w);*/
    return 0;
}

void exit_gui()
{
    gtk_main_quit();
}

void notify_workarea_size()
{
    int x, y, width, height;
    get_workarea_size(0, 0, &x, &y, &width, &height);
    char* tmp = g_strdup_printf("{\"x\":%d, \"y\":%d, \"width\":%d, \"height\":%d}", x, y, width, height);
    js_post_message("workarea_changed", tmp);
    GtkAllocation alloc = {x, y, width, height};
    gtk_widget_size_allocate(container, &alloc);
    /*gtk_window_resize(GTK_WINDOW(container), width, height);*/
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

//JS_EXPORT
char* get_items_by_category(double _id)
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

//JS_EXPORT
JSObjectRef get_items()
{
    JSObjectRef json = json_array_create();

    GList* app_infos = g_app_info_get_all();
    GList* iter = app_infos;
    for (gsize i=0; iter != NULL; i++, iter = g_list_next(iter)) {
        GAppInfo* info = iter->data;
        record_category_info(g_app_info_get_id(info), G_DESKTOP_APP_INFO(info));

        JSObjectRef item = json_create();
        json_append_nobject(item, "Core", info, g_object_unref);
        json_append_string(item, "ID", g_app_info_get_id(info));
        json_append_string(item, "Name", g_app_info_get_display_name(info));

        GIcon* icon = g_app_info_get_icon(info);
        if (icon != NULL) {
            char* icon_str = g_icon_to_string(icon);
            char* icon_path = icon_name_to_path(icon_str, 48);
            json_append_string(item, "Icon", icon_path);
            g_free(icon_path);
            g_free(icon_str);
        } else {
            json_append_string(item, "Icon", "");
        }

        json_array_append(json, i, item);
    }

    g_list_free(app_infos); //the element of GAppInfo should free by JSRunTime not here!

    return json;
}

//JS_EXPORT
char* get_categories()
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
