#Copyright (c) 2011 ~ 2014 Deepin, Inc.
#              2011 ~ 2014 snyh
#
#Author:       snyh <snyh@snyh.org>
#Maintainer:   Cole <phcourage@gmail.com>
#             bluth <yuanchenglu001@gmail.com>
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


# remember the last widget which been operated last time whether has focus
last_widget_has_focus = false

connect_default_signals = ->
    DCore.signal_connect("item_update", do_item_update)
    DCore.signal_connect("item_delete", do_item_delete)
    DCore.signal_connect("item_rename", do_item_rename)
    DCore.signal_connect("trash_count_changed", do_trash_update)
    DCore.signal_connect("cut_completed", do_cut_completed)
    DCore.signal_connect("lost_focus", do_desktop_lost_focus)
    DCore.signal_connect("get_focus", do_desktop_get_focus)
    DCore.signal_connect("desktop_config_changed", do_desktop_config_changed)
    DCore.signal_connect("workarea_changed", do_workarea_changed)


do_item_delete = (data) ->
    echo "do_item_delete"
    id = DCore.DEntry.get_id(data.entry)
    if (w = Widget.look_up(id))?
        delete_item(w)
        dsc_e = DCore.DEntry.create_by_path("#{desktop_path}/deepin-software-center.desktop")
        dsc_id = DCore.DEntry.get_id(dsc_e)
        #if(id == dsc_id)
            #DCore.Desktop.set_config_boolean("show-dsc-icon",false)
        update_selected_item_drag_image()


do_item_update = (data) ->
    echo "do_item_update"
    id = DCore.DEntry.get_id(data.entry)
    if (w = Widget.look_up(id))?
        w.set_entry(data.entry)
        w.item_update?()
    else if (w = create_item(data.entry))?
        all_item.push(w.get_id())
        move_to_anywhere(w)
        #dsc_e = DCore.DEntry.create_by_path("#{desktop_path}/deepin-software-center.desktop")
        #dsc_id = DCore.DEntry.get_id(dsc_e)
        #if(id == dsc_id)
            #DCore.Desktop.set_config_boolean("show-dsc-icon",true)

    if w? then w.item_hint?()


do_item_rename = (data) ->
    sel = false
    old_id = DCore.DEntry.get_id(data.old)
    new_id = DCore.DEntry.get_id(data.new)

    if (w = Widget.look_up(old_id))?
        save_position(new_id, w.get_pos())
        sel = cancel_item_selected(w)
        all_item.remove(old_id)
        w.destroy()

    if (w = Widget.look_up(new_id))?
        cancel_item_selected(w)
        all_item.remove(new_id)
        w.destroy()

    discard_position(old_id)

    w = create_item(data.new)
    if w?
        move_to_anywhere(w)
        all_item.push(w.get_id())
        if sel then set_item_selected(w)

    update_selected_item_drag_image()
    return


do_trash_update = ->
    w = Widget.look_up("Trash_Virtual_Dir")
    if w?
        w.item_update()


do_cut_completed = (items) ->
    for e in items
        w = Widget.look_up(DCore.DEntry.get_id(e))
        if w? and w.modifiable == true then w.display_not_cut()
    return


do_desktop_lost_focus = ->
    # destkop has lost focus
    # notify destkop normal items
    if last_widget.length > 0 and (w = Widget.look_up(last_widget))?
        if w.has_focus
            last_widget_has_focus = true
            w.item_blur()
        else
            last_widget_has_focus = false
    return


do_desktop_get_focus = ->
    # destkop has lost focus
    # notify destkop normal items
    if last_widget.length > 0 and (w = Widget.look_up(last_widget))? and last_widget_has_focus == true
        w.item_focus()
        last_widget_has_focus == false
    return


do_desktop_config_changed = ->
    place_desktop_items()
    return


do_workarea_changed = (allo) ->
    update_gird_position(allo.x + 4, allo.y + 4, allo.width - 8, allo.height - 8)
    init_occupy_table()
    place_desktop_items()
    return
