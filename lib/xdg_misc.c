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
#include <glib.h>
#include <gio/gio.h>
#include <glib/gstdio.h>
#include <stdio.h>
#include <string.h>
#include <gtk/gtk.h>
#include <gio/gdesktopappinfo.h>

#include "pixbuf.h"
#include "utils.h"
#include "xdg_misc.h"

#include "category.h"

#define APPEND_STRING_WITH_ESCAPE(str, format, content) do { \
    char* escaped = json_escape(content); \
    g_string_append_printf(str, format, escaped); \
    g_free(escaped); \
} while (0) 

#define APPEND_JSON(str, k,v) g_string_append_printf(str, "\"%s\":\"%s\",\n", k, v)
#define APPEND_JSON_WITH_ESCAPE(str, k, v) do { \
    char* escaped = json_escape(v); \
    APPEND_JSON(str, k, escaped); \
    g_free(escaped); \
} while (0) 

static const char* GROUP = "Desktop Entry";
static char DE_NAME[100] = "DEEPIN";

void set_desktop_env_name(const char* name)
{
    size_t max_len = strlen(name) + 1;
    memcpy(DE_NAME, name, max_len > 100 ? max_len : 100);
    g_desktop_app_info_set_desktop_env(name);
}

char* check_xpm(const char* path)
{
    char* ext = strrchr(path, '.');
    if (ext != NULL && 
            (ext[1] == 'x' || ext[1] == 'X')  &&
            (ext[2] == 'p' || ext[2] == 'P')  &&
            (ext[3] == 'm' || ext[3] == 'M')
       ) {
        return get_data_uri_by_path(path);
    } else {
        return g_strdup(path);
    }
}



char* icon_name_to_path(const char* name, int size) 
{
    g_return_val_if_fail(name != NULL, NULL);

    if (g_path_is_absolute(name))
        return check_xpm(name);

    char* ext = strchr(name, '.');
    if (ext != NULL) {
        *ext = '\0'; //FIXME: Is it ok to changed it's value? The ext is an part of an gtk_icon_info's path field's allocated memroy.
        g_debug("desktop's Icon name should an absoulte path or an basename without extension");
    }
    GtkIconTheme* them = gtk_icon_theme_get_default(); //do not ref or unref it
    GtkIconInfo* info = gtk_icon_theme_lookup_icon(them, name, size, GTK_ICON_LOOKUP_GENERIC_FALLBACK);
    if (info) {
        const char* path = gtk_icon_info_get_filename(info);
        char* ret = check_xpm(path);
        gtk_icon_info_free(info);
        return ret;
    } else {
        return NULL;
    }
}

char* get_dir_file_list(const char* path)
{
    g_return_val_if_fail(g_path_is_absolute(path), g_strdup("Path must be absolutely!"));

    GString* string = g_string_new("[");
    GDir* dir = g_dir_open(path, 0, NULL);
    const char* child = NULL;
    int i = 0;
    while (NULL != (child = g_dir_read_name(dir))) {
        APPEND_STRING_WITH_ESCAPE(string, "\"%s\",", child);
        i++;
    }
    char *ret = NULL;
    if (i > 0)  {
        string = g_string_overwrite(string, string->len-1, "]");
        ret = string->str;
        g_string_free(string, FALSE);
    } else {
        ret = g_strdup("[]");
        g_string_free(string, TRUE);
    } 
    g_dir_close(dir);
    return ret;
}


char* lookup_icon_by_file(const char* path)
{
    char* icon_path = NULL;

    GFile* file = g_file_new_for_path(path);
    GFileInfo *info = g_file_query_info(file, "standard::icon", G_FILE_QUERY_INFO_NONE, NULL, NULL);
    if (info != NULL) {
        GIcon* icon = g_file_info_get_icon(info);
        char* str = g_icon_to_string(icon);
        char** types = g_strsplit(str, " ", -1);
        g_free(str);

        char** tmp = types;
        if (*tmp != NULL) tmp++;

        while (*tmp != NULL && icon_path == NULL) {
            icon_path = icon_name_to_path(*(tmp++), 48);
        }

        g_strfreev(types);
        g_object_unref(info);
    }
    g_object_unref(file);

    return icon_path;
}


