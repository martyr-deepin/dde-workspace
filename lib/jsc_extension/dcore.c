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
#include "utils.h"
#include "xdg_misc.h"
#include "jsextension.h"

//TODO run_command support variable arguments

JS_EXPORT_API
char* dcore_get_theme_icon(const char* name, double size)
{
    return icon_name_to_path_with_check_xpm(name, size);
}

JS_EXPORT_API
JSValueRef dcore_get_plugins(const char* app_name)
{
    JSObjectRef array = json_array_create();
    char* path = g_build_filename(RESOURCE_DIR, app_name, "plugin", NULL);
    char* expected_filename = g_strconcat(app_name, ".js", NULL);

    GDir* dir = g_dir_open(path, 0, NULL);
    if (dir != NULL) {
        JSContextRef ctx = get_global_context();
        const char* file_name = NULL;
        for (int i=0; NULL != (file_name = g_dir_read_name(dir));) {
            if (g_str_equal(expected_filename, file_name)) {
                char* js_path = g_build_filename(path, file_name, NULL);
                JSValueRef v = jsvalue_from_cstr(ctx, js_path);
                g_free(js_path);
                json_array_insert(array, i++, v);
            }
        }

        g_dir_close(dir);
    }

    g_free(expected_filename);
    g_free(path);

    return array;
}
