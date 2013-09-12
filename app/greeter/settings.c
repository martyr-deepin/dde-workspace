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

#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>

#include <gio/gio.h>

#include "camera.h"
#include "jsextension.h"

#define CONFIG_FILE "/etc/face_login.ini"

gboolean _get_face_recognition_login_setting(const char* username)
{
    gboolean use_face_login = FALSE;
    GKeyFile* config = g_key_file_new();
    GError* err = NULL;
    g_key_file_load_from_file(config, CONFIG_FILE, G_KEY_FILE_NONE, &err);
    if (err != NULL) {
        g_warning("[_get_face_recognition_login_setting] read config file failed: %s", err->message);
        goto out;
    }

    use_face_login = g_key_file_get_boolean(config, "Users", username, &err);
    if (err != NULL)
        g_warning("[_get_face_recognition_login_setting] read config file failed: %s", err->message);

out:
    if (err != NULL)
        g_error_free(err);
    g_key_file_unref(config);
    return use_face_login;
}


gboolean _use_face_recognition_login(char const* username)
{
    return detect_is_enabled && has_camera()
        && _get_face_recognition_login_setting(username);
}


JS_EXPORT_API
gboolean lock_use_face_recognition_login(const char* username)
{
    return _use_face_recognition_login(username);
    return TRUE;
}


JS_EXPORT_API
gboolean greeter_use_face_recognition_login(const char* username)
{
    return _use_face_recognition_login(username);
    return TRUE;
}


static void _webview_ok(char const* username)
{
    static gboolean inited = FALSE;
    if (!inited) {
        g_warning("current user: %s", username);
        if (_use_face_recognition_login(username)) {
            js_post_message_simply("draw", NULL);
            connect_camera();
        }

        inited = TRUE;
    }
}


JS_EXPORT_API
void lock_webview_ok(char const* username)
{
    _webview_ok(username);
}


JS_EXPORT_API
void greeter_webview_ok(char const* username)
{
    _webview_ok(username);
}

