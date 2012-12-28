#Copyright (c) 2011 ~ 2012 Deepin, Inc.
#              2011 ~ 2012 snyh
#
#Author:      snyh <snyh@snyh.org>
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

FILE_TYPE_APP = 0
FILE_TYPE_FILE = 1
FILE_TYPE_DIR = 2
FILE_TYPE_RICH_DIR = 3

create_item = (entry) ->
    w = null
    Id = DCore.DEntry.get_id(entry)
    Type = DCore.DEntry.get_type(entry)
    switch Type
        when FILE_TYPE_APP
            w = new Application(entry)
        when FILE_TYPE_FILE
            w = new NormalFile(entry)
        when FILE_TYPE_DIR
            w = new Folder(entry)
        when FILE_TYPE_RICH_DIR
            w = new RichDir(entry)
        else
            echo "don't support type"

    if w? then div_grid.appendChild(w.element)
    return w


clear_desktop_items = ->
    Widget.look_up(i)?.destroy() for i in all_item
    all_item.splice(0)
    return


load_desktop_all_items = ->
    clear_desktop_items()

    for e in DCore.Desktop.get_desktop_entries()
        w = create_item(e)
        if w? then all_item.push(w.id)

    place_desktop_items()
    return
