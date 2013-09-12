/**
 * Copyright (c) 2011 ~ 2012 Deepin, Inc.
 *               2011 ~ 2012 Liqiang Lee
 *
 * Author:      Liqiang Lee <liliqiang@linuxdeepin.com>
 * Maintainer:  Liqiang Lee <liliqiang@linuxdeepin.com>
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
#include "x_category.h"
#include "launcher_category.h"
#include "i18n.h"
#include "jsextension.h"


PRIVATE
const char* _get_x_category_db_path()
{
    return DATA_DIR"/x_category.sqlite";
}


PRIVATE
int _get_category_name_index_map(GHashTable* infos, int argc, char** argv, char** colname)
{
    if (argv[1][0] != '\0') {
        int id = (int)g_strtod(argv[1], NULL);
        g_hash_table_insert(infos, g_strdup(_(argv[0])), GINT_TO_POINTER(id));
    }
    return 0;
}

int find_category_id(const char* category_name)
{
    static GHashTable* _category_info = NULL;

    if (_category_info == NULL) {
        _category_info = g_hash_table_new_full(g_str_hash, g_str_equal, g_free, NULL);
        char const* sql = "select distinct first_category_name, first_category_index from category_name;";
        search_database(get_category_index_db_path(), sql,
                        (SQLEXEC_CB)_get_category_name_index_map, _category_info);

        for (gsize i = 0; i < X_CATEGORY_NUM; ++i)
            g_hash_table_insert(_category_info, g_strdup(_(x_category_name_index_map[i].name)),
                                GINT_TO_POINTER(x_category_name_index_map[i].index));
    }

    int id = OTHER_CATEGORY_ID;
    char* key = g_utf8_casefold(category_name, -1);
    gpointer tmp;
    if (g_hash_table_lookup_extended(_category_info, key, NULL, &tmp))
        id = GPOINTER_TO_INT(tmp);
    g_free(key);
    return id;
}

PRIVATE
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

PRIVATE
GList* _get_x_category(GDesktopAppInfo* info)
{
    GList* categories = NULL;
    const char* all_categories = g_desktop_app_info_get_categories(info);
    if (all_categories == NULL) {
        categories = g_list_append(categories, GINT_TO_POINTER(OTHER_CATEGORY_ID));
        return categories;
    }

    g_debug("%s", g_desktop_app_info_get_filename(info));
    gboolean has_other_id = FALSE;
    gchar** x_categories = g_strsplit(all_categories, ";", 0);
    for (int i = 0; x_categories[i] != NULL; ++i) {
        char* lower_case = g_utf8_casefold(x_categories[i], -1);
        int id = find_category_id(_(lower_case));
        g_free(lower_case);
        g_debug("%s:%d", x_categories[i], id);
        if (id == OTHER_CATEGORY_ID)
            has_other_id = TRUE;
        categories = g_list_append(categories, GINT_TO_POINTER(id));
    }

    if (has_other_id)
        categories = _remove_other_category(categories);

    if (categories == NULL)
        categories = g_list_append(categories, GINT_TO_POINTER(OTHER_CATEGORY_ID));

    for (GList* iter = g_list_first(categories); iter != NULL; iter = g_list_next(iter))
        g_debug("%d", GPOINTER_TO_INT(iter->data));
    g_strfreev(x_categories);
    return categories;
}

PRIVATE
int _get_all_possible_categories(GList** categories, int argc, char** argv, char** colname)
{
    if (argv[0][0] != '\0') {
        int category_id = find_category_id(_(argv[0]));
        *categories = g_list_append(*categories, GINT_TO_POINTER(category_id));
    }

    return 0;
}

GList* get_deepin_categories(GDesktopAppInfo* info)
{
    char* basename = g_path_get_basename(g_desktop_app_info_get_filename(info));
    GList* categories = NULL;
    GString* sql = g_string_new("select first_category_name from desktop where desktop_name = \"");
    char** app_name = g_strsplit(basename, ".", -1);
    g_free(basename);

    g_string_append(sql, app_name[0]);
    g_strfreev(app_name);
    g_string_append(sql, "\";");
    search_database(get_category_name_db_path(), sql->str,
                    (SQLEXEC_CB)_get_all_possible_categories,
                    &categories);
    g_string_free(sql, TRUE);

    if (categories == NULL)
        categories = _get_x_category(info);

    return categories;
}


static
int _fill_category_info(GPtrArray* infos, int argc, char** argv, char** colname)
{
    if (argv[0][0] != '\0')
        g_ptr_array_add(infos, _(argv[0]));
    return 0;
}


static
void _load_category_info(GPtrArray* category_infos)
{
    const char* sql_category_info = "select distinct first_category_name from desktop;";
    if (!search_database(get_category_name_db_path(), sql_category_info,
                         (SQLEXEC_CB)_fill_category_info, category_infos)) {
        const char* const category_names[] = {
            INTERNET, MULTIMEDIA, GAMES, GRAPHICS, PRODUCTIVITY,
            INDUSTRY, EDUCATION, DEVELOPMENT, SYSTEM, UTILITIES,
        };
        int category_num = G_N_ELEMENTS(category_names);
        for (int i = 0; i < category_num; ++i)
            g_ptr_array_add(category_infos, g_strdup(category_names[i]));
    }

    /* add this for apps which cannot be categoried */
    g_ptr_array_add(category_infos, g_strdup(OTHER));
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

