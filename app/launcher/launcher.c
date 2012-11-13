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

    char* path = get_html_path("launcher");
    GtkWidget *webview = d_webview_new_with_uri(path);
    g_free(path);

    gtk_window_set_skip_pager_hint(GTK_WINDOW(container), TRUE);
    gtk_container_add(GTK_CONTAINER(container), GTK_WIDGET(webview));


    g_signal_connect (container , "destroy", G_CALLBACK (gtk_main_quit), NULL);

    gtk_window_maximize(GTK_WINDOW(container));

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

GHashTable* _category_table = NULL;
void append_to_category(const char* path, char** cs)
{
    if (cs == NULL) //TODO add to default other category
    {
        printf("%s hasn't categories info\n", path);
        return;
    }

    if (_category_table == NULL) {
        //TODO new_with_full
        _category_table = g_hash_table_new(g_direct_hash, g_direct_equal);
    }
    while (*cs != NULL) {
        gpointer id = GINT_TO_POINTER((int)g_strtod(*cs, NULL));
        GPtrArray* l = g_hash_table_lookup(_category_table, id);
        if (l == NULL) {
            l = g_ptr_array_new_with_free_func(g_free);
            g_hash_table_insert(_category_table, id, l);
        }
        g_ptr_array_add(l, g_strdup(path));


        cs++;
    }
}


#include <glib/gprintf.h>
void parse_items(GString *str, const char* root)
{
    GDir *dir = g_dir_open(root, 0, NULL);
    if (dir == NULL)
        return;

    const char *filename = NULL;
    char path[500];
    while ((filename = g_dir_read_name(dir)) != NULL) {
        if (!only_desktop(filename))
            continue;
        g_sprintf(path, "%s/%s", root, filename);
        BaseEntry* entry = parse_desktop_entry(path);
        if (entry == NULL)
            continue;

        char* c = ((ApplicationEntry*)entry)->categories;
        char** cs = g_strsplit(c, ";", -1);
        append_to_category(entry->entry_path, cs);
        g_strfreev(cs);

        // append to category entry

        char* info = entry_info_to_json(entry);
        g_string_append(str, info);
        g_string_append_c(str, ',');
        g_free(info);

        desktop_entry_free(entry);
    }
    g_dir_close(dir);
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

//JS_EXPORT
char* get_items()
{
    static GString* content = NULL;
    if (content == NULL) {
        content = g_string_new("[");
        //TODO use g_get_user_data_dir()
        parse_items(content, "/usr/share/applications");
        parse_items(content, "/usr/local/share/applications");
        parse_items(content, "~/.local/share/applications");
        g_string_overwrite(content, content->len-1, "]");
    }
    return g_strdup(content->str);
}


const char* _gen_category_info_str(GPtrArray* infos)
{
    if (infos == NULL) {
    } else {
        static GString* info_str = NULL;
        if (info_str == NULL) {
            info_str = g_string_new("[");
            for (int i=0; i<infos->len; i++) {
                char* v = g_ptr_array_index(infos, i);
                g_string_append_printf(info_str, "{\"ID\":%d, \"Name\":\"%s\"},", i, v);
            }
            g_string_overwrite(info_str, info_str->len - 1, "]");
            g_ptr_array_free(infos, TRUE); //TODO: why can't free element memory?
        }
        return info_str->str;
    }
}

//JS_EXPORT
char* get_categories()
{
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

    g_string_overwrite(info_str, info_str->len - 1, "]");
    return info_str->str;
}
