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
#include "dentry/entry.h"

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
    if (path == NULL)
        return NULL;
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

char* icon_name_to_path_with_check_xpm(const char* name, int size)
{
    char* path = icon_name_to_path(name, size);
    char* ret = check_xpm(path);
    g_free(path);
    return ret;
}


char* icon_name_to_path(const char* name, int size)
{
    if (g_path_is_absolute(name))
        return g_strdup(name);
    g_return_val_if_fail(name != NULL, NULL);

    int pic_name_len = strlen(name);
    char* ext = strchr(name, '.');
    if (ext != NULL) {
        if (g_ascii_strcasecmp(ext+1, "png") == 0 || g_ascii_strcasecmp(ext+1, "svg") == 0 || g_ascii_strcasecmp(ext+1, "jpg") == 0) {
            pic_name_len = ext - name;
            g_debug("desktop's Icon name should an absoulte path or an basename without extension");
        }
    }

    char* pic_name = g_strndup(name, pic_name_len);
    GtkIconTheme* them = gtk_icon_theme_get_default(); //do not ref or unref it

    // This info must not unref, owned by gtk !!!!!!!!!!!!!!!!!!!!!
    GtkIconInfo* info = gtk_icon_theme_lookup_icon(them, pic_name, size, GTK_ICON_LOOKUP_GENERIC_FALLBACK);
    g_free(pic_name);
    if (info) {
        char* path = g_strdup(gtk_icon_info_get_filename(info));
        g_object_unref(info);
        return path;
    } else {
        return NULL;
    }
}


char* lookup_icon_by_gicon(GIcon* icon)
{
    char* icon_path = NULL;

    char* icon_infos = g_icon_to_string(icon);
    char** types = g_strsplit(icon_infos, " ", -1);
    g_free(icon_infos);

    char** tmp = types;
    if (*tmp != NULL) tmp++;

    while (*tmp != NULL && icon_path == NULL) {
        icon_path = icon_name_to_path(*(tmp++), 48);
    }

    g_strfreev(types);

    return icon_path;
}

void set_default_theme(const char* theme)
{
    GtkSettings* setting = gtk_settings_get_default();
    g_object_set(setting, "gtk-icon-theme-name", theme, NULL);
}

char* get_desktop_dir(gboolean update)
{
    static char* dir = NULL;
    if (update || dir == NULL) {
        if (dir != NULL)
            g_free(dir);
        const char* cmd = "sh -c '. ~/.config/user-dirs.dirs && echo $XDG_DESKTOP_DIR'";
        g_spawn_command_line_sync(cmd, &dir, NULL, NULL, NULL);
        g_strchomp(dir);
    }
    return g_strdup(dir);
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





//-------templates---------//

#if 0
static XdgDirEntry *cached_xdg_dirs = NULL;
static GFileMonitor *cached_xdg_dirs_monitor = NULL;
#endif

#define DEFAULT_NAUTILUS_DIRECTORY_MODE (0755)
#define DESKTOP_DIRECTORY_NAME "Desktop"



char *
nautilus_get_xdg_dir (const char *type)
{
    int i;

#if 0
    if (cached_xdg_dirs == NULL) {
        update_xdg_dir_cache ();
    }


    for (i = 0 ; cached_xdg_dirs != NULL && cached_xdg_dirs[i].type != NULL; i++) {
        if (strcmp (cached_xdg_dirs[i].type, type) == 0) {
            return g_strdup (cached_xdg_dirs[i].path);
        }
    }
#endif

    if (strcmp ("DESKTOP", type) == 0) {
        return g_build_filename (g_get_home_dir (), DESKTOP_DIRECTORY_NAME, NULL);
    }
    if (strcmp ("TEMPLATES", type) == 0) {
        return g_build_filename (g_get_home_dir (), "Templates", NULL);
    }
    
    return g_strdup (g_get_home_dir ());
}



gboolean
nautilus_should_use_templates_directory (void)
{
    char *dir;
    gboolean res;
    
    dir = nautilus_get_xdg_dir ("TEMPLATES");
    res = strcmp (dir, g_get_home_dir ()) != 0;
    g_free (dir);
    return res;
}

char *
nautilus_get_templates_directory (void)
{
    return nautilus_get_xdg_dir ("TEMPLATES");
}

void
nautilus_create_templates_directory (void)
{
    char *dir;

    dir = nautilus_get_templates_directory ();
    if (!g_file_test (dir, G_FILE_TEST_EXISTS)) {
        g_mkdir (dir, DEFAULT_NAUTILUS_DIRECTORY_MODE);
    }
    g_free (dir);
}

char *
nautilus_get_templates_directory_uri (void)
{
    char *directory, *uri;

    directory = nautilus_get_templates_directory ();
    uri = g_filename_to_uri (directory, NULL, NULL);
    g_free (directory);
    return uri;
}



JS_EXPORT_API
ArrayContainer natilus_get_templates_files(void)
{
    ArrayContainer EMPTY_CONTAINER = {0, 0};
    char * c = nautilus_get_templates_directory();
    g_message("%s",c);
    GFile* f = g_file_new_for_path(c);

    g_return_val_if_fail(g_file_query_file_type(f, G_FILE_QUERY_INFO_NONE, NULL) == G_FILE_TYPE_DIRECTORY, EMPTY_CONTAINER);
    char* dir_path = g_file_get_path(f);
    GDir* dir = g_dir_open(dir_path, 0, NULL);
    const char* child_name = NULL;
    GPtrArray* array = g_ptr_array_sized_new(1024);

    for (int i=0; NULL != (child_name = g_dir_read_name(dir)); i++) {
        char* path = g_build_filename(dir_path, child_name, NULL);
        g_message("%s",path);
        g_ptr_array_add(array, g_file_new_for_path(path));
        g_free(path);
    }

    g_dir_close(dir);
    g_free(dir_path);

    ArrayContainer ac;
    ac.num = array->len;
    ac.data = array->pdata;
    g_ptr_array_free(array, FALSE);

    // fs = dentry_list_files(f);

    g_free(c);   
    g_object_unref(f); 
    return ac ;
}