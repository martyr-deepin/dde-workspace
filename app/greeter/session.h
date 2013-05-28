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

#include "jsextension.h"
#include <glib.h>
#include <lightdm.h>

gboolean is_session_valid(const gchar *session);
const gchar* get_first_session();
JS_EXPORT_API ArrayContainer greeter_get_sessions();
JS_EXPORT_API const gchar* greeter_get_session_name(const gchar *key);
JS_EXPORT_API const gchar* greeter_get_session_icon(const gchar *key);
