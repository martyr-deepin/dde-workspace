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
#include "category.h"
#include <stdlib.h>
#include <glib.h>
#include "sqlite3.h"


void gen_item_info(char* path, GString* string)
{
    g_string_append_printf(string, "\"%s\",", path);
}
char* get_deepin_categories(const char* path, char** xdg_categories)
{
    return g_strdup("[1]");
}


void add_item_to_cateogry(const char* path, int cat_id)
{
    /*if (categorys[cat_id] == NULL) {*/
        /*categorys[cat_id] = g_hash_table_new_full(g_str_hash, g_str_equal, g_free, NULL);*/
    /*}*/
    /*GHashTable* c = categorys[cat_id];*/
    /*if (!g_hash_table_lookup(c, path)) {*/
        /*g_hash_table_insert(c, g_strdup(path), GINT_TO_POINTER(1));*/
    /*}*/
}

//JS_EXPORT
char* get_items_by_category(double _id)
{
    return g_strdup("[]");
    /*int id = (int)_id;*/
    /*GHashTable* c = categorys[id];*/
    /*if (c != NULL) {*/
        /*GList* items = g_hash_table_get_keys(c);*/
        /*GString *string = g_string_new("[");*/
        /*g_list_foreach(items, (GFunc)gen_item_info, string);*/
        /*g_string_overwrite(string, string->len-1, "]");*/
        /*g_list_free(items);*/
        /*return g_string_free(string, FALSE);*/
    /*} else {*/
        /*return g_strdup("[]");*/
    /*}*/
}



const char* _gen_category_info_str(GArray* infos)
{
    if (infos == NULL) {
        return "["
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
        "}]";
    } else {
        static GString* info_str = NULL;
        if (info_str == NULL) {
            info_str = g_string_new("[");
            for (int i=0; i<infos->len; i++) {
                char* v = g_array_index(infos, char*, i);
                g_string_append_printf(info_str, "{\"ID\":%d, \"Name\":\"%s\"},", i, v);
            }
            g_string_overwrite(info_str, info_str->len - 1, "]");
            g_array_free(infos, FALSE); //TODO: why can't free element memory?
        }
        return info_str->str;
    }
}


int _fill_category_info(GArray* infos, int argc, char** argv, char** colname)
{
    char* value = g_strdup(argv[1]);
    g_array_append_val(infos, value);
    return 0;
}
gboolean _load_category_info(const char* db_path, GArray* category_infos)
{
    const char* sql_category_info = "select distinct first_category_index, first_category_name from category_name group by first_category_index;";
    sqlite3 *db = NULL;
    if (SQLITE_OK == sqlite3_open_v2(db_path, &db, SQLITE_OPEN_READONLY, NULL)) {
        g_assert(db != NULL);
        char* error = NULL;
        sqlite3_exec(db, sql_category_info, _fill_category_info, category_infos, &error);
        if (error != NULL) {
            g_warning("load_category_info failed %s\n", error);
            sqlite3_free(error);
            sqlite3_close(db);
            return FALSE;
        }
        sqlite3_close(db);
        return TRUE;
    } else {
        return FALSE;
    }
}
//JS_EXPORT
char* get_categories()
{
    static GArray* category_infos = NULL;
    if (category_infos == NULL) {
        category_infos = g_array_new(FALSE, FALSE, sizeof(char*));
        g_array_set_clear_func(category_infos, g_free);
        if (!_load_category_info(DESKTOP_DB_PATH, category_infos)) {
            g_array_free(category_infos, FALSE);
            category_infos = NULL;
        }
    }
    return g_strdup(_gen_category_info_str(category_infos));
}