BaseEntry* parse_normal_file(const char* path)
{
    DirectoryEntry* dir_entry = NULL;
    FileEntry* file_entry = NULL;
    BaseEntry* entry = NULL;

    if (g_file_test(path, G_FILE_TEST_IS_DIR)) {
        dir_entry = g_new0(DirectoryEntry, 1);
        entry = (BaseEntry*)dir_entry;

        entry->type = DirEntryType;
        /*dir_entry->files = get_dir_file_list(path);*/
    } else {
        file_entry = g_new0(FileEntry, 1);

        entry = (BaseEntry*)file_entry;
        entry->type = FileEntryType; 

        if (g_file_test(path, G_FILE_TEST_IS_EXECUTABLE)) {
            file_entry->exec = g_strdup(path);
        } else {
            char* e_path = shell_escape(path);
            file_entry->exec = g_strdup_printf("gvfs-open %s", e_path);
            g_free(e_path);
        }
    }

    entry->icon = lookup_icon_by_file(path);
    entry->name = g_path_get_basename(path);
    entry->entry_path = g_strdup(path);

    return entry;
}

gboolean find_in(char** const array, const char* str)
{
    if (array == NULL) return FALSE;

    char** tmp = array;
    for(; *tmp != NULL; tmp++)
        if (g_strcmp0(*tmp, str) == 0)
            return TRUE;
    return FALSE;
}

BaseEntry* parse_base_entry(GKeyFile* de, const char* path)
{
    BaseEntry* entry = NULL;

    char* type = g_key_file_get_value(de, GROUP, "Type", NULL);
    if (type == NULL)
        return NULL;
    if (g_key_file_get_boolean(de, GROUP, "NoDisplay", NULL))
        return NULL;

    if (g_strcmp0(type, "Application") == 0) {
        entry = (BaseEntry*)g_new0(ApplicationEntry, 1);
        entry->type = AppEntryType;
    } else if (g_strcmp0(type, "Link") == 0) {
        entry = (BaseEntry*)g_new0(LinkEntry, 1);
        entry->type = LinkEntryType;
    } else {
        g_warning("Not yet support the desktop entry of type : %s\n", type);
        return NULL;
    }

    entry->entry_path = g_strdup(path);
    entry->name = g_key_file_get_locale_string(de, GROUP, "Name", NULL, NULL); 
    if (entry->name == NULL) {
        g_warning("%s must have Name field\n", path);
        desktop_entry_free(entry);
        return NULL;
    }
    entry->icon = g_key_file_get_locale_string(de, GROUP, "Icon", NULL, NULL);

    return entry;
}

BaseEntry* parse_application_entry(GKeyFile* de, ApplicationEntry* entry)
{
    entry->exec = g_key_file_get_string(de, GROUP, "Exec", NULL);

    if (entry->exec == NULL) {
        g_warning("%s is Application Entry , so must have Exec field\n", entry->base.entry_path);
        desktop_entry_free((BaseEntry*)entry);
        return NULL;
    } else {
        char* percentage = strrchr(entry->exec, '%');
        if (percentage != NULL && (percentage - entry->exec) < strlen(entry->exec) - 1) {
            entry->exec_flag = percentage[1];
            /**percentage = '\0';*/
        } else {
            entry->exec_flag = ' ';
        }
    }
    /*char** cs = g_key_file_get_string_list(de, GROUP, "Categories", NULL, NULL);*/
    /*if (cs != NULL) {*/
        /*entry->categories = get_deepin_categories(cs);*/
        /*g_strfreev(cs);*/
    /*}*/
    return (BaseEntry*)entry;
}

BaseEntry* parse_link_entry(GKeyFile* de, LinkEntry* entry)
{
    entry->url = g_key_file_get_string(de, GROUP, "URL", NULL); 
    if (entry->url == NULL) {
        g_warning("%s is URL Entry , so must have URL field\n", entry->base.entry_path);
        desktop_entry_free((BaseEntry*)entry);
        return NULL;
    }
    return (BaseEntry*)entry;
}

