/**
 * Copyright (c) 2011 ~ 2014 Deepin, Inc.
 *               2013 ~ 2014 jouyouyun
 *
 * Author:      jouyouyun <jouyouwen717@gmail.com>
 * Maintainer:  jouyouyun <jouyouwen717@gmail.com>
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
#include "zone.h"

#define COMMANDS_SCHEMA_ID "org.compiz.commands"
#define COMMANDS_SCHEMA_PATH "/org/compiz/profiles/deepin/plugins/commands/"
#define SCALE_SCHEMA_ID "org.compiz.scale"
#define SCALE_SCHEMA_PATH "/org/compiz/profiles/deepin/plugins/scale/"

#define SCALE_EDGE_KEY "initiate-edge"

const char *edge_map[] = {
    KEY_LEFTUP":TopLeft",
    KEY_RIGHTDOWN":BottomRight",
    KEY_LEFTDOWN":BottomLeft",
    KEY_RIGHTUP":TopRight",
    NULL
} ;

const char *edge_command_map[] = {
    KEY_LEFTUP":command20",
    KEY_LEFTDOWN":command19",
    KEY_RIGHTUP":command18",
    KEY_RIGHTDOWN":command17",
    NULL
} ;

const char *edge_command_run_map[] = {
    KEY_LEFTUP":run-command20-edge",
    KEY_LEFTDOWN":run-command19-edge",
    KEY_RIGHTUP":run-command18-edge",
    KEY_RIGHTDOWN":run-command17-edge",
    NULL
} ;

static char *get_command_key(const char *str, const char **list);
static gboolean set_commands(const char *key, const char *value, gboolean scale);
static gboolean set_scale (const char *key, const char *value);

static char *
get_command_key(const char *str, const char **list)
{
    if (str == NULL || list == NULL) {
        return NULL;
    }

    gint i = 0;
    char *ret = NULL;

    for (; list[i] != NULL; i++) {
        gchar **strs = g_strsplit(list[i], ":", 0);

        if (g_strcmp0(str, strs[0]) == 0) {
            ret = g_strdup(strs[1]);
            g_strfreev(strs);
            break;
        }
    }

    return ret;
}

static gboolean 
set_commands(const char *key, const char *value, gboolean scale)
{
    g_debug("Set commands key: %s, value: %s\n", key, value);

    gchar *ret = get_command_key(key, edge_command_map);

    if (ret == NULL) {
        return FALSE;
    }

    g_debug("Commands Real Key: %s\n", ret);

    GSettings *cmdSettings = g_settings_new_with_path(COMMANDS_SCHEMA_ID, COMMANDS_SCHEMA_PATH);
    gboolean ok = g_settings_set_string(cmdSettings, ret, value);
    g_free(ret);
    ret = NULL;

    ret = get_command_key(key, edge_command_run_map);

    if (ret == NULL) {
        return FALSE;
    }

    if (scale == TRUE) {
        // Disable cmdSettings edge value, otherwise scaleSettings value invalid
        g_settings_set_string(cmdSettings, ret, "");
    } else {
        gchar *v = get_command_key(key, edge_map);

        if (v == NULL) {
            g_free(ret);
            return FALSE;
        }

        g_settings_set_string(cmdSettings, ret, v);
        g_free(v);
    }

    g_free(ret);

    g_settings_sync();

    return ok;
}

static gboolean 
set_scale (const char *key, const char *value)
{
    g_debug("Set scale key: %s, value: %s\n", key, value);

    gchar *ret = get_command_key(key, edge_map);

    if (ret == NULL) {
        return FALSE;
    }

    g_debug("Scale Real Value: %s\n", ret);

    GSettings *scaleSettings = g_settings_new_with_path(SCALE_SCHEMA_ID, SCALE_SCHEMA_PATH);
    gboolean ok = g_settings_set_string(scaleSettings, SCALE_EDGE_KEY, ret);
    g_free(ret);

    if (ok) {
        g_debug("Clear Commands Key: %s\n", key);
        set_commands(key, "", TRUE);
    }

    return ok;
}

gboolean 
compiz_set(const char *key, const char *value)
{
    if (key == NULL) {
        return FALSE;
    }

    if (g_strcmp0(value, VAL_WORKSPACE) == 0) {
        return set_scale(key, value);
    }

    return set_commands(key, value, FALSE);
}
