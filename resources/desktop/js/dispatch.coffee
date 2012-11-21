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
            w = new Application info.Name, info.Icon, info.Exec, info.EntryPath
        when "File"
            w = new NormalFile info.Name, info.Icon, info.Exec, info.EntryPath
        when "Dir"
            w = new Folder info.Name, info.Icon, info.exec, info.EntryPath
        else
            echo "don't support type"

    if w? then div_grid.appendChild(w.element)
    return w


load_desktop_all_items = ->
    all_item.splice(0)
    for info in DCore.Desktop.get_desktop_items()
        w = create_item(info)
        all_item.push(w.id)
        if w?
            move_to_anywhere(w)