BaseEntry* parse_directory_entry(GKeyFile* de, DirectoryEntry* entry)
{
    return (BaseEntry*)entry;
}

BaseEntry* parse_desktop_entry(const char* path)
{
    GKeyFile *de = g_key_file_new();

    if (!g_key_file_load_from_file(de, path, G_KEY_FILE_NONE, NULL)) {
        g_warning("this is not an valid desktop entry file");
        g_key_file_free(de);
        return NULL;
    } 

    BaseEntry* entry = parse_base_entry(de, path);

    if (entry != NULL) {
        switch(entry->type) {
            case AppEntryType:
                parse_application_entry(de, (ApplicationEntry*)entry);
                break;
            case LinkEntryType:
                parse_link_entry(de, (LinkEntry*)entry);
                break;
            case DirEntryType:
                parse_directory_entry(de, (DirectoryEntry*)entry);
                break;
        }
    }

    g_key_file_free(de);
    return entry;
}
char* to_json_array(char** const strings)
{
    int i = 0;
    GString* string = g_string_new("[");
    char** tmp = strings;
    while (*tmp != NULL) {
        APPEND_STRING_WITH_ESCAPE(string, "\"%s\",", *(tmp++));
        i++;
    }


    char* ret = NULL;
    if (i > 0)  {
        string = g_string_overwrite(string, string->len-1, "]");
        ret = string->str;
        g_string_free(string, FALSE);
    } else {
        ret = g_strdup("[]");
        g_string_free(string, TRUE);
    }
    g_assert (ret != NULL);
    return ret;
}

static 
char* get_dir_icon(const gchar* path)
{
    GDir *dir =  g_dir_open(path, 0, NULL);
    g_assert(dir != NULL);

    char* icons[4] = {NULL, NULL, NULL, NULL};
    for (int i=0; i<4; i++) {
        const gchar* filename= g_dir_read_name(dir);
        if (filename == NULL) break;

        gchar* entry_path = g_strdup_printf("%s/%s", path, filename);
        BaseEntry* entry = parse_one_entry(entry_path);
        g_free(entry_path);

        if (entry != NULL) {
            icons[i] = icon_name_to_path(entry->icon, 24);
            desktop_entry_free(entry);
        } else {
            i--;
        }

    }
    g_dir_close(dir);
    char* data = generate_directory_icon(icons[0], icons[1], icons[2], icons[3]);
    g_free(icons[0]);
    g_free(icons[1]);
    g_free(icons[2]);
    g_free(icons[3]);
    return data;
}



char* app_info_to_json(GAppInfo* app_info)
{
}

