/**
 * Copyright (c) 2011 ~ 2013 Deepin, Inc.
 *               2013 ~ 2013 Liqiang Lee
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

#include <string.h>

#include "category.h"
#include "x_category.h"
#include "launcher_category.h"
#include "i18n.h"
#include "jsextension.h"
#include "dentry/entry.h"


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

    g_debug("[%s] %s", __func__, g_desktop_app_info_get_filename(info));
    gboolean has_other_id = FALSE;
    gchar** x_categories = g_strsplit(all_categories, ";", 0);
    for (int i = 0; x_categories[i] != NULL && x_categories[i][0] != '\0'; ++i) {
        char* lower_case = g_utf8_casefold(x_categories[i], -1);
        int id = find_category_id(_(lower_case));
        g_free(lower_case);
        g_debug("[%s] #%s#:%d", __func__, x_categories[i], id);
        if (id == OTHER_CATEGORY_ID)
            has_other_id = TRUE;
        categories = g_list_append(categories, GINT_TO_POINTER(id));
    }

    if (has_other_id)
        categories = _remove_other_category(categories);

    if (categories == NULL)
        categories = g_list_append(categories, GINT_TO_POINTER(OTHER_CATEGORY_ID));

    for (GList* iter = g_list_first(categories); iter != NULL; iter = g_list_next(iter))
        g_debug("[%s] using %d", __func__, GPOINTER_TO_INT(iter->data));
    g_strfreev(x_categories);
    return categories;
}


PRIVATE
int _get_all_possible_categories(GList** categories, int argc, char** argv, char** colname)
{
    if (argv[0][0] != '\0') {
        int category_id = find_category_id(_(argv[0]));
        g_debug("[%s] %d", __func__, category_id);
        *categories = g_list_append(*categories, GINT_TO_POINTER(category_id));
    }

    return 0;
}


GList* get_deepin_categories(GDesktopAppInfo* info)
{
    char* basename = g_path_get_basename(g_desktop_app_info_get_filename(info));
    GList* categories = NULL;
    char* sql = g_strdup_printf("select first_category_name "
                                "from desktop "
                                "where desktop_name like \"%s\";", basename);
    g_debug("[%s] app: %s", __func__, basename);
    g_free(basename);
    search_database(get_category_name_db_path(), sql,
                    (SQLEXEC_CB)_get_all_possible_categories,
                    &categories);
    g_free(sql);

    return categories;
}


static
int _fill_category_info(GPtrArray* infos, int argc, char** argv, char** colname)
{
    if (argv[0][0] != '\0')
        g_ptr_array_add(infos, g_strdup(_(argv[0])));
    return 0;
}


PRIVATE
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


/**
 * @brief - key: the category id
 *          value: a set of applications id (md5 basename of path)
 */
PRIVATE GHashTable* _category_table = NULL;


void destroy_category_table()
{
    if (_category_table != NULL)
        g_hash_table_destroy(_category_table);
}


PRIVATE
void _append_to_category(const char* path, GList* cs)
{
    if (_category_table == NULL) {
        _category_table =
            g_hash_table_new_full(g_direct_hash, g_direct_equal, NULL,
                                  (GDestroyNotify)g_hash_table_unref);
    }

    // Using GHashTable instead of GPtrArray to avoiding infinitely append the
    // same value.
    GHashTable* l = NULL;

    for (GList* iter = g_list_first(cs); iter != NULL; iter = g_list_next(iter)) {
        gpointer id = iter->data;
        l = g_hash_table_lookup(_category_table, id);
        if (l == NULL) {
            // Using GHashTable as a set, just one destroy function is needed,
            // otherwise, double free occurs.
            l = g_hash_table_new_full(g_str_hash, g_str_equal, g_free, NULL);
            g_hash_table_insert(_category_table, id, l);
        }

        g_hash_table_add(l, g_strdup(path));
    }
}


PRIVATE
void _record_category_info(GDesktopAppInfo* info)
{
    char* id = dentry_get_id(info);
    GList* categories = get_deepin_categories(info);

    if (categories == NULL)
        categories = _get_x_category(info);

    _append_to_category(id, categories);
    g_free(id);
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

        _record_category_info(G_DESKTOP_APP_INFO(info));

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

    GHashTable* l = (GHashTable*)g_hash_table_lookup(_category_table,
                                                     GINT_TO_POINTER(id));
    if (l == NULL) {
        return items;
    }

    JSContextRef cxt = get_global_context();
    GHashTableIter iter;
    gpointer value = NULL;
    g_hash_table_iter_init(&iter, l);
    for (int i = 0; g_hash_table_iter_next(&iter, &value, NULL); ++i) {
        char const* path = (char const*)value;
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
double launcher_weight(GDesktopAppInfo* info, const char* key)
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

