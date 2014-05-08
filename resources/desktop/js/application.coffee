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


class Application extends DesktopEntry
    constructor : ->
        super
        @show_launcher_box = null
        @animate_background = null


    set_icon : (src = null) =>
        echo "set_icon:#{src}"
        if src == null
            if (icon = DCore.DEntry.get_icon(@_entry)) == null
                icon = DCore.get_theme_icon("invalid-dock_app", D_ICON_SIZE_NORMAL)
        else
            icon = src
        super(icon)


    do_drop : (evt) ->
        super
        if _IS_DND_INTERLNAL_(evt) and @selected
        else
            tmp_list = []
            if (all_are_apps = (evt.dataTransfer.files.length > 0))
                for file in evt.dataTransfer.files
                    e = DCore.DEntry.create_by_path(decodeURI(file.path).replace(/^file:\/\//i, ""))
                    if not e? then continue
                    if all_are_apps == true and DCore.DEntry.get_type(e) != FILE_TYPE_APP
                        all_are_apps = false

                    tmp_list.push(e)

                if all_are_apps == true
                    pos = @get_pos()
                    tmp_list.push(@_entry)
                    if (new_entry = DCore.Desktop.create_rich_dir(tmp_list))?
                        for e in tmp_list
                            if (w = Widget.look_up(DCore.DEntry.get_id(e)))?
                                delete_item(w)
                        id = DCore.DEntry.get_id(new_entry)
                        if (w = Widget.look_up(id))?
                            move_to_somewhere(w, pos)
                        else
                            save_position(id, pos)
                else
                    DCore.DEntry.launch(@_entry, tmp_list)

            if @show_launcher_box == true
                @animate_combining_cancel()
            @show_launcher_box = null
        return


    do_dragenter : (evt) ->
        super
        if _IS_DND_INTERLNAL_(evt) and @selected
        else
            evt.dataTransfer.dropEffect = "move"

            if @show_launcher_box == null
                if (all_are_apps = (evt.dataTransfer.files.length > 0))
                    for file in evt.dataTransfer.files
                        e = DCore.DEntry.create_by_path(decodeURI(file.path).replace(/^file:\/\//i, ""))
                        if not e? then continue
                        if all_are_apps == true and DCore.DEntry.get_type(e) != FILE_TYPE_APP
                            all_are_apps = false
                            break
                    if all_are_apps
                        @show_launcher_box = true
                        @animate_combining()
                    else
                        @show_launcher_box = false
        return


    do_dragover : (evt) ->
        super
        if _IS_DND_INTERLNAL_(evt) and @selected
        else
            evt.dataTransfer.dropEffect = "move"

            if @show_launcher_box == null
                if (all_are_apps = (evt.dataTransfer.files.length > 0))
                    for file in evt.dataTransfer.files
                        e = DCore.DEntry.create_by_path(decodeURI(file.path).replace(/^file:\/\//i, ""))
                        if not e? then continue
                        if all_are_apps == true and DCore.DEntry.get_type(e) != FILE_TYPE_APP
                            all_are_apps = false
                            break
                    if all_are_apps
                        @show_launcher_box = true
                        @animate_combining()
                    else
                        @show_launcher_box = false
        return


    do_dragleave : (evt) ->
        super
        if _IS_DND_INTERLNAL_(evt) and @selected
        else
            evt.preventDefault()
            evt.dataTransfer.dropEffect = "move"

            if @show_launcher_box == true
                @animate_combining_cancel()
            @show_launcher_box = null
        return


    animate_combining : =>
        echo "animate_combining"
        @animate_background = document.createElement("div")
        @animate_background.style.position = "absolute"
        @animate_background.style.pointerEvents = "none"
        @animate_background.style.width = "48px"
        @animate_background.style.height = "48px"
        @animate_background.style.top = "2px"
        @animate_background.style.left = "20px"
        @animate_background.style.background = "url(img/richdir_background.png)"
        @element.insertBefore(@animate_background, @item_icon.parentElement)
        img_item = document.createElement("img")
        img_item.style.width = "#{@item_icon.offsetWidth * 4 / 5}px"
        img_item.style.height = "#{@item_icon.offsetHeight * 4 / 5}px"
        img_item.style.top = "0"
        img_item.style.left = "0"
        img_item.style.position = "absolute"
        img_item.style.webkitTransition = "width 0.2s, height 0.2s"
        img_item.src = @item_icon.src
        echo img_item.src
        @animate_background.appendChild(img_item)
        img_item.addEventListener("load", =>
            img_item.style.width = "20px"
            img_item.style.height = "20px"
            img_item.style.top = "5px"
            img_item.style.left = "6px"
            setTimeout(=>
                    if @animate_background?
                        @animate_background.parentElement.removeChild(@animate_background)
                        @animate_background = null
                , 101
            )
            return
        )
        @item_name.style.opacity = 0
        @set_icon(DCore.Desktop.get_transient_icon(@_entry))


    animate_combining_cancel : =>
        if @animate_background?
            @animate_background.parentElement.removeChild(@animate_background)
            @animate_background = null
        @set_icon()
        @item_name.style.opacity = 1

    item_exec : =>
        if !DCore.DEntry.launch(@_entry, [])
            if confirm(_("The link is invalid. Do you want to delete it?"), _("Warning"))
                list = []
                list.push(@_entry)
                DCore.DEntry.trash(list)
