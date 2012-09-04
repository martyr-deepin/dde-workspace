#include <glib.h>
#include <gio/gio.h>
#include <glib/gstdio.h>
#include <stdio.h>
#include <string.h>

#include "desktop_entry.h"

// Base Dir Specification
// http://standards.freedesktop.org/basedir-spec/basedir-spec-latest.html

#define GET_ENV(key) g_environ_getenv(g_get_environ(), key)

#define XDG_DATA_HOME GET_ENV("XDG_DATA_HOME") 
#define XDG_CONFIG_HOME g_environ_getenv(g_get_environ(), "XDG_CONFIG_HOME")
#define XDG_DATA_DIRS g_environ_getenv(g_get_environ(), "XDG_DATA_DIRS")
#define XDG_CONFIG_DIRS g_environ_getenv(g_get_environ(), "XDG_CONFIG_DIRS")
#define XDG_CACHE_HOME g_environ_getenv(g_get_environ(), "XDG_CACHE_HOME")
#define XDG_RUNTIME_DIR g_environ_getenv(g_get_environ(), "XDG_RUNTIME_DIR")


const char* DEFAULT_THEME = "Deepin";
const char* DESKTOP_NAME = "Desktop";


// Icon Theme Specification
// http://standards.freedesktop.org/icon-theme-spec/icon-theme-spec-latest.html

const char* type_to_dir(const char* type)
{
    if (g_strcmp0(type, "Actions") == 0) {
        return "actions";
    } else if (g_strcmp0(type, "Animations") == 0) {
        return "animations";
    } else if (g_strcmp0(type, "Application") == 0) {
        return "apps";
    } else if (g_strcmp0(type, "Categories") == 0) {
        return "categories";
    } else if (g_strcmp0(type, "Devices") == 0) {
        return "Devices";
    } else if (g_strcmp0(type, "Emblems") == 0) {
        return "emblems";
    } else if (g_strcmp0(type, "Emotes") == 0) {
        return "emotes";
    } else if (g_strcmp0(type, "International") == 0) {
        return "intl";
    } else if (g_strcmp0(type, "MimeTypes") == 0) {
        return "mimetypes";
    } else if (g_strcmp0(type, "Places") == 0) {
        return "places";
    } else if (g_strcmp0(type, "Status") == 0) {
        return "status";
    } else {
        return NULL;
    }
}


/*
 * http://standards.freedesktop.org/icon-naming-spec/icon-naming-spec-latest.html
 */

char** list_base() 
{
    char *home = g_build_filename(GET_ENV("HOME"), ".icons", NULL);
    GString *str = g_string_new(home);
    g_free(home);


    const char* dir_str = XDG_DATA_DIRS;
    if (dir_str != NULL) {
        char **dirs = g_strsplit(dir_str, ":", -1);
        char **tmp = dirs;
        while (*tmp != NULL) {
            g_string_append_printf(str, ":%s/icons", *(tmp++));
        }
        g_strfreev(dirs);
    }

    dir_str = XDG_DATA_HOME;
    if (dir_str != NULL) {
        char **dirs = g_strsplit(dir_str, ":", -1);
        char **tmp = dirs;
        while (*tmp != NULL) {
            g_string_append_printf(str, ":%s/icons", *(tmp++));
        }
        g_strfreev(dirs);
    }



    g_string_append(str, ":/usr/share/pixmaps");

    char** ret = g_strsplit(str->str, ":", -1);
    g_string_free(str, TRUE);

    return ret;
}

char** list_theme(const char* theme)
{
    char* tmp = g_strdup_printf("%s:Faenza:gnome:hicolor", theme);
    char** ret = g_strsplit(tmp, ":", -1);
    g_free(tmp);
    return ret;
}

/*
 * TODO: write the gen_size.py
 * generate by gen_size.py
 */
char** list_size(int size)
{
    static char *s_8[] = {"8x8", "16x16", "32x32", NULL};
    static char *s_16[] = {"16x16", "16x16", "32x32", NULL};
    static char *s_32[] = {"32x32", "16x16", "32x32", NULL};
    static char *s_48[] = {"48x48", "16x16", "32x32", NULL};
    static char *s_64[] = {"64x64", "16x16", "32x32", NULL};
    static char *s_128[] = {"128x128", "16x16", "32x32", NULL};
    static char *s_256[] = {"256x256", "16x16", "32x32", NULL};
    switch (size) {
        case 8: return s_8;
        case 16: return s_16;
        case 32: return s_32;
        case 48: return s_48;
        case 64: return s_64;
        case 128: return s_128;
        case 256: return s_256;
        default: return s_32;
    }
} 
char* find_first_exists(char *base[], char *theme[], char* size[],
        const char* type, const char* name, char* ext[])
{
    char **_base = base;
    char **_theme = theme;
    char **_size = size;
    char **_ext = ext;

    char* img = NULL;
    char* path = NULL;

    do { /* base */
        do { /* theme */
            do { /*size*/
                do { /*ext*/
                    img = g_strdup_printf("%s.%s", name, *_ext); 
                    path = g_build_filename(*_base, *_theme, *_size, type, img, NULL); 
                    g_free(img); 
                    if (g_file_test(path, G_FILE_TEST_EXISTS)) 
                        return path; 
                    else 
                        g_free(path); 

                } while (*(++_ext) != NULL);
                _ext = ext;

            } while (*(++_size) != NULL);
            _size = size;

        } while (*(++_theme) != NULL);
        _theme = theme;

    } while (*(++_base) != NULL);

    return NULL;
}

