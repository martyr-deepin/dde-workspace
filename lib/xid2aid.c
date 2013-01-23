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
#include "xid2aid.h"
#include <string.h>
#include <glib.h>

/*MEMORY_TESTED*/

#define FILTER_ARGS_PATH DATA_DIR"/filter_arg.ini"
#define FILTER_WMNAME_PATH DATA_DIR"/filter_wmname.ini"
#define FILTER_WMCLASS_PATH DATA_DIR"/filter_wmclass.ini"
#define PROCESS_REGEX_PATH DATA_DIR"/process_regex.ini"
#define DEEPIN_ICONS_PATH DATA_DIR"/deepin_icons.ini"

static GKeyFile* filter_args = NULL;
static GKeyFile* filter_wmname = NULL;
static GKeyFile* filter_wmclass = NULL;
static GKeyFile* deepin_icons = NULL;

static GRegex* prefix_regex = NULL;
static GRegex* suffix_regex = NULL;
static GHashTable* white_apps = NULL;
static gboolean _is_init = FALSE;

static
void _build_filter_info(GKeyFile* filter, const char* path)
{
    if (g_key_file_load_from_file(filter, path, G_KEY_FILE_NONE, NULL)) {
        gsize size;
        char** groups = g_key_file_get_groups(filter, &size);
        for (gsize i=0; i<size; i++) {
            gsize key_len;
            char** keys = g_key_file_get_keys(filter, groups[i], &key_len, NULL);
            for (gsize j=0; j<key_len; j++) {
                g_hash_table_insert(white_apps, g_key_file_get_string(filter, groups[i], keys[j], NULL), NULL);
            }
        }
    }
}


static
void _init()
{
    white_apps = g_hash_table_new_full(g_str_hash, g_str_equal, g_free, NULL);

    // load and build process regex config information
    GKeyFile* process_regex = g_key_file_new();
    if (g_key_file_load_from_file(process_regex, PROCESS_REGEX_PATH, G_KEY_FILE_NONE, NULL)) {
        char* str = g_key_file_get_string(process_regex, "DEEPIN_PREFIX", "skip_prefix", NULL);
        prefix_regex = g_regex_new(str, G_REGEX_OPTIMIZE, 0, NULL);
        g_free(str);

        str = g_key_file_get_string(process_regex, "DEEPIN_PREFIX", "skip_suffix", NULL);
        suffix_regex = g_regex_new(str, G_REGEX_OPTIMIZE, 0, NULL);
        g_free(str);
    } 
    if (prefix_regex == NULL) {
        g_warning("Can't build prefix_regex, use fallback config!");
        prefix_regex = g_regex_new(
                "skip_prefix=(^gksu(do)?$)|(^sudo$)|(^java$)|(^mono$)|(^ruby$)|(^padsp$)|(^aoss$)|(^python(\\d.\\d)?$)|(^(ba)?sh$)",
                G_REGEX_OPTIMIZE, 0, NULL
                );

    }
    if (suffix_regex == NULL) {
        g_warning("Can't build suffix_regex, use fallback config!");
        suffix_regex = g_regex_new( "((-|.)bin$)|(.py$)", G_REGEX_OPTIMIZE, 0, NULL);
    }
    g_key_file_free(process_regex);

    // load and filters and build white_list
    _build_filter_info(filter_args = g_key_file_new(), FILTER_ARGS_PATH);
    _build_filter_info(filter_wmclass = g_key_file_new(), FILTER_WMCLASS_PATH);
    _build_filter_info(filter_wmname = g_key_file_new(), FILTER_WMNAME_PATH);

    // set init flag
    _is_init = TRUE;
    g_assert(suffix_regex != NULL);
    g_assert(prefix_regex != NULL);
}

