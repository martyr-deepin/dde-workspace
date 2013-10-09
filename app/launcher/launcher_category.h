/**
 * Copyright (c) 2011 ~ 2013 Deepin, Inc.
 *               2011 ~ 2013 Liqiang Lee
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

#ifndef LAUNCHER_CATEGORY_H
#define LAUNCHER_CATEGORY_H

int find_category_id(const char* category_name);
GList* get_deepin_categories(GDesktopAppInfo* info);
const GPtrArray* get_all_categories_array();

#endif /* end of include guard: LAUNCHER_CATEGORY_H */

