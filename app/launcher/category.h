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
#ifndef _CATEGORY_H_
#define _CATEGORY_H_

#include <glib.h>
#include <gio/gdesktopappinfo.h>

#define CATEGORY_END_TAG -100
#define ALL_CATEGORY_ID (-1)
#define OTHER_CATEGORY_ID (-2)

#define ALL _("All")
#define INTERNET _("Internet")
#define MULTIMEDIA _("Multimedia")
#define GAMES _("Games")
#define GRAPHICS _("Graphics")
#define PRODUCTIVITY _("Productivity")
#define INDUSTRY _("Industry")
#define EDUCATION _("Education")
#define DEVELOPMENT _("Development")
#define SYSTEM _("System")
#define UTILITIES _("Utilities")
#define OTHER _("Other")

typedef int (*SQLEXEC_CB) (void*, int, char**, char**);

const char* get_category_db_path();
const char** get_category_list();
GList* get_deepin_categories(GDesktopAppInfo*);
const GPtrArray* get_all_categories_array();

#endif
