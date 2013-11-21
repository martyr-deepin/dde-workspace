/**
 * Copyright (c) 2011 ~ 2013 Deepin, Inc.
 *               2011 ~ 2013 Long Wei
 *
 * Author:      Long Wei <yilang2007lw@gmail.com>
 * Maintainer:  Long Wei <yilang2007lw@gamil.com>
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

#ifndef _LOCK_UTIL_H
#define _LOCK_UTIL_H

#include <glib.h>
#include <glib/gstdio.h>
#include <fcntl.h>
#include <pwd.h>
#include "jsextension.h"
#include "dwebview.h"
#include "i18n.h"
#include "utils.h"
#include "X_misc.h"

JS_EXPORT_API const gchar* lock_get_username ();

JS_EXPORT_API gchar* lock_get_user_realname (const gchar* name);

JS_EXPORT_API gchar* lock_get_user_icon (const gchar* name);

JS_EXPORT_API gboolean lock_need_password (const gchar* name);

JS_EXPORT_API gchar* lock_get_date ();

JS_EXPORT_API gboolean lock_detect_capslock ();

JS_EXPORT_API void lock_switch_user ();

JS_EXPORT_API void lock_draw_background (JSValueRef canvas);

gboolean lock_is_guest ();

gboolean lock_is_running ();

void lock_report_pid ();

#endif
