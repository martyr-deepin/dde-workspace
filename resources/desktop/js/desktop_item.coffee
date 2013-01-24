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

cleanup_filename = (str) ->
    new_str = str.replace(/\n|\//g, "")
    if new_str == "." or new_str == ".."
        ""
    else
        new_str


_GET_ENTRY_FROM_PATH_ = (path) ->
    DCore.DEntry.create_by_path(decodeURI(path).replace(/^file:\/\//i, ""))


class Item extends Widget
    constructor: (@entry, @modifiable = true) ->
        @id = @get_id()

        @selected = false
        @has_focus = false
        @clicked_before = 0

        @in_rename = false
        @delay_rename_tid = -1

        super(@id)

        el = @element
        info = {x:0, y:0, width:1, height:1}

        #el.setAttribute("tabindex", 0)
        el.draggable = true

        @item_icon = document.createElement("img")
        @item_icon.className = "item_icon"
        @item_icon.draggable = false
        el.appendChild(@item_icon)

        @item_attrib = document.createElement("ul")
        @item_attrib.className = "item_attrib"
        el.appendChild(@item_attrib)

        @item_name = document.createElement("div")
        @item_name.className = "item_name"
        el.appendChild(@item_name)

        @item_update()


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
        DCore.DEntry.get_uri(@entry)


    get_mtime : ->
        DCore.DEntry.get_mtime(@entry)


    do_mouseover : (evt) ->
        @display_hover()
        return


    do_mouseout : (evt) ->
        @display_not_hover()
        return


    do_mousedown : (evt) ->
        evt.stopPropagation()
        if evt.button == 0 and @clicked_before == 0 and not @selected
            @clicked_before = 1
            update_selected_stats(this, evt)
        return


    do_click : (evt) ->
        evt.stopPropagation()
        if @clicked_before == 1
            @clicked_before = 2
        else
            if is_selected_multiple_items()
                update_selected_stats(this, evt)
            else
                if @has_focus and evt.srcElement.className == "item_name" and @delay_rename_tid == -1
                    @delay_rename_tid = setTimeout(@item_rename, _RENAME_TIME_DELAY_)
                else
                    @clear_delay_rename_timer()


    do_dblclick : (evt) ->
        evt.stopPropagation()
        @clear_delay_rename_timer()
        if @in_rename then @item_complete_rename(false)

        if not evt.ctrlKey then @item_exec()
        return


    do_rightclick : (evt) ->
        evt.stopPropagation()
        if @selected == false
            update_selected_stats(this, evt)
        else if @in_rename == true
            @item_complete_rename(false)
        return


    display_full_name : ->
        @add_css_class("full_name")
        return


    display_short_name : ->
        @remove_css_class("full_name")
        return


    display_selected : =>
        @add_css_class("item_selected")


    display_not_selected : =>
        @remove_css_class("item_selected")
        return


    display_not_selected : =>
        @element.className = @element.className.replace(/\ item_selected/g, "")


    display_focus : =>
        @add_css_class("item_focus")
        return


    display_not_focus : =>
        @remove_css_class("item_focus")
        return


    display_hover : =>
        @add_css_class("item_hover")


    display_not_hover : =>
        @remove_css_class("item_hover")
        return


    display_cut : ->
        @element.style.opacity = "0.5"
        return


    display_not_cut : ->
        @element.style.opacity = "1"
        return


    on_event_stoppropagation : (evt) =>
        evt.stopPropagation()
        return


    on_event_preventdefault : (evt) =>
        evt.stopPropagation()
        evt.preventDefault()
        return


    on_rename : (new_name) ->
        DCore.DEntry.set_name(@entry, new_name)


    item_focus : ->
        @has_focus = true
        @display_full_name()
        @display_focus()
        return


    item_blur : ->
        @clear_delay_rename_timer()
        if @in_rename then @item_complete_rename(false)

        @display_short_name()
        @display_not_focus()
        @has_focus = false
        return


    item_selected : ->
        @display_selected()
        @selected = true
        return

    item_selected : ->
        @display_selected()
        @selected = true
        return

    item_normal : ->
        @clear_delay_rename_timer()
        if @in_rename then @item_complete_rename(false)
        @display_not_selected()

        @selected = false
        @clicked_before = 0
        return


    item_update : ->
        @item_icon.src = @get_icon()

        if @in_rename == false
            @item_name.innerText = @get_name()

        li_list = @item_attrib.getElementsByTagName("li")
        for i in [(li_list.length - 1) ... -1] by -1
            @item_attrib.removeChild(li_list[i])

        if @modifiable == false then return

        flags = DCore.DEntry.get_flags(@entry)
        if flags.read_only? and flags.read_only == 1
            ele = document.createElement("li")
            ele.innerHTML = "<img src=\"#{DCore.get_theme_icon(_FAI_READ_ONLY_, 16)}\" draggable=\"false\" />"
            @item_attrib.appendChild(ele)
        if flags.symbolic_link? and flags.symbolic_link == 1
            ele = document.createElement("li")
            ele.innerHTML = "<img src=\"#{DCore.get_theme_icon(_FAT_SYM_LINK_, 16)}\" draggable=\"false\" />"
            @item_attrib.appendChild(ele)
        if flags.unreadable? and flags.unreadable == 1
            ele = document.createElement("li")
            ele.innerHTML = "<img src=\"#{DCore.get_theme_icon(_FAT_UNREADABLE_, 16)}\" draggable=\"false\" />"
            @item_attrib.appendChild(ele)
        return


    item_exec : =>
        DCore.DEntry.launch(@entry, [])


    item_rename : =>
        if @delay_rename_tid != -1 then
        if @selected == false then return
        if @in_rename == false
            @display_full_name()
            @display_not_selected()
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
        if modify == true
            new_name = cleanup_filename(@item_name.innerText)
            if new_name.length > 0 and new_name != @get_name()
                if not @on_rename(new_name)
                    return

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

        @display_selected()

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

        item_dragend_handler(this, evt)

        return


    do_drop : (evt) =>
        evt.stopPropagation()
        evt.preventDefault()
        if not is_item_been_selected(@id)
            @display_not_hover()
        @in_count = 0


    do_dragenter : (evt) =>
        evt.stopPropagation()

        ++@in_count
        if @in_count == 1 and @selected == false
            @display_hover()

        evt.dataTransfer.dropEffect = "none"
        return


    do_dragover : (evt) =>
        evt.preventDefault()
        evt.stopPropagation()

        evt.dataTransfer.dropEffect = "none"
        return


    do_dragleave : (evt) =>
        evt.stopPropagation()
        --@in_count if @in_count >= 0
        if @in_count == 0 and @selected == false
            @display_not_hover()
        return


    do_buildmenu : ->
        menu = []
        menu.push([1, _("Open")])
        menu.push([])
        menu.push([3, _("Cut")])
        menu.push([4, _("Copy")])
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
    get_icon : ->
        DCore.get_theme_icon("folder", 48)


    do_drop : (evt) =>
        super

        if evt.dataTransfer.dropEffect == "move"
            tmp_list = []
            for file in evt.dataTransfer.files
                e = DCore.DEntry.create_by_path(decodeURI(file.path).replace(/^file:\/\//i, ""))
                if not e? then continue
                tmp_list.push(e)
            if tmp_list.length > 0 then DCore.DEntry.move(tmp_list, @entry)
        return


    do_dragenter : (evt) ->
        super

        if not _IS_DND_INTERLNAL_(evt) or not is_item_been_selected(@id)
            evt.dataTransfer.dropEffect = "move"
        return


    do_dragover : (evt) ->
        super

        if not _IS_DND_INTERLNAL_(evt) or not is_item_been_selected(@id)
            evt.dataTransfer.dropEffect = "move"
        return


    do_dragleave : (evt) ->
        super

        if @in_count > 0
            evt.preventDefault()
            if not _IS_DND_INTERLNAL_(evt) or not is_item_been_selected(@id)
                evt.dataTransfer.dropEffect = "move"
        return


class RichDir extends DesktopEntry
    constructor : (entry)->
        super(entry, false)

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
        evt.stopPropagation()
        if @clicked_before == 1
            @clicked_before = 2
            if @show_pop == false then @show_pop_block()
        else
            if is_selected_multiple_items()
                update_selected_stats(this, evt)
            else
                if @show_pop == false
                    @show_pop_block()
                else
                    @hide_pop_block()
                    if @has_focus and evt.srcElement.className == "item_name" and @delay_rename_tid == -1
                        @delay_rename_tid = setTimeout(@item_rename, _RENAME_TIME_DELAY_)
                    else
                        @clear_delay_rename_timer()


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

        if evt.dataTransfer.dropEffect == "move"
            tmp_list = []
            for file in evt.dataTransfer.files
                e = DCore.DEntry.create_by_path(decodeURI(file.path).replace(/^file:\/\//i, ""))
                if not e? then continue
                if DCore.DEntry.get_type(e) == FILE_TYPE_APP then tmp_list.push(e)
            if tmp_list.length > 0 then DCore.DEntry.move(tmp_list, @entry)
        return

    do_dragenter : (evt) ->
        super

        if not _IS_DND_INTERLNAL_(evt) or not is_item_been_selected(@id)
            evt.dataTransfer.dropEffect = "move"
        return


    do_dragover : (evt) ->
        super

        if not _IS_DND_INTERLNAL_(evt) or not is_item_been_selected(@id)
            evt.dataTransfer.dropEffect = "move"
        return


    do_dragleave : (evt) ->
        super

        if @in_count > 0
            evt.preventDefault()
            if not _IS_DND_INTERLNAL_(evt) or not is_item_been_selected(@id)
                evt.dataTransfer.dropEffect = "move"
        return


    do_buildmenu : ->
        menus = []
        menus.push([1, _("Open")])
        menus.push([])
        menus.push([6, _("Rename"), not is_selected_multiple_items()])
        menus.push([9, _("Delete")])
        menus


    item_normal : ->
        if @div_pop != null then @hide_pop_block()
        super


    item_blur : ->
        if @div_pop != null then @hide_pop_block()
        super


    item_update : =>
        list = DCore.DEntry.list_files(@entry)
        if list.length <= 1
            if @show_pop == true
                @hide_pop_block()
                if list.length then DCore.DEntry.move(list, g_desktop_entry)
            discard_position(DCore.DEntry.get_id(entry))
            DCore.DEntry.delete_files([@entry], false)
        else
            if @show_pop == true
                @sub_items = {}
                @sub_items_count = 0
                for e in list
                    @sub_items[DCore.DEntry.get_id(e)] = e
                    ++@sub_items_count
                @reflesh_pop_block()
            super
        return


    item_exec : ->
        if @show_pop == false then @show_pop_block()


    item_rename : =>
        if @show_pop == true then @hide_pop_block()
        super


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

        @display_not_selected()
        @display_not_focus()
        @display_short_name()

        @fill_pop_block()


    reflesh_pop_block : =>
        for i in @div_pop.getElementsByTagName("ul")
            i.parentElement.removeChild(i)

        for i in @div_pop.getElementsByTagName("div")
            if i.id.substr(0, 10) == "pop_arrow_"
                i.parentElement.removeChild(i)
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
                    evt.dataTransfer.setData("text/uri-list", "file://#{encodeURI(DCore.DEntry.get_uri(e))}")
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
            pop_width = col * _ITEM_WIDTH_ + 30
        else
            pop_width = col * _ITEM_WIDTH_ + 22
        @div_pop.style.width = "#{pop_width}px"

        n = Math.ceil(@sub_items_count / col)
        if n > 4 then n = 4
        n = n * _ITEM_HEIGHT_ + 24
        if s_height - @element.offsetTop > n
            pop_top = @element.offsetTop + Math.min(_ITEM_HEIGHT_, @element.offsetHeight) + 12
            arrow_pos_at_bottom = false
        else
            pop_top = @element.offsetTop - n - 12
            arrow_pos_at_bottom = true
        @div_pop.style.top = "#{pop_top}px"

        n = @div_pop.offsetWidth / 2 + 1
        p = @element.offsetLeft + @element.offsetWidth / 2
        arrow_outter = document.createElement("div")
        arrow_mid = document.createElement("div")
        arrow_inner = document.createElement("div")
        if p < n
            @div_pop.style.left      = "#{s_offset_x}px"
            arrow_outter.style.left  = "#{p - 8}px"
            arrow_mid.style.left     = "#{p - 8}px"
            arrow_inner.style.left   = "#{p - 7}px"
        else if p + n > s_width
            @div_pop.style.left      = "#{s_width - 2 * n}px"
            arrow_outter.style.right = "#{s_width - p - 14}px"
            arrow_mid.style.right    = "#{s_width - p - 14}px"
            arrow_inner.style.right  = "#{s_width - p - 13}px"
        else
            @div_pop.style.left      = "#{p - n}px"
            arrow_outter.style.left  = "#{n - 3}px"
            arrow_mid.style.left     = "#{n - 3}px"
            arrow_inner.style.left   = "#{n - 2}px"

        if arrow_pos_at_bottom == true
            arrow_outter.setAttribute("id", "pop_arrow_up_outter")
            arrow_mid.setAttribute("id", "pop_arrow_up_mid")
            arrow_inner.setAttribute("id", "pop_arrow_up_inner")
            @div_pop.appendChild(arrow_outter)
            @div_pop.appendChild(arrow_mid)
            @div_pop.appendChild(arrow_inner)
        else
            arrow_outter.setAttribute("id", "pop_arrow_down_outter")
            arrow_mid.setAttribute("id", "pop_arrow_down_mid")
            arrow_inner.setAttribute("id", "pop_arrow_down_inner")
            @div_pop.insertBefore(arrow_outter, ele_ul)
            @div_pop.insertBefore(arrow_mid, ele_ul)
            @div_pop.insertBefore(arrow_inner, ele_ul)



    hide_pop_block : =>
        if @div_pop?
            @sub_items = {}
            @div_pop.parentElement?.removeChild(@div_pop)
            delete @div_pop
            @div_pop = null
        @show_pop = false

        @display_selected()
        @display_focus()
        @display_full_name()


class Application extends DesktopEntry
    get_icon : ->
        if (icon = DCore.DEntry.get_icon(@entry)) == null
            icon = DCore.get_theme_icon("invalid_app", 48)
        icon


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


    do_dragenter : (evt) ->
        super

        if not _IS_DND_INTERLNAL_(evt) or not is_item_been_selected(@id)
            evt.dataTransfer.dropEffect = "move"
        return


    do_dragover : (evt) ->
        super

        if not _IS_DND_INTERLNAL_(evt) or not is_item_been_selected(@id)
            evt.dataTransfer.dropEffect = "move"
        return


    do_dragleave : (evt) ->
        super
        if @in_count > 0
            evt.preventDefault()
            if not _IS_DND_INTERLNAL_(evt) or not is_item_been_selected(@id)
                evt.dataTransfer.dropEffect = "move"
        return


class NormalFile extends DesktopEntry


class InvalidLink extends DesktopEntry
    get_icon : ->
        DCore.get_theme_icon("invalid-link", 48)


    do_buildmenu : ->
        [
            [9, _("Delete")]
        ]


    item_exec : ->
        return


    item_update : ->
        @item_icon.src = @get_icon()
        @item_name.innerText = @get_name()


    item_rename : ->
        return


class DesktopApplet extends Item


class ComputerVDir extends DesktopEntry
    constructor : ->
        entry = DCore.Desktop.get_computer_entry()
        super(entry, false)


    get_id : ->
        _ITEM_ID_COMPUTER_


    get_name : ->
        _("Computer")


    get_icon : ->
        DCore.get_theme_icon("computer", 48)


    get_path : ->
        ""

    item_rename : ->
        return


    do_buildmenu : ->
        [
            [1, _("Open")],
            [],
            [2, _("Properties")]
        ]


    do_itemselected : (evt) ->
        switch evt.id
            when 1
                @item_exec()
            when 2
                DCore.Desktop.run_deepin_settings("system_information")
            else
                echo "computer unkown command id:#{evt.id} title:#{evt.title}"


class HomeVDir extends DesktopEntry
    constructor : ->
        entry = DCore.Desktop.get_home_entry()
        super(entry, false)


    get_id : ->
        _ITEM_ID_USER_HOME_


    get_name : ->
        _("Home")


    get_icon : ->
        DCore.get_theme_icon("user-home", 48)


    get_path : ->
        ""

    do_drop : (evt) ->
        super

        if not _IS_DND_INTERLNAL_(evt) or not is_item_been_selected(@id)
            tmp_list = []
            for file in evt.dataTransfer.files
                e = DCore.DEntry.create_by_path(decodeURI(file.path).replace(/^file:\/\//i, ""))
                if not e? then continue
                tmp_list.push(e)
            if tmp_list.length > 0 then DCore.DEntry.move(tmp_list, @entry)
        return

    do_dragenter : (evt) ->
        super

        if not _IS_DND_INTERLNAL_(evt) or not is_item_been_selected(@id)
            evt.dataTransfer.dropEffect = "move"
        return


    do_dragover : (evt) ->
        super

        if not _IS_DND_INTERLNAL_(evt) or not is_item_been_selected(@id)
            evt.dataTransfer.dropEffect = "move"
        return


    do_dragleave : (evt) ->
        super
        if @in_count > 0
            evt.preventDefault()
            if not _IS_DND_INTERLNAL_(evt) or not is_item_been_selected(@id)
                evt.dataTransfer.dropEffect = "move"
        return


    item_rename : ->
        return


    do_buildmenu : ->
        [
            [1, _("Open")],
            [],
            [2, _("Properties")]
        ]


    do_itemselected : (evt) ->
        switch evt.id
            when 1
                @item_exec()
            when 2
                try
                    #XXX: we get an error here when call the nautilus DBus interface
                    g_dbus_nautilus?.ShowItemProperties_sync(["file://#{DCore.DEntry.get_uri(@entry)}"], "")
                catch e
            else echo "computer unkown command id:#{evt.id} title:#{evt.title}"


class TrashVDir extends DesktopEntry
    constructor : ->
        entry = DCore.DEntry.get_trash_entry()
        super(entry, false)


    get_id : ->
        _ITEM_ID_TRASH_BIN_


    get_name : ->
        _("Trash")


    get_icon : ->
        if DCore.DEntry.get_trash_count() > 0
            DCore.get_theme_icon("user-trash-full", 48)
        else
            DCore.get_theme_icon("user-trash", 48)


    get_path : ->
        ""


    do_drop : (evt) ->
        super

        if is_item_been_selected(@id) == false
            tmp_list = []
            for file in evt.dataTransfer.files
                e = DCore.DEntry.create_by_path(decodeURI(file.path).replace(/^file:\/\//i, ""))
                if not e? then continue
                tmp_list.push(e)

            if tmp_list.length > 0 then DCore.DEntry.trash(tmp_list)
        return


    do_dragenter : (evt) ->
        super

        if not _IS_DND_INTERLNAL_(evt) or not is_item_been_selected(@id)
            evt.dataTransfer.dropEffect = "move"
        return


    do_dragover : (evt) ->
        super

        if not _IS_DND_INTERLNAL_(evt) or not is_item_been_selected(@id)
            evt.dataTransfer.dropEffect = "move"
        return


    do_dragleave : (evt) ->
        super
        if @in_count > 0
            evt.preventDefault()
            if not _IS_DND_INTERLNAL_(evt) or not is_item_been_selected(@id)
                evt.dataTransfer.dropEffect = "move"
        return


    item_rename : ->
        return


    do_buildmenu : ->
        menus = []
        menus.push([1, _("Open")])
        menus.push([])
        count = DCore.DEntry.get_trash_count()
        if count > 1
            menus.push([3, _("Clean up") + " #{count} " + _("items")])
        else if count == 1
            menus.push([3, _("Clean up") + " #{count} " + _("item")])
        else
            menus.push([3, _("Clean up"), false])
        menus


    do_itemselected : (evt) ->
        switch evt.id
            when 1
                @item_exec()
            when 3
                DCore.DEntry.confirm_trash()
            else
                echo "computer unkown command id:#{evt.id} title:#{evt.title}"
