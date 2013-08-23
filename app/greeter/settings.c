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

#define GREETER_SCHEAM_ID "com.deepin.dde.greeter"

gboolean _get_face_recognition_login_setting()
{
    GSettings* settings = g_settings_new(GREETER_SCHEAM_ID);
    gboolean uses_camera = g_settings_get_boolean(settings,
                                                  "face-recognition-login");
    g_object_unref(settings);
    return uses_camera;
}


JS_EXPORT_API
gboolean lock_use_face_recognition_login()
{
    /* return _has_camera() && _get_face_recognition_login_setting(); */
    return TRUE;
}


JS_EXPORT_API
gboolean greeter_use_face_recognition_login()
{
    /* return _has_camera() && _get_face_recognition_login_setting(); */
    return TRUE;
}
