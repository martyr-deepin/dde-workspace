#Copyright (c) 2012 ~ 2014 Deepin, Inc.
#              2012 ~ 2014 snyh
#
#Author:      snyh <snyh@snyh.org>
#             Cole <phcourage@gmail.com>
#             bluth <yuanchenglu001@gmail.com>
#
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



class DesktopEntry extends Item
    constructor : ->
        super
        @add_css_class("DesktopEntry")
        @unregisterMenu_connect()


    do_dragstart : (evt) ->
        evt.stopPropagation()
        @item_complete_rename(true)
        item_dragstart_handler(this, evt)

        return


    do_dragend : (evt) ->
        evt.stopPropagation()
        evt.preventDefault()
        item_dragend_handler(this, evt)

        return


    do_drop : (evt) ->
        file = evt.dataTransfer.getData("Text")
        if _IS_DND_INTERLNAL_(evt)
            if not @selected
                evt.stopPropagation()
                evt.preventDefault()
                @display_not_hover()
        else
            evt.stopPropagation()
            evt.preventDefault()
            if not @selected
                @display_not_hover()
        return


    do_dragenter : (evt) ->
        if _IS_DND_INTERLNAL_(evt)
            if not @selected
                evt.stopPropagation()
                @display_hover()
                evt.dataTransfer.dropEffect = "none"
        else
            evt.stopPropagation()
            if not @selected
                @display_hover()
            evt.dataTransfer.dropEffect = "none"
        return


    do_dragover : (evt) ->
        if _IS_DND_INTERLNAL_(evt)
            if not @selected
                evt.stopPropagation()
                evt.preventDefault()
                @display_hover()
                evt.dataTransfer.dropEffect = "none"
        else
            evt.stopPropagation()
            evt.preventDefault()
            if not @selected
                @display_hover()
            evt.dataTransfer.dropEffect = "none"
        return


    do_dragleave : (evt) ->
        evt.stopPropagation()
        evt.preventDefault()
        if not @selected
            @display_not_hover()
        return

    buildmenu : ->
        menu = []
        menu.push([1, _("_Open")])
        menu.push([])
        menu.push([3, _("Cu_t")])
        menu.push([4, _("_Copy")])
        menu.push([])
        menu.push([6, _("_Rename"), not is_selected_multiple_items()])
        menu.push([9, _("_Delete")])
        menu.push([])
        menu.push([10, _("_Properties")])

        if DCore.DEntry.is_fileroller_exist()
            compressable = get_items_compressibility()
            if 0 == compressable
            else if 1 == compressable
                menu.splice(2, 0, [11, _("Co_mpress")])
                menu.splice(3, 0, [])
            else if 2 == compressable
                menu.splice(2, 0, [12, _("_Extract")])
                menu.splice(3, 0, [13, _("Extract _Here")])
                menu.splice(4, 0, [])
            else if 3 == compressable
                menu.splice(2, 0, [11, _("Co_mpress")])
                menu.splice(3, 0, [12, _("_Extract")])
                menu.splice(4, 0, [13, _("Extract _Here")])
                menu.splice(5, 0, [])
        return menu

    unregisterMenu_connect: ->
        @element.addEventListener("contextmenu", (e) =>
            console.debug "contextmenu for unregisterHook"
            menu = @buildmenu()
            menu.unshift(DEEPIN_MENU_TYPE.NORMAL)
            build_menu(menu)
                    ?.addListener(@on_itemselected)
                    .showMenu(e.screenX, e.screenY)
                    .unregisterHook(=>
                        DCore.Desktop.force_get_input_focus()
                    )
            e.preventDefault()
        )


    on_itemselected : (evt) =>
        id = parseInt(evt)
        switch id
            when 1 then open_selected_items()
            when 3 then selected_cut_to_clipboard()
            when 4 then selected_copy_to_clipboard()
            when 6 then @item_rename()
            when 9 then delete_selected_items(evt.shiftKey)
            when 10 then show_selected_items_properties()
            when 11 then compress_selected_items()
            when 12 then decompress_selected_items()
            when 13 then decompress_selected_items_here()
            else echo "menu clicked:id=#{env.id} title=#{env.title}"
        return

    item_exec : =>
        filename = @get_name()
        if (filename.endsWith(".bin"))
            if (entry =  DCore.DEntry.create_by_path(@get_path()))
                DCore.DEntry.launch(entry, [])
            return
        if !DCore.DEntry.launch(@_entry,[])
            confirm(_("Can not open this file."), _("Warning"))
        return

class NormalFile extends DesktopEntry

class DesktopApplet extends Item
