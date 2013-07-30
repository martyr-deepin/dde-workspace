/**
 * Copyright (c) 2011 ~ 2012 Deepin, Inc.
 *               2011 ~ 2012 snyh
 *
 *Author:      bluth <yuanchenglu@linuxdeepin.com>
 *Maintainer:  bluth <yuanchenglu@linuxdeepin.com>
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
#include "templates.h"

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


