/**
 * Copyright (c) 2011 ~ 2012 Deepin, Inc.
 *               2011 ~ 2012 Liqiang Lee
 *
 * Author:      Liqiang Lee <liliqiang@linuxdeepin.com>
 * Maintainer:  Liqiang Lee <liliqiang@linuxdeepin.com>
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
#include "desktop_action.h"

#define DESKTOP_ACTION_PATTERN ".* Shortcut Group|Desktop Action .*"

struct Action* action_new(char const* name, char const* exec)
{
    struct Action* action = g_new0(struct Action, 1);
    action->name = g_strdup(name);
    action->exec = g_strdup(exec);
    return action;
}


void action_free(struct Action* action)
{
    g_free(action->name);
    g_free(action->exec);
    g_free(action);
}


GPtrArray* get_app_actions(GDesktopAppInfo* app)
{
    GPtrArray* actions = NULL;
    GError* error = NULL;

    GKeyFile* file = g_key_file_new();
    char const* filename = g_desktop_app_info_get_filename(app);
    g_key_file_load_from_file(file, filename, G_KEY_FILE_NONE, &error);

    if (error != NULL) {
        g_warning("[get_actions] %s", error->message);
        g_error_free(error);
        goto out;
    }

    GRegex* desktop_action_pattern = NULL;
    desktop_action_pattern = g_regex_new(DESKTOP_ACTION_PATTERN,
                                         G_REGEX_DUPNAMES
                                         | G_REGEX_OPTIMIZE,
                                         0,
                                         &error
                                        );

    if (error != NULL) {
        g_warning("[get_actions] %s", error->message);
        g_error_free(error);
        goto out;
    }

    gsize len = 0;
    gchar** groups = g_key_file_get_groups(file, &len);

    if (len == 0)
        goto out;

    actions = g_ptr_array_new_with_free_func((GDestroyNotify)action_free);
    for (int i = 0; groups[i] != NULL; ++i) {
        if (g_regex_match(desktop_action_pattern, groups[i], 0, NULL)) {
            gchar* action_name =
                g_key_file_get_locale_string(file,
                                             groups[i],
                                             G_KEY_FILE_DESKTOP_KEY_NAME,
                                             NULL,
                                             &error);
            if (error != NULL) {
                g_warning("[get_actions] %s", error->message);
                g_error_free(error);
                error = NULL;
                continue;
            }

            gchar* exec = g_key_file_get_string(file,
                                                groups[i],
                                                G_KEY_FILE_DESKTOP_KEY_EXEC,
                                                &error);
            if (error != NULL) {
                g_warning("[get_actions] %s", error->message);
                g_error_free(error);
                error = NULL;
                continue;
            }

            g_debug("name: %s, exec: %s", action_name, exec);
            g_ptr_array_add(actions, action_new(action_name, exec));
            g_free(action_name);
            g_free(exec);
        }
    }

out:
    g_strfreev(groups);
    g_key_file_unref(file);

    if (desktop_action_pattern != NULL)
        g_regex_unref(desktop_action_pattern);

    return actions;
}

