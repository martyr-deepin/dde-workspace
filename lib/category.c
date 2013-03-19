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
#include "i18n.h"
#include "category.h"
#include <stdlib.h>
#include <glib.h>
#include "sqlite3.h"


const char* get_category_db_path()
{
    return DATA_DIR"/desktop.db";
}

static
int _get_all_possible_categories(GList** categories, int argc, char** argv, char** colname)
{
    int category_id = OTHER_CATEGORY_ID;
    if (argv[0][0] != '\0') {
        category_id = (int)g_strtod(argv[0], NULL);
    }

    *categories = g_list_append(*categories, GINT_TO_POINTER(category_id));
    return 0;
}

GList* get_deepin_categories(const char* full_path_name)
{
    GList* categories = NULL;
    GString* sql = g_string_new("select first_category_index from desktop where desktop_path = \"");
    g_string_append(sql, full_path_name);
    g_string_append(sql, "\";");
    sqlite3* db = NULL;
    if (SQLITE_OK == sqlite3_open_v2(get_category_db_path(), &db, SQLITE_OPEN_READONLY, NULL)) {
        g_assert(db != NULL);
        char* error = NULL;
        sqlite3_exec(db, sql->str, (SQLEXEC_CB)_get_all_possible_categories, &categories, &error);
        g_string_free(sql, TRUE);

        if (error != NULL) {
            g_warning("load category info failed %s\n", error);
            sqlite3_free(error);
        }
        sqlite3_close(db);
    }

    return categories;
}


int _fill_category_info(GPtrArray* infos, int argc, char** argv, char** colname)
{
    g_ptr_array_add(infos, g_strdup(_(argv[1])));
    return 0;
}

void _load_category_info(GPtrArray* category_infos)
{
    const char* sql_category_info = "select distinct first_category_index, first_category_name from category_name group by first_category_index;";
    sqlite3 *db = NULL;
    if (SQLITE_OK == sqlite3_open_v2(get_category_db_path(), &db, SQLITE_OPEN_READONLY, NULL)) {
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
        g_ptr_array_add(category_infos, g_strdup(_("internet")));
        g_ptr_array_add(category_infos, g_strdup(_("multimedia")));
        g_ptr_array_add(category_infos, g_strdup(_("games")));
        g_ptr_array_add(category_infos, g_strdup(_("graphics")));
        g_ptr_array_add(category_infos, g_strdup(_("productivity")));
        g_ptr_array_add(category_infos, g_strdup(_("industry")));
        g_ptr_array_add(category_infos, g_strdup(_("education")));
        g_ptr_array_add(category_infos, g_strdup(_("development")));
        g_ptr_array_add(category_infos, g_strdup(_("system")));
        g_ptr_array_add(category_infos, g_strdup(_("utilities")));
        /* g_ptr_array_add(category_infos, g_strdup("other")); */
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

