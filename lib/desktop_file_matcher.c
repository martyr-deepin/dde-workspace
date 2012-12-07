#include "desktop_file_matcher.h"
#include <glib.h>

/*MEMORY_TESTED*/

static GKeyFile* white_list = NULL;
static GRegex* prefix_regex = NULL;
static GRegex* suffix_regex = NULL;
static GHashTable* white_apps = NULL;
static gboolean is_init = FALSE;
#define WHITE_LIST_INI "app_white_list.ini"

static
void _init()
{
    white_apps = g_hash_table_new_full(g_str_hash, g_str_equal, g_free, NULL);
    white_list = g_key_file_new();
    g_key_file_load_from_file(white_list, WHITE_LIST_INI, G_KEY_FILE_NONE, NULL);

    char* str = g_key_file_get_string(white_list, "DEEPIN_PREFIX", "skip_prefix", NULL);
    prefix_regex = g_regex_new(str, G_REGEX_OPTIMIZE, 0, NULL);
    g_free(str);

    str = g_key_file_get_string(white_list, "DEEPIN_PREFIX", "skip_suffix", NULL);
    suffix_regex = g_regex_new(str, G_REGEX_OPTIMIZE, 0, NULL);
    g_free(str);

    gsize size;
    char** groups = g_key_file_get_groups(white_list, &size);
    for (gsize i=0; i<size; i++) {
        if (g_strcmp0(groups[i], "DEEPIN_PREFIX") == 0)
            continue;

        gsize key_len;
        char** keys = g_key_file_get_keys(white_list, groups[i], &key_len, NULL);
        for (gsize j=0; j<key_len; j++) {
            g_hash_table_insert(white_apps, g_key_file_get_string(white_list, groups[i], keys[j], NULL), NULL);
        }
    }
    is_init = TRUE;
}

static
void get_exec_name_args(char** cmdline, char** name, char** args)
{
    *args = NULL;

    gsize name_pos = 0;
    gsize length = g_strv_length(cmdline);
    for (; name_pos < length; name_pos++) {
        if (g_regex_match(prefix_regex, cmdline[name_pos], 0, NULL)) {
            while (cmdline[name_pos+1][0] == '-')
                name_pos++;
            name_pos++;
            break;
        }
    }

    int diff = length - name_pos;
    if (diff == 0) {
        *name = g_strdup(cmdline[0]);
        if (length > 1) {
            *args = g_strjoinv(" ", cmdline+1); 
        }
    } else if (diff >= 1){
        *name = g_strdup(cmdline[name_pos]); 
        if (diff >= 2) {
            *args = g_strjoinv(" ", cmdline+name_pos+1);
        }
    }

    char* tmp = *name;
    *name = g_path_get_basename(tmp);
    g_free(tmp);

    tmp = *name;
    *name = g_regex_replace_literal (suffix_regex, tmp, -1, 0, "", 0, NULL);
    g_free(tmp);
}

static
char* find_desktop_path_in_white_list(char* name, char* args)
{
    if (g_key_file_has_group(white_list, name)) {
        gsize size = 0;
        char** keys = g_key_file_get_keys(white_list, name, &size, NULL);
        for (gsize i=0; i<size; i++) {
            char* value = g_key_file_get_string(white_list, name, keys[i], NULL);
            if (g_strstr_len(args, -1, keys[i])) {
                g_strfreev(keys);
                return value;
            }
            g_free(value);
        }
        g_strfreev(keys);
        g_warning("find \"%s\" in whitelist but can't find the really desktop file\n", name);
        return g_strdup(name);
    } else {
        return g_strdup(name);
    }
}

char* get_desktop_file_name_by_pid(int pid)
{
    if (!is_init) {
        _init();
    }
    char* exec_name = NULL;
    char* exec_args = NULL;
    char* result = NULL;

    char* cmd_line = NULL;
    char* path = g_strdup_printf("/proc/%d/cmdline", pid);
    gsize size=0;
    if (g_file_get_contents(path, &cmd_line, &size, NULL)) {
        GPtrArray* tmp = g_ptr_array_new();
        int pre_pos = 0;
        for (gsize i=0; i<size-1; i++) {
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

        get_exec_name_args(name_args, &exec_name, &exec_args);
        g_strfreev(name_args);

        result = find_desktop_path_in_white_list(exec_name, exec_args);
        g_free(exec_name);
        g_free(exec_args);
    }
    g_free(path);
    return result;
}


gboolean is_app_in_white_list(const char* name)
{
    if (!is_init) {
        _init();
    }
    return g_hash_table_contains(white_apps, name);
}
