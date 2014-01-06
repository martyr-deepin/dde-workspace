/**
 * Copyright (c) 2011 ~ 2013 Deepin, Inc.
 *               2013 ~ 2013 Liqiang Lee
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

#ifndef DOCK_H
#define DOCK_H

#include "display_info.h"
#include "utils.h"

#define DOCK_MAJOR_VERSION 0
#define DOCK_MINOR_VERSION 0
#define DOCK_SUBMINOR_VERSION 3
#define DOCK_VERSION STR(DOCK_MAJOR_VERSION)"."STR(DOCK_MINOR_VERSION)"."STR(DOCK_SUBMINOR_VERSION)

#define DOCK_ID_NAME "dock.app.deepin"

void update_position_info();
extern struct DisplayInfo dock;

#endif /* end of include guard: DOCK_H */

