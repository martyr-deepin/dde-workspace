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


shorten_text = (str, n) ->
    r = /[^\x00-\xff]/g
    if str.replace(r, "mm").length <= n
        return str

    mid = Math.floor(n / 2)
    n = n - 3
    for i in [mid..(str.length - 1)]
        if str.substr(0, i).replace(r, "mm").length >= n
            return str.substr(0, i) + "..."

    return str


cleanup_filename = (str) ->
    new_str = str.replace(/\n|\//g, "")
    if new_str == "." or new_str == ".."
        ""
    else
        new_str


class Item extends Widget
    constructor: (@entry) ->
        @id = DCore.DEntry.get_id(@entry)

        @selected = false
        @focused = false
        @in_rename = false

        @clicked = false
        @delay_rename = -1

        super

        el = @element
        info = {x:0, y:0, width:1, height:1}

        #el.setAttribute("tabindex", 0)
        el.draggable = true

        @item_icon = document.createElement("img")
        @item_icon.src = DCore.DEntry.get_icon(@entry)
        @item_icon.draggable = false
        el.appendChild(@item_icon)

        @item_name = document.createElement("div")
        @item_name.className = "item_name"
        @item_name.innerText = shorten_text(@get_name(), MAX_ITEM_TITLE)
        el.appendChild(@item_name)


    get_name : ->
        DCore.DEntry.get_name(@entry)


    get_icon : ->
        DCore.DEntry.get_icon(@entry)


    get_path : ->
        DCore.DEntry.get_path(@entry)


    get_mtime : ->
        DCore.DEntry.get_mtime(@entry)


    do_mouseover : (evt) =>
        @show_hover_box()


    do_mouseout : (evt) =>
        @hide_hover_box()


    do_mousedown : (evt) =>
        evt.stopPropagation()
        if evt.button == 0 then update_selected_stats(this, evt)
        false


    do_click : (evt) =>
        evt.stopPropagation()
        if @clicked == false
            @clicked = true
            update_selected_stats(this, evt)
        else
            if evt.srcElement.className == "item_name"
                if @delay_rename == -1 then @delay_rename = setTimeout(() =>
                        @item_rename()
                    , 200);
            else
                if @in_rename
                    @item_complete_rename(true)
                else
                    update_selected_stats(this, evt)

        #echo "do_click #{@clicked} #{@in_rename} #{@delay_rename}"
        false


    do_rightclick : (evt) ->
        evt.stopPropagation()
        if @selected == false then update_selected_stats(this, evt)


    do_dblclick : (evt) ->
        #echo "do_dblclick #{@clicked} #{@in_rename} #{@delay_rename}"

        if @delay_rename != -1
            clearTimeout(@delay_rename)
            @delay_rename = -1
        if @in_rename then @item_complete_rename(false)

        if evt.ctrlKey == true then return
        @item_exec()


    item_update : () =>
        @item_icon.src = @get_icon()
        if @in_rename == false
            if @focused then @item_name.innerText = @get_name()
            else @item_name.innerText = shorten_text(@get_name(), MAX_ITEM_TITLE)


    item_exec : =>
        DCore.DEntry.launch(@entry, [])


    item_selected : ->
        @selected = true
        @show_selected_box()


    item_normal : ->
        @selected = false
        @clicked = false
        @hide_selected_box()


    item_focus : ->
        @item_name.innerText = @get_name()
        @focused = true


    item_blur : ->
        if @delay_rename != -1
            clearTimeout(@delay_rename)
            @delay_rename = -1
        if @in_rename then @item_complete_rename()

        @item_name.innerText = shorten_text(@get_name(), MAX_ITEM_TITLE)
        @focused = false


    show_selected_box : =>
        @element.className += " item_selected"


    hide_selected_box : =>
        @element.className = @element.className.replace(/\ item_selected/g, "")


    show_hover_box : =>
        @element.className += " item_hover"


    hide_hover_box : =>
        @element.className = @element.className.replace(/\ item_hover/g, "")


    on_rename : (new_name) ->
        DCore.DEntry.set_name(@entry, new_name)


    item_rename : =>
        echo "item_rename"
        @delay_rename = -1
        if @selected == false then return
        if @in_rename == false
            @element.draggable = false
            @item_name.contentEditable = "true"
            @item_name.className = "item_renaming"
            @item_name.addEventListener("mousedown", @event_stoppropagation)
            @item_name.addEventListener("click", @event_stoppropagation)
            @item_name.addEventListener("dblclick", @event_stoppropagation)
            @item_name.addEventListener("keypress", @item_rename_keypress)
            @item_name.focus()
            #TODO: set caret pos to end or select all text when begin editing
            #ws = window.getSelection()
            #ws.removeAllRanges()
            #range = document.createRange()
            #range.setStart(@item_name.childNodes[0], 0)
            #range.setEnd(@item_name.childNodes[0], @item_name.innerText.length)
            #ws.addRange(range)

            @in_rename = true
        return


    event_stoppropagation : (evt) =>
        evt.stopPropagation()


    item_rename_keypress : (evt) =>
        evt.stopPropagation()
        switch evt.keyCode
            when 13   # enter
                evt.preventDefault()
                @item_complete_rename(true)
            when 27   # esc
                evt.preventDefault()
                @item_complete_rename(false)
            when 47   # /
                evt.preventDefault()
        return


    item_complete_rename : (modify = true) =>
        @element.draggable = true
        @item_name.contentEditable = "false"
        @item_name.className = "item_name"
        @item_name.removeEventListener("mousedown", @event_stoppropagation)
        @item_name.removeEventListener("click", @event_stoppropagation)
        @item_name.removeEventListener("dblclick", @event_stoppropagation)
        @item_name.removeEventListener("keypress", @item_rename_keypress)

        new_name = cleanup_filename(@item_name.innerText)
        if modify == true and new_name.length > 0 and new_name != @get_name()
            on_rename(new_name)

        if @delay_rename > 0
            clearTimeout(@delay_rename)
            @delay_rename = 0

        @in_rename = false
        @item_focus()


    destroy: ->
        info = load_position(@id)
        clear_occupy(info)
        super


    move: (x, y) ->
        style = @element.style
        style.position = "absolute"
        style.left = x
        style.top = y


class DesktopEntry extends Item
    constructor : ->
        @in_count = 0

        super


    do_dragstart : (evt) =>
        evt.stopPropagation()

        item_dragstart_handler(this, evt)

        return


    do_dragend : (evt) =>
        evt.stopPropagation()
        evt.preventDefault()
        if evt.dataTransfer.dropEffect == "move"
            drag_update_selected_pos(this, evt)

        #else if evt.dataTransfer.dropEffect == "link"
            #node = evt.target
            #node.parentNode.removeChild(node)

        return


    do_drop : (evt) =>
        evt.preventDefault()
        evt.stopPropagation()
        if @selected == false
            @hide_hover_box()
            @in_count = 0


    do_dragenter : (evt) =>
        evt.stopPropagation()

        if @selected == false
            ++@in_count
            if @in_count == 1
                @show_hover_box()

        all_selected_items = evt.dataTransfer.getData("text/uri-list")
        files = all_selected_items.split("\n")
        if files.indexOf(encodeURI("file://" + @get_path())) >= 0
            evt.dataTransfer.dropEffect = "none"
        else
            evt.dataTransfer.dropEffect = "link"

        #FIXME: test propose only, should disable on public release
        #echo "do_dragenter #{evt.dataTransfer.dropEffect}"
        return


    do_dragover : (evt) =>
        evt.preventDefault()
        evt.stopPropagation()

        all_selected_items = evt.dataTransfer.getData("text/uri-list")
        files = all_selected_items.split("\n")
        if files.indexOf(encodeURI("file://" + @get_path())) >= 0
            evt.dataTransfer.dropEffect = "none"
        else
            evt.dataTransfer.dropEffect = "link"

        #FIXME: test propose only, should disable on public release
        #echo "do_dragover #{evt.dataTransfer.dropEffect}"
        return


    do_dragleave : (evt) =>
        evt.stopPropagation()
        if @selected == false
            --@in_count
            if @in_count == 0
                @hide_hover_box()


    do_buildmenu : () ->
        build_selected_items_menu()


    do_itemselected : (evt) =>
        switch evt.id
            when 1 then open_selected_items()
            when 3 then selected_cut_to_clipboard()
            when 4 then selected_copy_to_clipboard()
            when 6 then @item_rename()
            when 9 then delete_selected_items()
            when 10 then show_selected_items_Properties()
            else echo "menu clicked:id=#{env.id} title=#{env.title}"


class Folder extends DesktopEntry
    constructor : ->
        super

       if not @exec?
           @exec = "gvfs-open \"#{@id}\""


    do_drop : (evt) =>
        super

        all_selected_items = evt.dataTransfer.getData("text/uri-list")
        files = all_selected_items.split("\n")

        for f in files
            e = DCore.DEntry.create_by_path(decodeURI(f).substr(7))
            if e? then continue
            if DCore.DEntry.get_type(e) != FILE_TYPE_RICH_DIR
                @move_in(e)

        return


    do_dragenter : (evt) =>
        evt.stopPropagation()

        if @selected == false
            ++@in_count
            if @in_count == 1
                @show_hover_box()

        all_selected_items = evt.dataTransfer.getData("text/uri-list")
        files = all_selected_items.split("\n")
        if files.indexOf(encodeURI("file://" + @get_path())) >= 0
            evt.dataTransfer.dropEffect = "none"
        else
            evt.dataTransfer.dropEffect = "move"

        #FIXME: test propose only, should disable on public release
        #echo "do_dragenter #{evt.dataTransfer.dropEffect}"
        return


    do_dragover : (evt) =>
        evt.preventDefault()
        evt.stopPropagation()

        all_selected_items = evt.dataTransfer.getData("text/uri-list")
        files = all_selected_items.split("\n")
        enc_path = encodeURI("file://" + @get_path())
        if files.indexOf(enc_path) >= 0
            evt.dataTransfer.dropEffect = "none"
        else
            evt.dataTransfer.dropEffect = "move"

        #echo "do_dragover #{evt.dataTransfer.dropEffect}"
        return


    move_in: (move_entry) ->
        DCore.DEntry.move(@entry, move_entry)


class RichDir extends DesktopEntry
    constructor : ->
        super

        if not @exec?
            @exec = "gvfs-open \"#{@id}\""

        @div_pop = null
        @show_pop = false


    get_name : ->
        DCore.Desktop.get_rich_dir_name(@entry)


    get_icon : ->
        DCore.Desktop.get_rich_dir_icon(@entry)


    do_click : (evt) =>
        super
        if evt.shiftKey == false && evt.ctrlKey == false
            if @show_pop == false
                @show_pop_block()


    do_dblclick : (evt) =>
        if @show_pop == true
            @hide_pop_block()
        super


    do_dragstart : (evt) =>
        if @show_pop == true
            @hide_pop_block()
        super


    do_drop : (evt) =>
        super

        all_selected_items = evt.dataTransfer.getData("text/uri-list")
        files = all_selected_items.split("\n")
        for file in files
            e = DCore.DEntry.create_by_path(decodeURI(file).substr(7))
            if e? and file.length > 0 then @move_in(e)

        return


    do_dragenter : (evt) =>
        evt.stopPropagation()

        if @selected == false
            ++@in_count
            if @in_count == 1
                @show_hover_box()

        all_selected_items = evt.dataTransfer.getData("text/uri-list")
        files = all_selected_items.split("\n")
        if files.indexOf(encodeURI("file://" + @get_path())) >= 0
            evt.dataTransfer.dropEffect = "none"
        else
            evt.dataTransfer.dropEffect = "move"

        #FIXME: test propose only, should disable on public release
        #echo "do_dragenter #{evt.dataTransfer.dropEffect}"
        return


    do_dragover : (evt) =>
        evt.preventDefault()
        evt.stopPropagation()

        all_selected_items = evt.dataTransfer.getData("text/uri-list")
        files = all_selected_items.split("\n")
        if files.indexOf(encodeURI("file://" + @get_path())) >= 0
            evt.dataTransfer.dropEffect = "none"
        else
            evt.dataTransfer.dropEffect = "move"

        #echo "do_dragover #{evt.dataTransfer.dropEffect}"
        return


    item_update : () ->
        if @show_pop == true then @reflesh_pop_block()
        super


    item_blur : ->
        if @div_pop != null then @hide_pop_block()
        super


    on_rename : (new_name) ->
        DCore.Desktop.set_rich_dir_name(@entry, new_name)


    destroy : ->
        if @div_pop != null then @hide_pop_block()
        super


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
        @div_pop.addEventListener("mousedown", @event_stoppropagation)

        @show_pop = true

        @fill_pop_block()


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
        else
            @fill_pop_block()


    fill_pop_block : () =>
        ele_ul = document.createElement("ul")
        ele_ul.setAttribute("title", @id)
        @div_pop.appendChild(ele_ul)

        for i, e of @sub_items
            ele = document.createElement("li")
            ele.setAttribute('id', i)
            ele.draggable = true
            s = document.createElement("img")
            s.src = DCore.DEntry.get_icon(e)
            ele.appendChild(s)
            s = document.createElement("div")
            s.innerText = shorten_text(DCore.DEntry.get_name(e), MAX_ITEM_TITLE)
            ele.appendChild(s)

            ele.addEventListener('mousedown', (evt) ->
                evt.stopPropagation()
            )
            ele.addEventListener('click', (evt) ->
                evt.stopPropagation()
            )
            ele.addEventListener('dragstart', (evt) ->
                evt.stopPropagation()
                evt.dataTransfer.setData("text/uri-list", "file://#{encodeURI(this.id)}")
                evt.dataTransfer.effectAllowed = "moveCopy"
            )
            ele.addEventListener('dragend', (evt) ->
                evt.stopPropagation()
            )
            ele.addEventListener('dblclick', (evt) ->
                w = Widget.look_up(this.parentElement.title)
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
        if @sub_items_count > 24
            @div_pop.style.width = "#{col * i_width + 10}px" # 8px for scrollbar
        else
            @div_pop.style.width = "#{col * i_width + 2}px" # 2px for border
        arrow = document.createElement("div")

        n = Math.ceil(@sub_items_count / col)
        if n > 4 then n = 4
        n = n * i_height + 20
        if s_height - @element.offsetTop > n
            @div_pop.style.top = "#{@element.offsetTop + @element.offsetHeight + 20}px"
            arrow_pos = false
        else
            @div_pop.style.top = "#{@element.offsetTop - n - 16}px"
            arrow_pos = true

        n = (col * i_width) / 2
        p = @element.offsetLeft + @element.offsetWidth / 2 - 10
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


    move_in: (move_entry) ->
        DCore.DEntry.move(@entry, move_entry)


class Application extends DesktopEntry
#TODO: if drag target.constructor.name = "Application" then DCore.Desktop.merge_files(itself, target)
    do_drop : (evt) ->
        super

        tmp_list = []
        all_are_apps = true
        all_selected_items = evt.dataTransfer.getData("text/uri-list")
        files = all_selected_items.split("\n")
        for f in files
            e = DCore.DEntry.create_by_path(decodeURI(f).substr(7))
            if e? then continue
            if DCore.DEntry.get_type(e) != FILE_TYPE_APP
                all_are_apps = false

            tmp_list.push(f)

        if all_are_apps == true
            tmp_list.push(@get_path())
            DCore.Desktop.create_rich_dir(tmp_list)
        else
            DCore.DEntry.launch(@entry, tmp_list)
        return


class NormalFile extends DesktopEntry


class DesktopApplet extends Item


#TODO: desktop applet like "computer" and "profile", etc
