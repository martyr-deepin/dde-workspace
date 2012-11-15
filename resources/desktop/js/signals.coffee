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

connect_default_signals = ->
    DCore.signal_connect("item_update", do_item_update)
    DCore.signal_connect("item_delete", do_item_delete)
    DCore.signal_connect("item_rename", do_item_rename)

    DCore.signal_connect("workarea_changed", do_workarea_changed)
    DCore.Desktop.notify_workarea_size()


do_item_delete = (info) ->
    id = info.id
    Widget.look_up(id)?.destroy()
    for i in all_item
        if i == id
            all_item.splice(i, 1)
            break


do_item_update = (info) ->
    w = Widget.look_up(info.EntryPath)
    if w?
        w.item_update?(info.Icon)
    else
        w = create_item(info)
        if w?
            move_to_anywhere(w)
            all_item.push(w.id)


do_item_rename = (data) ->
    Widget.look_up(data.old_id)?.destroy()
    for i in all_item
        if i == id
            all_item.splice(i, 1)
            break

    update_position(data.old_id, data.info.EntryPath)

    w = create_item(data.info)
    if w?
        move_to_anywhere(w)
        all_item.push(w.id)


do_workarea_changed = (allo) ->
    update_gird_position(allo.x + 4, allo.y + 4, allo.width - 8, allo.height - 8)
