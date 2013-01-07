#Copyright (c) 2011 ~ 2012 Deepin, Inc.
#              2011 ~ 2012 snyh
#
#Author:       snyh <snyh@snyh.org>
#Maintainer:   Cole <phcourage@gmail.com>
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
    DCore.signal_connect("trash_count_changed", do_trash_update)
    DCore.signal_connect("cut_completed", do_cut_completed)
    DCore.signal_connect("lost_focus", do_desktop_lost_focus)

    DCore.signal_connect("workarea_changed", do_workarea_changed)
    DCore.Desktop.notify_workarea_size()


do_item_delete = (data) ->
    id = DCore.DEntry.get_id(data.entry)
    w = Widget.look_up(id)
    if w?
        cancel_item_selected(w)
        all_item.remove(id)
        w.destroy()

    update_selected_item_drag_image()


do_item_update = (data) ->
    id = DCore.DEntry.get_id(data.entry)
    w = Widget.look_up(id)
    if w?
        w.item_update?()
    else
        w = create_item(data.entry)
        if w?
            move_to_anywhere(w)
            all_item.push(w.id)


do_item_rename = (data) ->
    sel = false
    old_id = DCore.DEntry.get_id(data.old)
    new_id = DCore.DEntry.get_id(data.new)
    w = Widget.look_up(old_id)
    if w?
        sel = cancel_item_selected(w)
        all_item.remove(old_id)
        w.destroy()

    update_position(old_id, new_id)

    w = create_item(data.new)
    if w?
        move_to_anywhere(w)
        all_item.push(w.id)
        if sel then set_item_selected(w)

    update_selected_item_drag_image()


do_trash_update = ->
    w = Widget.look_up("Trash_Virtual_Dir")
    if w?
        w.item_update()


do_cut_completed = ->
    echo "do_cut_completed"
    for i in all_item
        w = Widget.look_up(i)
        if w? and w.modifiable == true then w.display_not_cut()


do_desktop_lost_focus = ->
    echo "do_desktop_lost_focus"
    if last_widget.length > 0 then Widget.look_up(last_widget)?.display_blur()


do_workarea_changed = (allo) ->
    update_gird_position(allo.x + 4, allo.y + 4, allo.width - 8, allo.height - 8)
