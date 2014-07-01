#Copyright (c) 2011 ~ 2012 Deepin, Inc.
#              2011 ~ 2012 snyh
#
#Author:      Cole <phcourage@gmail.com>
#             bluth <yuanchenglu001@gmail.com>
#Maintainer:  Cole <phcourage@gmail.com>
#
#This program is free software; you can redistribute it and/or modify
#it under the terms of the GNU General Public License as published by
#the Free Software Foundation; either version 3 of the License, or
#(at your option) any later version.
#
#This program is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.
#
#You should have received a copy of the GNU General Public License
#along with this program; if not, see <http://www.gnu.org/licenses/>.

set_version_desktop("2.0.3")

create_item_grid()

connect_default_signals()
DCore.Desktop.emit_webview_ok()

load_desktop_all_items()
load_plugins()

place_desktop_items()
place_all_widgets()

DCore.Desktop.test()

#echo "s_width:" + s_width + ",s_height:" + s_height + ",s_offset_x:" + s_offset_x + ",s_offset_y:" + s_offset_y
#echo "cols:" + cols + ",rows:" + rows + ",grid_item_width:" + grid_item_width + ",grid_item_height:" + grid_item_height
