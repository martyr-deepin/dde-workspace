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
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>
#include <glib.h>
#include <glib/gprintf.h>

#define DEEPIN_SOFTWARE_CENTER_DATE_DIR    "/usr/share/deepin-software-center/data"
#define DATA_NEWEST_ID    DEEPIN_SOFTWARE_CENTER_DATE_DIR"/data_newest_id.ini"
#define DESKTOP_DB_PATH   DEEPIN_SOFTWARE_CENTER_DATE_DIR"/update/%s/desktop/desktop.db"

static time_t _last_modify_time = 0;

static
gboolean _need_to_update()
{
    struct stat newest;
    if (!stat(DATA_NEWEST_ID, &newest)) {
        return FALSE;
    }

    if (newest.st_mtime != _last_modify_time) {
        _last_modify_time = newest.st_mtime;
        return TRUE;
    }

    return FALSE;
}

const gchar* get_category_db_path()
{
    // the path to db has fixed 65 bytes, and uuid is 35 or 36 bytes.
    static gchar db_path[102] = {0};

    if (db_path[0] == 0 || _need_to_update()) {
        GKeyFile* id_file = g_key_file_new();
        if (g_key_file_load_from_file(id_file, DATA_NEWEST_ID, G_KEY_FILE_NONE, NULL)) {
            gchar* newest_id = g_key_file_get_value(id_file, "newest", "data_id", NULL);
            g_key_file_free(id_file);
            g_snprintf(db_path, 101, DESKTOP_DB_PATH, newest_id);
            g_free(newest_id);
        }
    }

    return db_path;
}

static
const char* _get_x_category_db_path()
{
    return DATA_DIR"/x_category.sqlite";
}

static
gboolean _search_database(const char* db_path, const char* sql, SQLEXEC_CB fn, void* res)
{
    sqlite3* db = NULL;
    gboolean is_good = SQLITE_OK == sqlite3_open_v2(db_path, &db, SQLITE_OPEN_READONLY, NULL);
    if (is_good) {
        char* error = NULL;
        sqlite3_exec(db, sql, fn, res, &error);
        sqlite3_close(db);
        if (error != NULL) {
            g_warning("%s\n", error);
            sqlite3_free(error);
            is_good = FALSE;
        }
    }

    return is_good;
}

static
int _get_all_possible_x_categories(GHashTable* infos, int argc, char** argv, char** colname)
{
    if (argv[1][0] != '\0') {
        int id = (int)g_strtod(argv[1], NULL);
        g_hash_table_insert(infos, g_strdup(argv[0]), GINT_TO_POINTER(id));
    }
    return 0;
}

static
int find_category_id(const char* category_name)
{
    static GHashTable* _category_info = NULL;

    if (_category_info == NULL) {
        _category_info = g_hash_table_new_full(g_str_hash, g_str_equal, g_free, NULL);
        const char* sql = "select x_category_name, first_category_index from x_category;";
        _search_database(_get_x_category_db_path(), sql,
                         (SQLEXEC_CB)_get_all_possible_x_categories, _category_info);
    }

    int id = OTHER_CATEGORY_ID;
    char* key = g_utf8_casefold(category_name, -1);
    gpointer tmp;
   if (g_hash_table_lookup_extended(_category_info, key, NULL, &tmp))
        id = GPOINTER_TO_INT(tmp);
    g_free(key);
    return id;
}

static
GList* _remove_other_category(GList* categories)
{
    GList* iter = g_list_first(categories);
    while (iter != NULL) {
        if (iter->data == GINT_TO_POINTER(OTHER_CATEGORY_ID)) {
            categories = g_list_remove(categories, iter->data);
            iter = g_list_first(categories);
        } else {
            iter = g_list_next(iter);
        }
    }
    return categories;
}

static
GList* _get_x_category(GDesktopAppInfo* info)
{
    GList* categories = NULL;
    const char* all_categories = g_desktop_app_info_get_categories(info);
    if (all_categories == NULL) {
        categories = g_list_append(categories, GINT_TO_POINTER(OTHER_CATEGORY_ID));
        return categories;
    }

    gboolean has_other_id = FALSE;
    gchar** x_categories = g_strsplit(all_categories, ";", 0);
    gsize len = g_strv_length(x_categories) - 1;
    for (int i = 0; i < len; ++i) {
        int id = find_category_id(x_categories[i]);
        if (id == OTHER_CATEGORY_ID)
            has_other_id = TRUE;
        categories = g_list_append(categories, GINT_TO_POINTER(id));
    }

    if (has_other_id)
        categories = _remove_other_category(categories);

    if (categories == NULL)
        categories = g_list_append(categories, GINT_TO_POINTER(OTHER_CATEGORY_ID));

    g_strfreev(x_categories);
    return categories;
}

static
int _get_all_possible_categories(GList** categories, int argc, char** argv, char** colname)
{
    if (argv[0][0] != '\0') {
        int category_id = (int)g_strtod(argv[0], NULL);
        *categories = g_list_append(*categories, GINT_TO_POINTER(category_id));
    }

    return 0;
}

GList* get_deepin_categories(GDesktopAppInfo* info)
{
    GList* categories = NULL;
    GString* sql = g_string_new("select first_category_index from desktop where desktop_path = \"");
    g_string_append(sql, g_desktop_app_info_get_filename(info));
    g_string_append(sql, "\";");
    _search_database(get_category_db_path(), sql->str,
                     (SQLEXEC_CB)_get_all_possible_categories,
                     &categories);
    g_string_free(sql, TRUE);

    if (categories == NULL)
        categories = _get_x_category(info);

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
    if (!_search_database(get_category_db_path(), sql_category_info,
                          (SQLEXEC_CB)_fill_category_info, category_infos)) {
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
    }

    /* add this for apps which cannot be categoried */
    g_ptr_array_add(category_infos, g_strdup(_("other")));
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

