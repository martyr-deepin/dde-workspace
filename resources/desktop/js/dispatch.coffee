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

create_item = (info) ->
    w = null
    switch info.Type
        when "Application"
            w = new DesktopEntry info.Name, info.Icon, info.Exec, info.EntryPath
        when "File"
            w = new NormalFile info.Name, info.Icon, info.Exec, info.EntryPath
        when "Dir"
            w = new Folder info.Name, info.Icon, info.exec, info.EntryPath
        else
            echo "don't support type"

    div_grid.appendChild(w.element)
    return w


load_desktop_all_items = ->
    for info in DCore.Desktop.get_desktop_items()
        w = create_item(info)
        if w?
            move_to_anywhere(w)


reflesh_desktop_new_items = ->
    for info in DCore.Desktop.get_desktop_items()
        if not Widget.look_up(info.EntryPath)?
            w = create_item(info)
            if w?
                move_to_anywhere(w)
    return

reflesh_desktop_del_items = ->
    items= DCore.Desktop.get_desktop_items()
    for i, v of Widget.object_table
        exists = false
        for info in items
            if info.EntryPath == i
                exists = true
                break
        if exists == false
            v.destroy()
    return
