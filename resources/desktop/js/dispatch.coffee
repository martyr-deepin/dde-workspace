#Copyright (c) 2011 ~ 2014 Deepin, Inc.
#              2011 ~ 2014 snyh
#
#Author:      snyh <snyh@snyh.org>
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

FILE_TYPE_APP = 0
FILE_TYPE_FILE = 1
FILE_TYPE_DIR = 2
FILE_TYPE_RICH_DIR = 3
FILE_TYPE_INVALID_LINK = 4


attach_item_to_grid = (w) ->
    if w? and w.element?
        div_grid.appendChild(w.element)
    return


create_item = (entry) ->
    w = null
    Type = DCore.DEntry.get_type(entry)
    switch Type
        when FILE_TYPE_APP
            w = new Application(entry)
        when FILE_TYPE_FILE
            w = new NormalFile(entry)
        when FILE_TYPE_DIR
            w = new Folder(entry)
        when FILE_TYPE_RICH_DIR
            list = DCore.DEntry.list_files(entry)
            if list.length <= 1
                if list.length
                    DCore.DEntry.move(list, g_desktop_entry,true)
                    if (pos = load_position(DCore.DEntry.get_id(entry)))?
                        save_position(DCore.DEntry.get_id(list[0]), pos)
                discard_position(DCore.DEntry.get_id(entry))
                DCore.DEntry.delete_files([entry], false)
            else
                w = new RichDir(entry)
        when FILE_TYPE_INVALID_LINK
            w = new InvalidLink(entry)
        else
            echo "don't support type"

    attach_item_to_grid(w)
    return w


delete_item = (w) ->
    cancel_item_selected(w)
    all_item.remove(w.get_id())
    discard_position(w.get_id())
    w.destroy()


delete_widget = (w) ->
    old_info = w.get_pos()
    widget_item.remove(w.get_id())
    clear_occupy(w.get_id(), old_info)
    discard_position(w.get_id())
    PluginManager.enable_plugin(w.get_plugin(), false)
    w.destroy()


clear_speical_desktop_items = ->
    Widget.look_up(i)?.destroy() for i in speical_item
    speical_item.splice(0)
    return


load_speical_desktop_items = ->
    clear_speical_desktop_items()

    if _GET_CFG_BOOL_(_CFG_SHOW_COMPUTER_ICON_)
        item = new ComputerVDir
        if item?
            div_grid.appendChild(item.element)
            speical_item.push(item.get_id())
    else
        discard_position(_ITEM_ID_COMPUTER_)

    if _GET_CFG_BOOL_(_CFG_SHOW_TRASH_BIN_ICON_)
        item = new TrashVDir
        if item?
            div_grid.appendChild(item.element)
            speical_item.push(item.get_id())
    else
        discard_position(_ITEM_ID_TRASH_BIN_)
    return


clear_desktop_items = ->
    Widget.look_up(i)?.destroy() for i in all_item
    all_item.splice(0)
    return


load_desktop_all_items = ->
    clear_desktop_items()

    for e in DCore.Desktop.get_desktop_entries()
        w = create_item(e)
        if w? then all_item.push(w.get_id())

    return
