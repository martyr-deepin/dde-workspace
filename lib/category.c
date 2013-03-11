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

typedef int (*SQLEXEC_CB) (void*, int, char**, char**);

const char* get_cateogry_db_path()
{
    return DATA_DIR"/category-zh_CN.db";
}

int _fill_category_info_id(GHashTable* infos, int argc, char** argv, char** colname)
{
    g_assert(argc == 2);
    g_hash_table_insert(infos, g_strdup(argv[0]), GINT_TO_POINTER(((int)g_strtod(argv[1], NULL))));
    return 0;
}

int find_category_id(char* s)
{
    static GHashTable* _c_info = NULL;
    if (_c_info == NULL) {
        /*----------init------*/
        _c_info = g_hash_table_new_full(g_str_hash, g_str_equal, g_free, NULL);
        const char* sql = "select x_category_name, first_category_index from category;";
        sqlite3 *db = NULL;
        if (SQLITE_OK == sqlite3_open_v2(get_cateogry_db_path(), &db, SQLITE_OPEN_READONLY, NULL)) {
            char* error = NULL;
            sqlite3_exec(db, sql, (SQLEXEC_CB)_fill_category_info_id, _c_info, &error);
            if (error != NULL) {
                g_warning("fetch category info failed %s\n", error);
                sqlite3_free(error);
            }
            sqlite3_close(db);
        } 
    }

    /*---------------begin-----------*/
    int id = -1;
    char* key = g_utf8_casefold(s, -1);
    gpointer tmp = g_hash_table_lookup(_c_info, key);
    g_free(key);
    if (tmp != NULL)
        id = GPOINTER_TO_INT(tmp);
    return id;
}

int* get_deepin_categories(const char* c)
{
    if (c == NULL) return NULL;

    char** cs = g_strsplit(c, ";", -1);
    g_assert(cs != NULL);
    gsize len = g_strv_length(cs);
    int *ret = g_new(int, len+1);
    for (gsize i=0; i<len; i++) {
        ret[i] = find_category_id(cs[i]);
    }
    g_strfreev(cs);
    ret[len] = CATEGORY_END_TAG;

    return ret;

    /*GString* content = g_string_new("");*/
    /*while (*cs != NULL) {*/
        /*g_string_append_printf(content, "%d;", find_category_id(*cs));*/
        /*cs++;*/
    /*}*/
    /*return g_string_free(content, FALSE);*/
}

int _fill_category_info(GPtrArray* infos, int argc, char** argv, char** colname)
{
    g_ptr_array_add(infos, g_strdup(argv[1]));
    return 0;
}

void _load_category_info(GPtrArray* category_infos)
{
    const char* sql_category_info = "select distinct first_category_index, first_category_name from category_name group by first_category_index;";
    sqlite3 *db = NULL;
    if (SQLITE_OK == sqlite3_open_v2(get_cateogry_db_path(), &db, SQLITE_OPEN_READONLY, NULL)) {
        g_assert(db != NULL);
        char* error = NULL;
        sqlite3_exec(db, sql_category_info, (SQLEXEC_CB)_fill_category_info, category_infos, &error);
        if (error != NULL) {
            g_warning("load_category_info failed %s\n", error);
            sqlite3_free(error);
            sqlite3_close(db);
        }
        sqlite3_close(db);
    } else {
        g_ptr_array_add(category_infos, g_strdup("Internet"));
        g_ptr_array_add(category_infos, g_strdup("Media"));
        g_ptr_array_add(category_infos, g_strdup("Game"));
        g_ptr_array_add(category_infos, g_strdup("Graphics"));
        g_ptr_array_add(category_infos, g_strdup("Office"));
        g_ptr_array_add(category_infos, g_strdup("Industry"));
        g_ptr_array_add(category_infos, g_strdup("Education"));
        g_ptr_array_add(category_infos, g_strdup("Development"));
        g_ptr_array_add(category_infos, g_strdup("General"));
        g_ptr_array_add(category_infos, g_strdup("Other"));
    }
}

const GPtrArray* get_all_categories_array()
{
    static GPtrArray* category_infos = NULL;
    if (category_infos == NULL) {
        category_infos = g_ptr_array_new_with_free_func(g_free);
        _load_category_info(category_infos);
    }
    return category_infos;
}

