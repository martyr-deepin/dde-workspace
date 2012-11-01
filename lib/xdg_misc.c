#include <glib.h>
#include <gio/gio.h>
#include <glib/gstdio.h>
#include <stdio.h>
#include <string.h>
#include <gtk/gtk.h>

#include "pixbuf.h"
#include "utils.h"
#include "xdg_misc.h"

#include "category.h"


#define APPEND_STRING_WITH_ESCAPE(str, format, content) do { \
    char* escaped = json_escape(content); \
    g_string_append_printf(str, format, escaped); \
    g_free(escaped); \
} while (0) 


static const char* GROUP = "Desktop Entry";
static char DE_NAME[100] = "DEEPIN";

void set_desktop_env_name(const char* name)
{
    size_t max_len = strlen(name) + 1;
    memcpy(DE_NAME, name, max_len > 100 ? max_len : 100);
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
        g_warning("desktop's Icon name should an absoulte path or an basename without extension");
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


static
BaseEntry* parse_normal_file(const char* path)
{
    DirectoryEntry* dir_entry = NULL;
    FileEntry* file_entry = NULL;
    BaseEntry* entry = NULL;

    if (g_file_test(path, G_FILE_TEST_IS_DIR)) {
        dir_entry = g_new0(DirectoryEntry, 1);
        entry = (BaseEntry*)dir_entry;

        entry->type = g_strdup("Dir");
        /*dir_entry->files = get_dir_file_list(path);*/
    } else {
        file_entry = g_new0(FileEntry, 1);

        entry = (BaseEntry*)file_entry;
        entry->type = g_strdup("File");

        if (g_file_test(path, G_FILE_TEST_IS_EXECUTABLE)) {
            file_entry->exec = g_strdup(path);
        } else {
            char* quote_path = g_shell_quote(path);
            file_entry->exec = g_strdup_printf("xdg-open %s", quote_path);
            g_free(quote_path);
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
    } else if (g_strcmp0(type, "Link") == 0) {
        entry = (BaseEntry*)g_new0(LinkEntry, 1);
    } else if (g_strcmp0(type, "Directory") == 0) {
        entry = (BaseEntry*)g_new0(DirectoryEntry, 1);
    } else {
        g_warning("Not yet support the desktop entry of type : %s\n", type);
        return NULL;
    }

    entry->entry_path = g_strdup(path);
    entry->type = type;
    entry->version = g_key_file_get_value(de, GROUP, "Version", NULL);
    entry->name = g_key_file_get_locale_string(de, GROUP, "Name", NULL, NULL); 
    if (entry->name == NULL) {
        g_warning("%s must have Name field\n", path);
        desktop_entry_free(entry);
        return NULL;
    }
    entry->generic_name = g_key_file_get_locale_string(de, GROUP, "GenericName", NULL, NULL);
    entry->comment = g_key_file_get_locale_string(de, GROUP, "Comment", NULL, NULL);
    entry->icon = g_key_file_get_locale_string(de, GROUP, "Icon", NULL, NULL);
    entry->hidden = g_key_file_get_boolean(de, GROUP, "Hidden", NULL);

    entry->only_show_in = g_key_file_get_string_list(de, GROUP, "OnlyShowIn", NULL, NULL);
    entry->not_show_in = g_key_file_get_string_list(de, GROUP, "NotShowIn", NULL, NULL);
    if (entry->only_show_in != NULL) {
        if (!find_in(entry->only_show_in, DE_NAME)) {
            desktop_entry_free(entry);
            entry = NULL;
            return entry;
        }
    } else if (entry->not_show_in != NULL) {
        if (find_in(entry->not_show_in, DE_NAME)) {
            desktop_entry_free(entry);
            entry = NULL;
            return entry;
        }
    }
    return entry;
}

BaseEntry* parse_application_entry(GKeyFile* de, ApplicationEntry* entry)
{
    entry->try_exec = g_key_file_get_string(de, GROUP, "TryExec", NULL);

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
    entry->path = g_key_file_get_string(de, GROUP, "Path", NULL);
    entry->terminal = g_key_file_get_boolean(de, GROUP, "Terminal", NULL);
    entry->actions = g_key_file_get_string_list(de, GROUP, "Actions", NULL, NULL); 
    entry->mime_type = g_key_file_get_string_list(de, GROUP, "MimeType", NULL, NULL);
    entry->categories = g_key_file_get_string_list(de, GROUP, "Categories", NULL, NULL);
    entry->keywords = g_key_file_get_locale_string_list(de, GROUP, "Keywords", NULL, NULL, NULL);
    entry->startup_notify = g_key_file_get_boolean(de, GROUP, "StartupNotify", NULL);
    entry->startup_wmclass = g_key_file_get_string(de, GROUP, "StartupWMClass", NULL);
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

static
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
        if (g_strcmp0(entry->type, "Application") == 0) {
            parse_application_entry(de, (ApplicationEntry*)entry);
        } else if (g_strcmp0(entry->type, "Link") == 0) {
            parse_link_entry(de, (LinkEntry*)entry);
        } else if (g_strcmp0(entry->type, "Directory") == 0) {
            parse_directory_entry(de, (DirectoryEntry*)entry);
        } else {
            g_warning("Entry file %s with Type %s is not support\n", entry->entry_path, entry->type);
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

char* entry_info_to_json(BaseEntry* _entry) 
{
    g_return_val_if_fail(_entry != NULL, NULL);
    GString* string = g_string_new("{\n");
    if (_entry->entry_path)
        APPEND_STRING_WITH_ESCAPE(string, "\"EntryPath\":\"%s\",\n", _entry->entry_path);
    if (_entry->type)
        APPEND_STRING_WITH_ESCAPE(string, "\"Type\":\"%s\",\n", _entry->type);
    if (_entry->version)
        APPEND_STRING_WITH_ESCAPE(string, "\"Version\":\"%s\",\n", _entry->version);
    if (_entry->name)
        APPEND_STRING_WITH_ESCAPE(string, "\"Name\":\"%s\",\n", _entry->name);
    if (_entry->generic_name)
        APPEND_STRING_WITH_ESCAPE(string, "\"GenericName\":\"%s\",\n", _entry->generic_name);
    if (_entry->comment)
        APPEND_STRING_WITH_ESCAPE(string, "\"Comment\":\"%s\",\n", _entry->comment);

    if (g_strcmp0(_entry->type, "Dir") == 0) {
        char* data_uri = get_dir_icon(_entry->entry_path);
        if (data_uri != NULL) {
            APPEND_STRING_WITH_ESCAPE(string, "\"Icon\":\"%s\",\n", data_uri);
            g_free(data_uri);
        }
    } else if (_entry->icon) {
        char* icon_path = icon_name_to_path(_entry->icon, 48);
        if (icon_path != NULL) {
            APPEND_STRING_WITH_ESCAPE(string, "\"Icon\":\"%s\",\n", icon_path);
            g_free(icon_path);
        }
    }
    if (_entry->hidden)
        g_string_append(string, "\"Hidden\":true,\n");

    if (_entry->only_show_in) {
        char* array = to_json_array(_entry->only_show_in);
        if (array != NULL) {
            g_string_append_printf(string, "\"OnlyShowIn\":%s,\n", array);
            g_free(array);
        }
    } else if (_entry->not_show_in) {
        char* array = to_json_array(_entry->not_show_in);
        if (array != NULL) {
            g_string_append_printf(string, "\"NotShowIn\":%s,\n", array);
            g_free(array);
        }
    }

    if (g_strcmp0(_entry->type, "Application") == 0) {
        ApplicationEntry* entry = (ApplicationEntry*) _entry;
        if (entry->try_exec)
            APPEND_STRING_WITH_ESCAPE(string, "\"TryExec\":\"%s\",\n", entry->try_exec);
        if (entry->exec) {
            APPEND_STRING_WITH_ESCAPE(string, "\"Exec\":\"%s\",\n", entry->exec);
        }
        if (entry->exec_flag != ' ')
            g_string_append_printf(string, "\"ExecFlag\":\"%c\",\n", entry->exec_flag);
        if (entry->path)
            APPEND_STRING_WITH_ESCAPE(string, "\"Path\":\"%s\",\n", entry->path);
        if (entry->terminal)
            g_string_append(string, "\"Terminal\":true,\n");
        if (entry->actions) {
            char* array = to_json_array(entry->actions);
            if (array) {
                g_string_append_printf(string, "\"Actions\":%s,\n", array);
                g_free(array);
            }
        }
        if (entry->mime_type) {
            char* array = to_json_array(entry->mime_type);
            g_string_append_printf(string, "\"MimeType\":%s,\n", array);
            g_free(array);
        }
        if (entry->categories) {
            /*char* array = to_json_array(entry->categories);*/
            char* array = get_deepin_categories(_entry->entry_path, entry->categories);
            g_string_append_printf(string, "\"Categories\":%s,\n", array);
            g_free(array);
        }
        if (entry->keywords) {
            char* array = to_json_array(entry->keywords);
            g_string_append_printf(string, "\"Keywords\":%s,\n", array);
            g_free(array);
        }
        if (entry->startup_notify)
            g_string_append(string, "\"StartupNotify\":true,\n");
        if (entry->startup_wmclass)
            APPEND_STRING_WITH_ESCAPE(string, "\"StartupWMClass\":\"%s\",\n", entry->startup_wmclass);

    } else if (g_strcmp0(_entry->type, "Link") == 0) {
        LinkEntry *entry = (LinkEntry*) _entry;
        if (entry->url)
            APPEND_STRING_WITH_ESCAPE(string, "\"URL\":\"%s\",\n", entry->url);
    } else if (g_strcmp0(_entry->type, "File") == 0) {
        FileEntry *entry = (FileEntry*) _entry;
        if (entry->exec)
            g_string_append_printf(string, "\"Exec\":\"%s\",\n", entry->exec);
    } else if (g_strcmp0(_entry->type, "Dir") == 0) {
        DirectoryEntry *entry = (DirectoryEntry*) _entry;
        if (entry->files)
            g_string_append_printf(string, "\"Files\":%s,\n", entry->files);
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
        g_free(entry->version);
        g_free(entry->name);
        g_free(entry->generic_name);
        g_free(entry->comment);
        g_free(entry->icon);
        g_strfreev(entry->only_show_in);
        g_strfreev(entry->not_show_in);

        if (g_strcmp0(entry->type, "Application") == 0) {
            g_free(((ApplicationEntry*)entry)->try_exec);
            g_free(((ApplicationEntry*)entry)->exec);
            g_free(((ApplicationEntry*)entry)->path); 
            g_strfreev(((ApplicationEntry*)entry)->actions);
            g_strfreev(((ApplicationEntry*)entry)->mime_type); 
            g_strfreev(((ApplicationEntry*)entry)->categories);
            g_strfreev(((ApplicationEntry*)entry)->keywords);
            g_free(((ApplicationEntry*)entry)->startup_wmclass);
        } else if (g_strcmp0(entry->type, "Link") == 0) {
            g_free(((LinkEntry*)entry)->url);
        } else if (g_strcmp0(entry->type, "File") == 0) {
            g_free(((FileEntry*)entry)->exec);
        } else if (g_strcmp0(entry->type, "Dir") == 0) {
            g_free(((DirectoryEntry*)entry)->files);
        } else {
            g_assert_not_reached();
        }

        g_free(entry->type);
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

char* move_to_desktop(const char* path)
{
    char* desktop_dir = get_desktop_dir(FALSE);
    char* dir = g_path_get_dirname(path);

    if (g_strcmp0(desktop_dir, dir) == 0) {
        g_free(desktop_dir);
        g_free(dir);
        return NULL;
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


    char *cmd = g_strdup_printf("mv \'%s\' \'%s\'", path, new_path);
    g_spawn_command_line_sync(cmd, NULL, NULL, NULL, NULL);
    g_free(cmd);

    return new_path;
}