static
void _get_exec_name_args(char** cmdline, char** name, char** args)
{
    *args = NULL;

    gsize name_pos = 0;
    gsize length = g_strv_length(cmdline);
    for (; name_pos < length; name_pos++) {
        char* basename = g_path_get_basename(cmdline[name_pos]);
        if (g_regex_match(prefix_regex, basename, 0, NULL)) {
            while (basename[0] == '-')
                name_pos++;
            name_pos++;

            g_free(basename);
            break;
        } else {
            g_free(basename);
        }
    }

    int diff = length - name_pos;
    if (diff == 0) {
        *name = g_path_get_basename(cmdline[0]);
        if (length > 1) {
            *args = g_strjoinv(" ", cmdline+1); 
        }
    } else if (diff >= 1){
        *name = g_path_get_basename(cmdline[name_pos]); 
        if (diff >= 2) {
            *args = g_strjoinv(" ", cmdline+name_pos+1);
        }
    }

    char* tmp = *name;
    g_assert(tmp != NULL);
    g_assert(suffix_regex != NULL);
    *name = g_regex_replace_literal (suffix_regex, tmp, -1, 0, "", 0, NULL);
    g_free(tmp);

    for (int i=0; i<strlen(*name); i++) {
        if ((*name)[i] == ' ') {
            (*name)[i] = '\0';
            break;
        }
    }
}

static
char* _find_app_id_by_filter(const char* name, const char* keys_str, GKeyFile* filter)
{
    if (filter == NULL) return NULL;
    g_assert(name != NULL && keys_str != NULL);
    if (g_key_file_has_group(filter, name)) {
        gsize size = 0;
        char** keys = g_key_file_get_keys(filter, name, &size, NULL);
        for (gsize i=0; i<size; i++) {
            char* value = g_key_file_get_string(filter, name, keys[i], NULL);
            if (g_strstr_len(keys_str , -1, keys[i])) {
                g_strfreev(keys);
                return value;
            }
            g_free(value);
        }
        g_strfreev(keys);
        /*g_debug("find \"%s\" in filter.ini but can't find the really desktop file\n", name);*/
    }
    return NULL;
}

char* find_app_id(const char* exec_name, const char* key, int filter)
{
    if (_is_init == FALSE) {
        _init();
    }
    g_assert(exec_name != NULL && key != NULL);
    switch (filter) {
        case APPID_FILTER_WMCLASS:
            return _find_app_id_by_filter(exec_name, key, filter_wmclass);
        case APPID_FILTER_WMNAME:
            return _find_app_id_by_filter(exec_name, key, filter_wmname);
        case APPID_FILTER_ARGS:
            return _find_app_id_by_filter(exec_name, key, filter_args);
        default:
            g_error("filter %d is not support !", filter);
    }
    return NULL;
}

void get_pid_info(int pid, char** exec_name, char** exec_args)
{
    if (_is_init == FALSE) {
        _init();
    }
    char* cmd_line = NULL;
    char* path = g_strdup_printf("/proc/%d/cmdline", pid);

    gsize size=0;
    if (g_file_get_contents(path, &cmd_line, &size, NULL) && size > 0) {
        GPtrArray* tmp = g_ptr_array_new();
        int pre_pos = 0;
        for (gsize i=0; i<size; i++) {
            if (cmd_line[i] == '\0') {
                g_ptr_array_add(tmp, cmd_line+pre_pos);
                pre_pos = i+1;
            }
        }

        int len = tmp->len;
        char** name_args = g_new(char*, len+1);
        for (gsize i=0; i<len; i++) {
            name_args[i] = g_utf8_casefold(g_ptr_array_index(tmp, i), -1);
        }
        name_args[len] = NULL;

        g_ptr_array_free(tmp, TRUE);
        g_free(cmd_line);

        _get_exec_name_args(name_args, exec_name, exec_args);

    } else {
        g_free(path);
        *exec_name = NULL;
        *exec_args = NULL;
    }
}

gboolean is_app_in_white_list(const char* name)
{
    if (!_is_init) {
        _init();
    }
    return g_hash_table_contains(white_apps, name);
}


gboolean is_deepin_app_id(const char* app_id)
{
    if (deepin_icons == NULL) {
        deepin_icons = g_key_file_new();
        if (!g_key_file_load_from_file(deepin_icons, DEEPIN_ICONS_PATH, G_KEY_FILE_NONE, NULL)) {
            g_key_file_free(deepin_icons);
            deepin_icons = NULL;
            return FALSE;
        }
    }
    return g_key_file_has_group(deepin_icons, app_id);

}
int get_deepin_app_id_operator(const char* app_id)
{
    g_assert(deepin_icons != NULL);
    return g_key_file_get_integer(deepin_icons, app_id, "operator", NULL);
}
char* get_deepin_app_id_value(const char* app_id)
{
    g_assert(deepin_icons != NULL);
    return g_key_file_get_string(deepin_icons, app_id, "value", NULL);
}
