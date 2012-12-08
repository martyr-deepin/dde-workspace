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
#include "xdg_misc.h"
#include "jsextension.h"
#include "utils.h"
#include "launcher.h"
#include "dock_config.h"
#include "desktop_file_matcher.h"
#include <string.h>

#define APPS_INI "dock/apps.ini"
static GKeyFile* k_apps = NULL;

static
void post_app_info(const char* app_id)
{
    char* exec = g_key_file_get_string(k_apps, app_id, "Exec", NULL);
    char* icon = g_key_file_get_string(k_apps, app_id, "Icon", NULL);
    char* icon_path = icon_name_to_path(icon, 48);
    g_free(icon);
    char* name = g_key_file_get_string(k_apps, app_id, "Name", NULL);

    js_post_message("launcher_added",
            "{\"Id\": \"%s\","
            "\"Icon\": \"%s\","
            "\"Exec\": \"%s\","
            "\"Name\": \"%s\"}",
            app_id,
            json_escape_with_swap(&icon_path),
            json_escape_with_swap(&exec),
            json_escape_with_swap(&name)
            );

    g_free(exec);
    g_free(icon_path);
    g_free(name);
}


static
char* get_app_id(ApplicationEntry* entry)
{
    char* basename = g_path_get_basename(entry->base.entry_path);
    basename[strlen(basename) - 8 /*strlen(".desktop")*/] = '\0';
    if (is_app_in_white_list(basename)) {
        return basename;
    } else {
        g_free(basename);

        char* exec = g_strdup(entry->exec);
        for (int i=0; i<strlen(exec); i++) {
            if (exec[i] == ' ') {
                exec[i] = '\0';
                break;
            }
        }
        char* exec_name = g_path_get_basename(exec);
        g_free(exec);

        return exec_name;
    }
}

void update_dock_apps()
{
    gsize size = 0;
    char** groups = g_key_file_get_groups(k_apps, &size);
    for (gsize i=0; i<size; i++) {
        post_app_info(groups[i]);
    }
    g_strfreev(groups);
}

void init_launchers()
{
    if (k_apps == NULL) {
        k_apps = load_app_config(APPS_INI);
        update_dock_apps();
    }
}

static
void write_app_info(ApplicationEntry* entry)
{
    g_assert(k_apps != NULL);

    char* app_id = get_app_id(entry);

    g_key_file_set_string(k_apps, app_id, "Exec", entry->exec);

    g_key_file_set_string(k_apps, app_id, "Icon", entry->base.icon);

    g_key_file_set_string(k_apps, app_id, "Name", entry->base.name);

    g_free(app_id);

    save_app_config(k_apps, APPS_INI);
}


JS_EXPORT_API
void request_dock(const char* path)
{
    BaseEntry* entry =  parse_desktop_entry(path);
    if (entry != NULL && entry->type == AppEntryType) {
        write_app_info((ApplicationEntry*)entry);

        char* app_id = get_app_id((ApplicationEntry*)entry);
        post_app_info(app_id);
        g_free(app_id);
    } else {
        g_warning("request dock %s is invalide %p\n", path, entry);
    }
    desktop_entry_free(entry);
}

JS_EXPORT_API
void request_undock(const char* app_id)
{
    g_key_file_remove_group(k_apps, app_id, NULL);
    save_app_config(k_apps, APPS_INI);
    js_post_message("launcher_deleted", "{\"Id\": \"%s\"}", app_id);
}

JS_EXPORT_API
void try_post_launcher_info(const char* app_id)
{
    if (g_key_file_has_group(k_apps, app_id)) {
        post_app_info(app_id);
    } else {
        printf("try find %s failed \n", app_id);
    }
}
