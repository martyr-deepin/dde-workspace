/**
 * Copyright (c) 2011 ~ 2012 Deepin, Inc.
 *               2011 ~ 2012 Long Wei
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
#include <glib.h>
#include <glib/gstdio.h>
#include <lightdm.h>
#include "utils.h"
#include "jsextension.h"

gboolean is_user_valid(const gchar *username);
JS_EXPORT_API const gchar* greeter_get_default_user();
JS_EXPORT_API ArrayContainer greeter_get_users();
JS_EXPORT_API const gchar* greeter_get_user_background(const gchar* name);
JS_EXPORT_API const gchar* greeter_get_user_session(const gchar* name);
const gchar* get_first_user();
