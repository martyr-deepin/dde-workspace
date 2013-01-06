#Copyright (c) 2011 ~ 2012 Deepin, Inc.
#              2011 ~ 2012 snyh
#
#Author:      snyh <snyh@snyh.org>
#             Cole <phcourage@gmail.com>
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

MAX_ITEM_TITLE = 20
DLCLICK_INTERVAL = 200


cleanup_filename = (str) ->
    new_str = str.replace(/\n|\//g, "")
    if new_str == "." or new_str == ".."
        ""
    else
        new_str


class Item extends Widget
    constructor: (@entry, @modifiable = true) ->
        @id = @get_id()

        @selected = false
        @has_focus = false
        @clicked_before = false

        @in_rename = false
        @delay_rename_tid = -1

        super(@id)

        el = @element
        info = {x:0, y:0, width:1, height:1}

        #el.setAttribute("tabindex", 0)
        el.draggable = true

        @item_icon = document.createElement("img")
        @item_icon.src = @get_icon()
        @item_icon.draggable = false
        el.appendChild(@item_icon)

        @item_name = document.createElement("div")
        @item_name.className = "item_name"
        @item_name.innerText = @get_name()
        el.appendChild(@item_name)


    destroy : ->
        info = load_position(@id)
        clear_occupy(info)
        super


    get_id : ->
        DCore.DEntry.get_id(@entry)


    get_name : ->
        DCore.DEntry.get_name(@entry)


    get_icon : ->
        DCore.DEntry.get_icon(@entry)


    get_path : ->
        DCore.DEntry.get_path(@entry)


    get_mtime : ->
        DCore.DEntry.get_mtime(@entry)


    do_mouseover : (evt) ->
        @show_hover_box()


    do_mouseout : (evt) ->
        @hide_hover_box()


    do_mousedown : (evt) ->
        evt.stopPropagation()
        if evt.button == 0 then update_selected_stats(this, evt)
        false


    do_click : (evt) ->
        evt.stopPropagation()
        if @clicked_before == false
            @clicked_before = true
            update_selected_stats(this, evt)
        else
            if evt.srcElement.className == "item_name"
                if @delay_rename_tid == -1 then @delay_rename_tid = setTimeout(@item_rename, 600)
            else
                if @in_rename
                    @item_complete_rename(true)
                else
                    update_selected_stats(this, evt)

        false


    do_dblclick : (evt) ->
        evt.stopPropagation()
        @clear_delay_rename_timer()
        if @in_rename then @item_complete_rename(false)

        if evt.ctrlKey == true then return
        @item_exec()


    do_rightclick : (evt) ->
        evt.stopPropagation()
        if @selected == false
            update_selected_stats(this, evt)
        else if @in_rename == true
            @item_complete_rename(false)


    display_full_name : ->
        echo "display_full_name"
        @element.className += " full_name"


    display_short_name : ->
        echo "display_short_name"
        @element.className = @element.className.replace(/\ full_name/g, "")


    display_selected : ->
        @selected = true
        @show_selected_box()


    display_normal : ->
        @selected = false
        @clicked_before = false

        @clear_delay_rename_timer()
        if @in_rename then @item_complete_rename(false)
        @hide_selected_box()


    display_focus : ->
        @has_focus = true
        @display_full_name()


    display_blur : ->
        @clear_delay_rename_timer()
        if @in_rename then @item_complete_rename(false)

        @has_focus = false
        @display_short_name()


    display_cut : ->
        @element.style.opacity = "0.5"


    display_not_cut : ->
        @element.style.opacity = "1"


    item_update : () =>
        @item_icon.src = @get_icon()
        if @in_rename == false
            @item_name.innerText = @get_name()


    item_exec : =>
        DCore.DEntry.launch(@entry, [])


    show_selected_box : =>
        @element.className += " item_selected"


    hide_selected_box : =>
        @element.className = @element.className.replace(/\ item_selected/g, "")


    show_hover_box : =>
        @element.className += " item_hover"


    hide_hover_box : =>
        @element.className = @element.className.replace(/\ item_hover/g, "")


    on_event_stoppropagation : (evt) =>
        evt.stopPropagation()
        return


    on_event_preventdefault : (evt) =>
        evt.stopPropagation()
        evt.preventDefault()
        return


    on_rename : (new_name) ->
        DCore.DEntry.set_name(@entry, new_name)


    item_rename : =>
        if @delay_rename_tid != -1 then
        if @selected == false then return
        if @in_rename == false
            echo "item_rename"
            @display_full_name()
            @element.draggable = false
            @item_name.contentEditable = "true"
            @item_name.className = "item_renaming"
            @item_name.addEventListener("mousedown", @on_event_stoppropagation)
            @item_name.addEventListener("mouseup", @on_event_stoppropagation)
            @item_name.addEventListener("click", @on_event_stoppropagation)
            @item_name.addEventListener("dblclick", @on_event_stoppropagation)
            @item_name.addEventListener("contextmenu", @on_event_preventdefault)
            @item_name.addEventListener("keydown", @on_event_stoppropagation)
            @item_name.addEventListener("keypress", @on_item_rename_keypress)
            @item_name.addEventListener("keyup", @on_item_rename_keyup)
            @item_name.focus()

            ws = window.getSelection()
            ws.removeAllRanges()
            range = document.createRange()
            range.setStart(@item_name.childNodes[0], 0)
            range.setEnd(@item_name.childNodes[0], @item_name.childNodes[0].length)
            ws.addRange(range)

            @in_rename = true
        return


    clear_delay_rename_timer : =>
        if @delay_rename_tid == -1 then return
        clearTimeout(@delay_rename_tid)
        @delay_rename_tid = -1
        return


    on_item_rename_keypress : (evt) =>
        evt.stopPropagation()
        switch evt.keyCode
            when 13   # enter
                evt.preventDefault()
                @item_complete_rename(true)
                ++ingore_keyup_counts
            when 27   # esc
                evt.preventDefault()
                @item_complete_rename(false)
            when 47   # /
                evt.preventDefault()
        return


    on_item_rename_keyup : (evt) =>
        evt.stopPropagation()
        return


    item_complete_rename : (modify = true) =>
        echo "item_complete_rename"
        if modify == true
            new_name = cleanup_filename(@item_name.innerText)
            if new_name.length > 0 and new_name != @get_name()
                @on_rename(new_name)

        @element.draggable = true
        @item_name.contentEditable = "false"
        @item_name.className = "item_name"
        @item_name.innerText = @get_name()
        @item_name.removeEventListener("mousedown", @on_event_stoppropagation)
        @item_name.removeEventListener("mouseup", @on_event_stoppropagation)
        @item_name.removeEventListener("click", @on_event_stoppropagation)
        @item_name.removeEventListener("dblclick", @on_event_stoppropagation)
        @item_name.removeEventListener("contextmenu", @on_event_preventdefault)
        @item_name.removeEventListener("keydown", @on_event_stoppropagation)
        @item_name.removeEventListener("keypress", @on_item_rename_keypress)
        @item_name.removeEventListener("keyup", @on_item_rename_keyup)

        @clear_delay_rename_timer()
        @in_rename = false

        return


    move: (x, y) ->
        style = @element.style
        style.position = "absolute"
        style.left = x
        style.top = y


class DesktopEntry extends Item
    constructor : ->
        @in_count = 0

        super
        @add_css_class("DesktopEntry")


    do_dragstart : (evt) =>
        evt.stopPropagation()

        @item_complete_rename(false)
        item_dragstart_handler(this, evt)

        return


    do_dragend : (evt) =>
        evt.stopPropagation()
        evt.preventDefault()
        if evt.dataTransfer.dropEffect == "move"
            drag_update_selected_pos(this, evt)

        return


    do_drop : (evt) =>
        evt.stopPropagation()
        evt.preventDefault()
        if @selected == false
            @hide_hover_box()
            @in_count = 0


    do_dragenter : (evt) =>
        evt.stopPropagation()

        if @selected == false
            ++@in_count
            if @in_count == 1
                @show_hover_box()

        found_self = false
        for file in evt.dataTransfer.files
            if decodeURI(file.path).replace(/^file:\/\//i, "") == @get_path()
                found_self = true
                break

        if found_self == true
            evt.dataTransfer.dropEffect = "none"
        else
            evt.dataTransfer.dropEffect = "move"

        return


    do_dragover : (evt) =>
        evt.preventDefault()
        evt.stopPropagation()

        found_self = false
        for file in evt.dataTransfer.files
            if decodeURI(file.path).replace(/^file:\/\//i, "") == @get_path()
                found_self = true
                break

        if found_self == true
            evt.dataTransfer.dropEffect = "none"
        else
            evt.dataTransfer.dropEffect = "move"

        return


    do_dragleave : (evt) =>
        evt.stopPropagation()
        if @selected == false
            --@in_count
            if @in_count == 0
                @hide_hover_box()

        return


    do_buildmenu : ->
        menu = []
        menu.push([1, _("Open")])
        menu.push([])
        menu.push([3, _("cut")])
        menu.push([4, _("copy")])
        menu.push([])
        menu.push([6, _("Rename"), not is_selected_multiple_items()])
        menu.push([9, _("Delete")])
        menu.push([])
        menu.push([10, _("Properties")])
        menu


    do_itemselected : (evt) =>
        switch evt.id
            when 1 then open_selected_items()
            when 3 then selected_cut_to_clipboard()
            when 4 then selected_copy_to_clipboard()
            when 6 then @item_rename()
            when 9 then delete_selected_items(evt.shiftKey == true)
            when 10 then show_selected_items_Properties()
            else echo "menu clicked:id=#{env.id} title=#{env.title}"


class Folder extends DesktopEntry
    do_drop : (evt) =>
        super

        tmp_list = []
        for file in evt.dataTransfer.files
            e = DCore.DEntry.create_by_path(decodeURI(file.path).replace(/^file:\/\//i, ""))
            if not e? then continue
            if DCore.DEntry.get_type(e) != FILE_TYPE_RICH_DIR then tmp_list.push(e)

        if tmp_list.length > 0 then DCore.DEntry.move(tmp_list, @entry)
        return


class RichDir extends DesktopEntry
    constructor : (entry)->
        super

        @div_pop = null
        @show_pop = false


    destroy : ->
        if @div_pop != null then @hide_pop_block()
        super


    get_name : ->
        DCore.Desktop.get_rich_dir_name(@entry)


    get_icon : ->
        DCore.Desktop.get_rich_dir_icon(@entry)


    do_click : (evt) ->
        super
        if evt.shiftKey == false && evt.ctrlKey == false
            if @show_pop == false
                @show_pop_block()
            else
                @hide_pop_block()


    do_dblclick : (evt) ->
        evt.stopPropagation()
        @clear_delay_rename_timer()
        if @in_rename then @item_complete_rename(false)


    do_rightclick : (evt) ->
        if @show_pop == true then @hide_pop_block()
        super


    do_dragstart : (evt) ->
        if @show_pop == true then @hide_pop_block()
        super


    do_drop : (evt) ->
        super

        tmp_list = []
        for file in evt.dataTransfer.files
            e = DCore.DEntry.create_by_path(decodeURI(file.path).replace(/^file:\/\//i, ""))
            if not e? then continue
            if DCore.DEntry.get_type(e) == FILE_TYPE_APP then tmp_list.push(e)

        if tmp_list.length > 0 then DCore.DEntry.move(tmp_list, @entry)
        return


    do_buildmenu : ->
        menus = []
        menus.push([1, _("Open")])
        menus.push([])
        menus.push([6, _("Rename"), not is_selected_multiple_items()])
        menus.push([9, _("Delete")])
        menus


    display_normal : ->
        if @div_pop != null then @hide_pop_block()
        super


    display_blur : ->
        if @div_pop != null then @hide_pop_block()
        super


    item_update : ->
        if @show_pop == true then @reflesh_pop_block()
        super


    item_exec : ->
        if @show_pop == false then @show_pop_block()


    on_rename : (new_name) ->
        DCore.Desktop.set_rich_dir_name(@entry, new_name)


    show_pop_block : =>
        if @selected == false then return
        if @div_pop != null then return

        @sub_items = {}
        @sub_items_count = 0
        for e in DCore.DEntry.list_files(@entry)
            @sub_items[DCore.DEntry.get_id(e)] = e
            ++@sub_items_count
        if @sub_items_count == 0 then return

        @div_pop = document.createElement("div")
        @div_pop.setAttribute("id", "pop_grid")
        document.body.appendChild(@div_pop)
        @div_pop.addEventListener("mousedown", @on_event_stoppropagation)
        @div_pop.addEventListener("click", @on_event_stoppropagation)
        @div_pop.addEventListener("contextmenu", @on_event_stoppropagation)
        @div_pop.addEventListener("keyup", @on_event_stoppropagation)

        @show_pop = true

        @fill_pop_block()

        @display_short_name()


    reflesh_pop_block : =>
        for i in @div_pop.getElementsByTagName("ul")
            i.parentElement.removeChild(i)

        for i in @div_pop.getElementsByTagName("div")
            if i.id == "pop_downarrow" or i.id == "pop_uparrow"
                i.parentElement.removeChild(i)

        @sub_items = {}
        @sub_items_count = 0
        for e in DCore.DEntry.list_files(@entry)
            @sub_items[DCore.DEntry.get_id(e)] = e
            ++@sub_items_count
        if @sub_items_count == 0
            @hide_pop_block()
            DCore.DEntry.delete([@entry])
        else
            @fill_pop_block()


    fill_pop_block : =>
        ele_ul = document.createElement("ul")
        ele_ul.setAttribute("id", @id)
        @div_pop.appendChild(ele_ul)

        for i, e of @sub_items
            ele = document.createElement("li")
            ele.setAttribute('id', i)
            ele.setAttribute('title', DCore.DEntry.get_name(e))
            ele.draggable = true
            s = document.createElement("img")
            s.src = DCore.DEntry.get_icon(e)
            ele.appendChild(s)
            s = document.createElement("div")
            s.innerText = DCore.DEntry.get_name(e)
            ele.appendChild(s)

            ele.addEventListener('dragstart', (evt) ->
                evt.stopPropagation()
                w = Widget.look_up(this.parentElement.id)
                if w? then e = w.sub_items[this.id]
                if e?
                    evt.dataTransfer.setData("text/uri-list", "file://#{encodeURI(DCore.DEntry.get_path(e))}")
                    evt.dataTransfer.effectAllowed = "moveCopy"
                else
                    evt.dataTransfer.effectAllowed = "none"
            )
            ele.addEventListener('dragend', (evt) ->
                evt.stopPropagation()
            )
            ele.addEventListener('dblclick', (evt) ->
                evt.stopPropagation()
                w = Widget.look_up(this.parentElement.id)
                if w? then e = w.sub_items[this.id]
                if e? then DCore.DEntry.launch(e, [])
                if w? then w.hide_pop_block()
            )

            ele_ul.appendChild(ele)

        if @sub_items_count <= 3
            col = @sub_items_count
        else if @sub_items_count <= 6
            col = 3
        else if @sub_items_count <= 12
            col = 4
        else if @sub_items_count <= 20
            col = 5
        else
            col = 6

        # 20px for ul padding, 2px for border, 8px for scrollbar
        if @sub_items_count > 24
            @div_pop.style.width = "#{col * i_width + 30}px"
        else
            @div_pop.style.width = "#{col * i_width + 22}px"
        arrow = document.createElement("div")

        n = Math.ceil(@sub_items_count / col)
        if n > 4 then n = 4
        n = n * i_height + 40
        if s_height - @element.offsetTop > n
            @div_pop.style.top = "#{@element.offsetTop + Math.min(i_height, @element.offsetHeight) + 16}px"
            arrow_pos = false
        else
            @div_pop.style.top = "#{@element.offsetTop - n}px"
            arrow_pos = true

        n = (col * i_width) / 2
        p = @element.offsetLeft + @element.offsetWidth / 2
        if p < n
            @div_pop.style.left = "0"
            arrow.style.left = "#{p}px"
        else if p + n > s_width
            @div_pop.style.left = "#{s_width - 2 * n}px"
            arrow.style.right = "#{s_width - p}px"
        else
            @div_pop.style.left = "#{p - n}px"
            arrow.style.left = "#{n}px"

        if arrow_pos == true
            arrow.setAttribute("id", "pop_downarrow")
            @div_pop.appendChild(arrow)
        else
            arrow.setAttribute("id", "pop_uparrow")
            @div_pop.insertBefore(arrow, @div_pop.firstChild)


    hide_pop_block : =>
        if @div_pop?
            @sub_items = {}
            @div_pop.parentElement?.removeChild(@div_pop)
            delete @div_pop
            @div_pop = null
        @show_pop = false

        @display_full_name()


class Application extends DesktopEntry
    do_drop : (evt) ->
        super

        tmp_list = []
        all_are_apps = true
        for file in evt.dataTransfer.files
            e = DCore.DEntry.create_by_path(decodeURI(file.path).replace(/^file:\/\//i, ""))
            if not e? then continue
            if all_are_apps == true and DCore.DEntry.get_type(e) != FILE_TYPE_APP
                all_are_apps = false

            tmp_list.push(e)

        if all_are_apps == true
            tmp_list.push(@entry)
            DCore.Desktop.create_rich_dir(tmp_list)
        else
            DCore.DEntry.launch(@entry, tmp_list)
        return


class NormalFile extends DesktopEntry


class DesktopApplet extends Item


class ComputerVDir extends DesktopEntry
    constructor : ->
        entry = DCore.Desktop.get_computer_entry()
        super(entry, false)


    get_id : ->
        "Computer_Virtual_Dir"


    get_name : ->
        _("Computer")


    get_icon : ->
        "img/computer.png"


    get_path : ->
        ""

    item_rename : ->
        return


    do_dragenter : (evt) ->
        evt.stopPropagation()
        evt.dataTransfer.dropEffect = "none"

        if @selected == false
            ++@in_count
            if @in_count == 1
                @show_hover_box()


    do_dragover : (evt) ->
        evt.stopPropagation()
        evt.dataTransfer.dropEffect = "none"


    do_drop : (evt) ->
        evt.stopPropagation()
        evt.dataTransfer.dropEffect = "none"


    do_buildmenu : ->
        [
            [1, _("open")],
            [2, _("open in terminal")],
            [],
            [3, _("properties")]
        ]


    do_itemselected : (evt) ->
        switch evt.id
            when 1 then @item_exec()
            when 2 then DCore.Desktop.run_terminal()
            when 3 then DCore.Desktop.run_deepin_settings("system_information")
            else echo "computer unkown command id:#{evt.id} title:#{evt.title}"


class HomeVDir extends DesktopEntry
    constructor : ->
        entry = DCore.Desktop.get_home_entry()
        super(entry, false)


    get_id : ->
        "Home_Virtual_Dir"


    get_name : ->
        _("Home")


    get_icon : ->
        "img/home_dir.png"


    get_path : ->
        ""

    do_drop : (evt) ->
        super

        tmp_list = []
        for file in evt.dataTransfer.files
            e = DCore.DEntry.create_by_path(decodeURI(file.path).replace(/^file:\/\//i, ""))
            if not e? then continue
            tmp_list.push(e)

        if tmp_list.length > 0 then DCore.DEntry.move(tmp_list, @entry)
        return


    item_rename : ->
        return


    do_buildmenu : ->
        [
            [1, _("open")],
            [2, _("open in terminal")],
            [],
            [3, _("properties")]
        ]

    do_itemselected : (evt) ->
        switch evt.id
            when 1 then @item_exec()
            when 2 then DCore.Desktop.run_terminal()
            when 3
                try
                    s_nautilus?.ShowItemProperties_sync(["file://#{encodeURI(DCore.DEntry.get_path(@entry))}"], "")
                catch e
            else echo "computer unkown command id:#{evt.id} title:#{evt.title}"


class TrashVDir extends DesktopEntry
    constructor : ->
        entry = DCore.Desktop.get_trash_entry()
        super(entry, false)


    get_id : ->
        "Trash_Virtual_Dir"


    get_name : ->
        _("Trash Bin")


    get_icon : ->
        if DCore.Desktop.get_trash_count() > 0
            "img/trash.png"
        else
            "img/trash_empty.png"


    get_path : ->
        ""


    do_drop : (evt) ->
        super

        tmp_list = []
        for file in evt.dataTransfer.files
            e = DCore.DEntry.create_by_path(decodeURI(file.path).replace(/^file:\/\//i, ""))
            if not e? then continue
            tmp_list.push(e)

        if tmp_list.length > 0 then DCore.DEntry.trash(tmp_list)
        return


    item_rename : ->
        return


    do_buildmenu : ->
        menus = []
        menus.push([1, _("open")])
        menus.push([])
        count = DCore.Desktop.get_trash_count()
        if count > 1
            menus.push([3, _("clean up") + " #{count} " + _("files")])
        else if count == 1
            menus.push([3, _("clean up") + " #{count} " + _("file")])
        else
            menus.push([3, _("clean up"), false])
        menus


    do_itemselected : (evt) ->
        switch evt.id
            when 1 then @item_exec()
            when 3 then DCore.Desktop.empty_trash()
            else echo "computer unkown command id:#{evt.id} title:#{evt.title}"
