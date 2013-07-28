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
                    DCore.DEntry.move(list, g_desktop_entry)
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
    # desktop_path = DCore.DEntry.get_desktop_path()
    desktop_path = "home/ycl/Desktop"
    dde_path = "/home/ycl/dde"
    # echo desktop_path

    Computer_copy = []
    Computer_delete = []
    Computer_f_e_delete = DCore.DEntry.create_by_path("#{desktop_path}/Computer.desktop")
    if Computer_f_e_delete?
        Computer_delete.push(Computer_f_e_delete)
    Computer_f_e = DCore.DEntry.create_by_path("#{dde_path}/data/Computer.desktop")
    if Computer_f_e? 
        Computer_copy.push(Computer_f_e)
    Computer_p = {x : 0, y : 0, width : 1, height : 1}
    save_position(DCore.DEntry.get_id(Computer_f_e), Computer_p) if not detect_occupy(Computer_p)

    Trash_copy = []
    Trash_delete = []
    Trash_f_e_delete = DCore.DEntry.create_by_path("#{desktop_path}/Trash.desktop")
    if Trash_f_e_delete?
        Trash_delete.push(Trash_f_e_delete)
    Trash_f_e = DCore.DEntry.create_by_path("#{dde_path}/data/Trash.desktop")
    if Trash_f_e? 
        Trash_copy.push(Trash_f_e)
    Trash_p = {x : 0, y : 1, width : 1, height : 1}
    save_position(DCore.DEntry.get_id(Trash_f_e), Trash_p) if not detect_occupy(Trash_p)

    Home_copy = []
    Home_delete = []
    Home_f_e_delete = DCore.DEntry.create_by_path("#{desktop_path}/Home.desktop")
    if Home_f_e_delete?
        Home_delete.push(Home_f_e_delete)
    Home_f_e = DCore.DEntry.create_by_path("#{dde_path}/data/Home.desktop")
    if Home_f_e? 
        Home_copy.push(Home_f_e)
    Home_p = {x : 0, y : 2, width : 1, height : 1}
    save_position(DCore.DEntry.get_id(Home_f_e), Home_p) if not detect_occupy(Home_p)

    SoftCenter_copy = []
    SoftCenter_delete = []
    SoftCenter_f_e_delete = DCore.DEntry.create_by_path("#{desktop_path}/SoftCenter.desktop")
    if SoftCenter_f_e_delete?
        SoftCenter_delete.push(SoftCenter_f_e_delete)
    SoftCenter_f_e = DCore.DEntry.create_by_path("#{dde_path}/data/SoftCenter.desktop")
    if SoftCenter_f_e? 
        SoftCenter_copy.push(SoftCenter_f_e)
    SoftCenter_p = {x : 0, y : 3, width : 1, height : 1}
    save_position(DCore.DEntry.get_id(SoftCenter_f_e), SoftCenter_p) if not detect_occupy(SoftCenter_p)


    if _GET_CFG_BOOL_(_CFG_SHOW_DSC_ICON_)
        if Computer_copy.length && Computer_f_e_delete == null
            echo "load Computer"
            DCore.DEntry.copy(Computer_copy, g_desktop_entry)
    else
        echo "discard Computer"
        DCore.DEntry.delete_files(Computer_delete, false)


    if _GET_CFG_BOOL_(_CFG_SHOW_DSC_ICON_)
        if Trash_copy.length && Trash_f_e_delete == null
            echo "load Trash"
            DCore.DEntry.copy(Trash_copy, g_desktop_entry)
    else
        echo "discard Trash"
        DCore.DEntry.delete_files(Trash_delete, false)


    if _GET_CFG_BOOL_(_CFG_SHOW_DSC_ICON_)
        if Home_copy.length && Home_f_e_delete == null
            echo "load Home"
            DCore.DEntry.copy(Home_copy, g_desktop_entry)
    else
        echo "discard Home"
        DCore.DEntry.delete_files(Home_delete, false)


    if _GET_CFG_BOOL_(_CFG_SHOW_DSC_ICON_)
        if SoftCenter_copy.length && SoftCenter_f_e_delete == null
            echo "load SoftCenter"
            DCore.DEntry.copy(SoftCenter_copy, g_desktop_entry)
    else
        echo "discard SoftCenter"
        DCore.DEntry.delete_files(SoftCenter_delete, false)

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