char* entry_info_to_json(BaseEntry* _entry) 
{
    g_return_val_if_fail(_entry != NULL, NULL);
    GString* string = g_string_new("{\n");
    if (_entry->entry_path)
        APPEND_JSON_WITH_ESCAPE(string, "EntryPath", _entry->entry_path);
    if (_entry->name)
        APPEND_JSON_WITH_ESCAPE(string, "Name", _entry->name);
    if (_entry->type)
        g_string_append_printf(string, "\"Type\":\"%d\",\n", _entry->type);
    switch (_entry->type) {
        case DirEntryType:
            {
                g_string_append(string, "\"Type\":\"Dir\",\n");
                char* data_uri = get_dir_icon(_entry->entry_path);
                if (data_uri != NULL) {
                    APPEND_JSON_WITH_ESCAPE(string, "Icon", data_uri);
                    g_free(data_uri);
                }
                DirectoryEntry *entry = (DirectoryEntry*) _entry;
                if (entry->files)
                    g_string_append_printf(string, "\"Files\":%s,\n", entry->files);
            }
            break;
        case FileEntryType:
            {
                g_string_append(string, "\"Type\":\"File\",\n");
                FileEntry *entry = (FileEntry*) _entry;
                if (entry->exec) {
                    APPEND_JSON_WITH_ESCAPE(string, "Exec", entry->exec);
                }
            }
            break;
        case LinkEntryType:
            {
                g_string_append(string, "\"Type\":\"Link\",\n");
                LinkEntry *entry = (LinkEntry*) _entry;
                if (entry->url)
                    APPEND_JSON_WITH_ESCAPE(string, "URL", entry->url);
            }
            break;
        case AppEntryType:
            {
                g_string_append(string, "\"Type\":\"Application\",\n");
                ApplicationEntry* entry = (ApplicationEntry*) _entry;
                if (entry->exec) {
                    APPEND_JSON_WITH_ESCAPE(string, "Exec", entry->exec);
                }
                if (entry->exec_flag != ' ')
                    g_string_append_printf(string, "\"ExecFlag\":\"%c\",\n", entry->exec_flag);
                if (entry->categories) {
                    char** cs = g_strsplit(entry->categories, ";", -1);
                    char* array = to_json_array(cs);
                    g_string_append_printf(string, "\"Categories\":%s,\n", array);
                    g_free(array);
                    g_strfreev(cs);
                }
                break;
            }
    }

    char* icon_path = icon_name_to_path(_entry->icon, 48);
    if (icon_path != NULL) {
        APPEND_JSON_WITH_ESCAPE(string, "Icon", icon_path);
        g_free(icon_path);
    } else {
        g_string_append(string, "\"Icon\":\"not_found.png\",\n");
        g_free(icon_path);
    }


    if (string->len > 2) {
        string = g_string_overwrite(string, string->len-2, "\n}\0");
    }
    char* ret = string->str;
    g_string_free(string, FALSE);
    return ret;
}


BaseEntry* parse_one_entry(const char* path)
{
    if (g_str_has_suffix(path, ".desktop")) {
        return parse_desktop_entry(path);
    } else  {
        char* basename = g_path_get_basename(path);
        if (basename[0] == '.') {
            g_free(basename);
            return NULL;
        }
        g_free(basename);
        return parse_normal_file(path);
    }
}


void set_default_theme(const char* theme)
{
    GtkSettings* setting = gtk_settings_get_default();
    g_object_set(setting, "gtk-icon-theme-name", "Deepin", NULL);
}

void desktop_entry_free(BaseEntry* entry)
{
    if (entry != NULL) {
        g_free(entry->entry_path);
        g_free(entry->name);
        g_free(entry->icon);

        switch(entry->type) {
            case AppEntryType:
                {
                    g_free(((ApplicationEntry*)entry)->exec);
                    g_free(((ApplicationEntry*)entry)->categories);
                    break;
                }
            case LinkEntryType:
                g_free(((LinkEntry*)entry)->url);
                break;
            case FileEntryType:
                g_free(((FileEntry*)entry)->exec);
                break;
            case DirEntryType:
                g_free(((DirectoryEntry*)entry)->files);
                break;
            default:
                g_assert_not_reached();
        }
    }
    g_free(entry);
}

char* get_desktop_dir(gboolean update)
{
    static char* dir = NULL;
    if (update || dir == NULL) {
        if (dir != NULL)
            g_free(dir);
        const char* cmd = "bash -c 'source ~/.config/user-dirs.dirs && echo $XDG_DESKTOP_DIR'";
        g_spawn_command_line_sync(cmd, &dir, NULL, NULL, NULL);
        g_strchomp(dir);
    }
    return g_strdup(dir);
}