#include <gtk/gtk.h>
static
char* lookup_icon(const char* theme, 
        const char* type, 
        const char* name, 
        const int size) 
{
    GtkIconTheme* ithem = gtk_icon_theme_get_default();
    GtkIconInfo* info = gtk_icon_theme_lookup_icon(ithem,
            name, size, 1 << 3);
    char* path = gtk_icon_info_get_filename(info);

    /*char **bases = list_base();*/
    /*char **themes = list_theme(theme);*/
    /*char **sizes = list_size(size);*/
    /*static char *exts[] = { "png", "svg", "xpm", NULL};*/

    /*char* path = find_first_exists(bases, themes, sizes, type_to_dir(type), name, exts);*/
    /*g_strfreev(bases);*/
    /*g_strfreev(themes);*/
    if (path == NULL) {
        printf("Lookup icon failed %s!\n", name);
        path = g_strdup("notfound");
    }
    return path;
}

char* get_folder_open_icon()
{
    return lookup_icon(gtk_icon_theme_get_default(), NULL, "folder-open", 48);
}
char* get_folder_close_icon()
{
    return lookup_icon(gtk_icon_theme_get_default(), NULL, "folder-close", 48);
}


char* lookup_icon_by_file(const char* path)
{
    char* icon_path = NULL;
    GFile* file = g_file_new_for_path(path);
    GFileInfo *info = g_file_query_info(file, "standard::icon", G_FILE_QUERY_INFO_NONE, NULL, NULL);
    if (info != NULL) {
        GIcon* icon = g_file_info_get_icon(info);
        char* str = g_icon_to_string(icon);
        /*g_object_unref(icon);*/

        char** types = g_strsplit(str, " ", -1);
        g_free(str);

        char** tmp = types;
        if (*tmp != NULL) tmp++;
        /*if (*tmp != NULL) tmp++;*/

        while (*(tmp++) != NULL) {
            icon_path = lookup_icon(DEFAULT_THEME, "MimeTypes", *tmp, 48);
            if (g_strcmp0(icon_path, "notfound") != 0)
                break;
        }

        g_strfreev(types);
        g_object_unref(info);
    }
    g_object_unref(file);

    return icon_path;
}


const char* item_format = "{"
    "\"type\": \"%s\","
    "\"name\": \"%s\","
    "\"icon\": \"%s\","
    "\"exec\": \"%s\","
    "\"path\": \"%s\""
"}";

static
char* parse_normal_file(const char* path)
{
    gboolean is_dir = g_file_test(path, G_FILE_TEST_IS_DIR);

    char* name = g_path_get_basename(path);
    char* icon = lookup_icon_by_file(path);
    char* ret = NULL;
    char* quote_path = g_shell_quote(path);
    char* exec = g_strdup_printf("xdg-open %s", quote_path);
    g_free(quote_path);
    if (is_dir) 
        ret = g_strdup_printf(item_format, "Dir", name, icon, exec, path);
    else
        ret = g_strdup_printf(item_format, "File", name, icon, exec, path);
    g_free(name);
    g_free(icon);
    g_free(exec);
    return ret;
}


static
char* parse_desktop_entry(const char* path)
{
    //TODO: not all .desktop file has "Name" "Icon" "Exec" "Type" field

    char *group = "Desktop Entry";
    GKeyFile *de = g_key_file_new();
    if (!g_key_file_load_from_file(de, path, G_KEY_FILE_NONE, NULL)) {
        g_assert(!"shoud an desktip file");
    } 

    char* type_name = g_key_file_get_value(de, group, "Type", NULL);
    if (type_name == NULL) 
        return NULL;
    char* icon_name = g_key_file_get_value(de, group, "Icon", NULL);
    if (icon_name == NULL) {
        g_free(type_name);
        return NULL;
    }

    char* icon = NULL;
    if (g_path_is_absolute(icon_name)) {
        icon = icon_name;
        g_printf("abs path: %s\n", icon_name);
    } else {
        icon = lookup_icon(DEFAULT_THEME, type_name, icon_name, 48);
        g_free(icon_name);
        g_printf("not abs path: %s\n", icon_name);
    }
    g_free(type_name);
    g_assert(icon_name != NULL);

    char* name = g_key_file_get_value(de, group, "Name", NULL);

    char* exec = g_key_file_get_value(de, group, "Exec", NULL);

    char* result = g_strdup_printf(item_format, "Entry", name, icon, exec, path);

    if (icon != icon_name)
        g_free(icon);
    g_free(name);
    g_free(exec);
    return result;
}

char* parse_desktop_item(const char* path)
{
    if (g_str_has_suffix(path, ".desktop")) {
        return parse_desktop_entry(path);
    } else {
        return parse_normal_file(path);
    }
}


char* get_desktop_entries()
{
    GString *content = g_string_new("[");

    char* base_dir = g_build_filename(GET_ENV("HOME"), DESKTOP_NAME, NULL);
    GDir *dir =  g_dir_open(base_dir, 0, NULL);
    const char* filename = NULL;

    char path[1000];
    while ((filename = g_dir_read_name(dir)) != NULL) {

        if (filename[0] == '.') 
            continue;

        g_sprintf(path, "%s/%s", base_dir, filename);

        char* info = parse_desktop_item(path);
        if (info == NULL)
            continue;
        g_string_append(content, info);
        g_string_append_c(content, ',');
        g_free(info);
    }

    g_free(base_dir);
    content = g_string_overwrite(content, content->len-1, "]");
    return content->str;
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

char* get_desktop_dir(gboolean update)
{
    static const char* dir = NULL;
    if (update) {
        /*xdg_use_dir_update();*/
        /*g_free(dir);*/
        // TODO:
        dir = g_build_filename(GET_ENV("HOME"), "Desktop", NULL);
    }
    return g_strdup(dir);
}
