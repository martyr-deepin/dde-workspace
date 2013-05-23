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
#include <string.h>
#include <sys/stat.h>
#include "utils.h"
#include "xdg_misc.h"
#include "jsextension.h"

//TODO run_command support variable arguments

JS_EXPORT_API
char* dcore_get_theme_icon(const char* name, double size)
{
    return icon_name_to_path_with_check_xpm(name, size);
}


PRIVATE
const char* _is_plugin(const char* path, const char* dir_name)
{
    GDir* plugin_dir = g_dir_open(path, 0, NULL);
    char* plugin_file_name = g_strconcat(dir_name, ".js", NULL);
    const char* filename = NULL;

    if (plugin_dir != NULL) {
        const char* file_name = NULL;
        while ((file_name = g_dir_read_name(plugin_dir)) != NULL) {
            if (g_str_equal(plugin_file_name, file_name)) {
                filename = file_name;
                break;
            }
        }
    }

    g_dir_close(plugin_dir);
    g_free(plugin_file_name);

    return filename;
}


#define IS_DIR(path) g_file_test(path, G_FILE_TEST_IS_DIR)


JS_EXPORT_API
JSValueRef dcore_get_plugins(const char* app_name)
{
    JSObjectRef array = json_array_create();
    JSContextRef ctx = get_global_context();
    char* path = g_build_filename(RESOURCE_DIR, app_name, "plugin", NULL);

    GDir* dir = g_dir_open(path, 0, NULL);
    if (dir != NULL) {
        const char* file_name = NULL;
        for (int i=0; NULL != (file_name = g_dir_read_name(dir));) {
            char* full_path = g_build_filename(path, file_name, NULL);
            const char* filename = NULL;

            if (IS_DIR(full_path) && (filename = _is_plugin(full_path, file_name)) != NULL) {
                char* js_path = g_build_filename(full_path, filename, NULL);
                JSValueRef v = jsvalue_from_cstr(ctx, js_path);
                g_free(js_path);
                json_array_insert(array, i++, v);
            }

            g_free(full_path);
        }

        g_dir_close(dir);
    }

    g_free(path);

    return array;
}