char* get_entries_by_func(const char* base_dir, ENTRY_CONDITION func)
{
    char** str_dirs = g_strsplit(base_dir, ";", -1);
    char** tmp = str_dirs;

    const char* filename = NULL;
    char path[500];

    GString* content = g_string_new("[");

    for (; *tmp != NULL; tmp++) {
        GDir *dir =  g_dir_open(*tmp, 0, NULL);
        if (dir == NULL)
            continue;
        while ((filename = g_dir_read_name(dir)) != NULL) {
            g_sprintf(path, "%s/%s", *tmp, filename);
            if (func != NULL && !func(path))
                continue;

            BaseEntry* entry = parse_one_entry(path);
            if (entry == NULL)
                continue;
            char* info = entry_info_to_json(entry);
            desktop_entry_free(entry);

            g_string_append(content, info);
            g_string_append_c(content, ',');
            g_free(info);
        }
        g_dir_close(dir);
    }
    g_strfreev(str_dirs);



    char* ret = NULL;
    if (content->len > 2) {
        content = g_string_overwrite(content, content->len-1, "]");
        ret = content->str;
        g_string_free(content, FALSE);
    } else {
        ret = g_strdup("[]");
        g_string_free(content, TRUE);
    }
    return ret;
}

gboolean only_desktop(const char* path)
{
    return g_str_has_suffix(path, ".desktop");
}
gboolean only_normal_file(const char* path)
{
    return g_file_test(path, G_FILE_TEST_IS_REGULAR) && !only_desktop(path);
}
gboolean only_normal_dir(const char* path)
{
    return g_file_test(path, G_FILE_TEST_IS_DIR);
}
gboolean no_dot_hidden_file(const char* path)
{
    char* basename = g_path_get_basename(path);
    gboolean ret = TRUE;
    if (basename && basename[0] == '.')
        ret = FALSE;
    g_free(basename);
    return ret;
}

char* get_application_entries()
{
    char* base_dir = g_strdup_printf("%s;%s/%s", "/usr/share/applications", g_get_home_dir(), ".local/share/applications");
    char* ret = get_entries_by_func(base_dir, only_desktop);
    g_free(base_dir);
    return ret;
}

 

char* get_desktop_entries()
{
    char* base_dir = get_desktop_dir(FALSE);

    char* ret = get_entries_by_func(base_dir, no_dot_hidden_file);

    g_free(base_dir);

    return ret;
}

char* get_entry_info(const char* path)
{
    BaseEntry* entry = parse_one_entry(path);
    if (entry != NULL) {
        char* ret = entry_info_to_json(entry);
        desktop_entry_free(entry);
        return ret;
    }
    return NULL;
}

//JS_EXPORT_API
char* desktop_move_to_desktop(const char* path)
{
    char* desktop_dir = get_desktop_dir(FALSE);
    char* dir = g_path_get_dirname(path);

    if (g_strcmp0(desktop_dir, dir) == 0) {
        g_free(desktop_dir);
        g_free(dir);
        return g_strdup("");
    } 

    char* name = g_path_get_basename(path);
    char* new_path = g_build_filename(desktop_dir, name, NULL);
    int i= 1;
    while (g_file_test(new_path, G_FILE_TEST_EXISTS)) {
        g_free(new_path);
        new_path = g_strdup_printf("%s/%s.(%d)", desktop_dir, name, i++);
    }
    g_free(name);
    g_free(desktop_dir);
    g_free(dir);

    dcore_run_command2("mv", path, new_path);
    return new_path;
}

gboolean change_desktop_entry_name(const char* path, const char* name)
{
    GKeyFile *de = g_key_file_new();
    if (!g_key_file_load_from_file(de, path,
                G_KEY_FILE_KEEP_COMMENTS | G_KEY_FILE_KEEP_TRANSLATIONS, NULL)) {
        return FALSE;
    } else {
        const char* locale = *g_get_language_names();
        if (locale && !g_str_has_prefix(locale, "en"))
            g_key_file_set_locale_string(de, GROUP, "Name", locale, name);
        else
            g_key_file_set_string(de, GROUP, "Name", name);

        gsize size;
        gchar* content = g_key_file_to_data(de, &size, NULL);
        if (write_to_file(path, content, size)) {
            g_key_file_free(de);
            g_free(content);
            return TRUE;
        } else {
            g_key_file_free(de);
            g_free(content);
            return FALSE;
        }
    }
}


const char* get_entry_name(GAppInfo* info)
{
    return g_app_info_get_display_name(info);
}
