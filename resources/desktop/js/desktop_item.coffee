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
    constructor: (@name, @icon, @exec, @path) ->
        @selected = false
        @id = @path
        @in_rename = false

        @clicked = false
        @delay_rename = -1

        super

        el = @element
        info = {x:0, y:0, width:1, height:1}

        #el.setAttribute("tabindex", 0)
        el.draggable = true

        @item_icon = document.createElement("img")
        @item_icon.src = @icon
        @item_icon.draggable = false
        el.appendChild(@item_icon)

        @item_name = document.createElement("div")
        @item_name.className = "item_name"
        @item_name.innerText = shorten_text(@name, MAX_ITEM_TITLE)
        el.appendChild(@item_name)


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

        echo "do_click #{@clicked} #{@in_rename} #{@delay_rename}"
        false


    do_dblclick : (evt) =>
        echo "do_dblclick #{@clicked} #{@in_rename} #{@delay_rename}"

        if @delay_rename != -1
            clearTimeout(@delay_rename)
            @delay_rename = -1
        if @in_rename then @item_complete_rename(false)

        if evt.ctrlKey == true then return
        @item_exec()


    item_update : (icon) =>
        @item_icon.src = "#{icon}"


    item_exec : () =>
        DCore.run_command @exec


    item_selected : ->
        @selected = true
        @show_selected_box()


    item_normal : ->
        @selected = false
        @clicked = false
        @hide_selected_box()


    item_focus : ->
        @item_name.innerText = @name


    item_blur : ->
        if @delay_rename != -1
            clearTimeout(@delay_rename)
            @delay_rename = -1
        if @in_rename then @item_complete_rename()

        @item_name.innerText = shorten_text(@name, MAX_ITEM_TITLE)


    show_selected_box : =>
        @element.className += " item_selected"


    hide_selected_box : =>
        @element.className = @element.className.replace(/\ item_selected/g, "")


    show_hover_box : =>
        @element.className += " item_hover"


    hide_hover_box : =>
        @element.className = @element.className.replace(/\ item_hover/g, "")


    item_rename : =>
        echo "item_rename"
        @delay_rename = -1
        if @selected == false then return
        if @in_rename == false
            @element.draggable = false
            @item_name.contentEditable = "true"
            @item_name.style.webkitUserSelect = "text"
            @item_name.style.cursor = "text"
            @item_name.style.backgroundColor = "#FFF"
            @item_name.style.webkitUserModify = "read-write-plaintext-only"
            @item_name.focus()
            @item_name.addEventListener("mousedown", @event_stoppropagation)
            @item_name.addEventListener("dblclick", @event_stoppropagation)
            @item_name.addEventListener("keypress", @item_rename_keypress)

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
        @item_name.style.cursor = ""
        @item_name.style.backgroundColor = ""
        @item_name.style.webkitUserSelect = ""
        @item_name.style.webkitUserModify = ""
        @item_name.removeEventListener("mousedown", @event_stoppropagation)
        @item_name.removeEventListener("dblclick", @event_stoppropagation)
        @item_name.removeEventListener("keypress", @item_rename_keypress)

        new_name = cleanup_filename(@item_name.innerText)
        if modify == true and new_name.length > 0 and new_name != @name
            DCore.Desktop.item_rename(@id, new_name)

        if @delay_rename > 0
            clearTimeout(@delay_rename)
            @delay_rename = 0

        @in_rename = false
        @item_focus()


    destroy: ->
        info = load_position(this.path)
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


    do_dragover : (evt) =>
        evt.preventDefault()
        evt.stopPropagation()


    do_dragleave : (evt) =>
        evt.stopPropagation()
        if @selected == false
            --@in_count
            if @in_count == 0
                @hide_hover_box()


    do_contextmenu : () ->
        if @selected == false then update_selected_stats(this, evt)
        [
            [1, _("Open")],
#            [_("Open with"), [
#                    [35, "emaces"],
#                    [36, "geany"],
#                    [37, "vim"]
#                ]
#            ],
            [],
            [2, _("cut")],
            [3, _("copy")],
            [],
#            [4, _("create link")],
            [5, _("Rename")],
#            [_("copy to"), [
#                    [41, _("another desktop")],
#                    [42, _("home")],
#                    [43, _("desktop")]
#                ]
#           ],
#            [_("move to"), [
#                    [51, _("another desktop")],
#                    [52, _("home")],
#                    [53, _("desktop")]
#                ]
#            ],
            [6, _("Delete")],
            [],
            [7, _("Properties")]
        ]


    do_itemselected : (evt) =>
        switch evt.id
            when 1 then @item_exec()
            when 2 then selected_cut_to_clipboard()
            when 3 then selected_copy_to_clipboard()
            when 5 then @item_rename()
            when 6 then delete_selected_items()
            else echo "menu clicked:id=#{evt.id} title=#{evt.title}"


class Folder extends DesktopEntry
    constructor : ->
        super

        if not @exec?
            @exec = "gvfs-open \"#{@id}\""

        @div_pop = null
        @show_pop = false


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

        echo evt

        #if evt.dataTransfer.dropEffect == "link"
        file = decodeURI(evt.dataTransfer.getData("text/uri-list"))
        #@icon_close()
        @move_in(file)

        echo "do_drop #{evt.dataTransfer.dropEffect}"


    do_dragover : (evt) =>
        super
        evt.preventDefault()
        path = decodeURI(evt.dataTransfer.getData("text/uri-list"))
        if @path == path.substring(7)
            evt.dataTransfer.dropEffect = "none"
        else
            evt.dataTransfer.dropEffect = "link"

        echo "do_dragover #{evt.dataTransfer.dropEffect}"


    do_dragenter : (evt) =>
        super

        path = decodeURI(evt.dataTransfer.getData("text/uri-list"))
        if @path == path.substring(7)
            evt.dataTransfer.dropEffect = "none"
        else
            evt.dataTransfer.dropEffect = "link"

        echo "do_dragenter #{evt.dataTransfer.dropEffect}"


    do_dragleave : (evt) =>
        super

        #@icon_close()


    item_update : (icon) ->
        if @show_pop == true then @reflesh_pop_block()
        super


    item_blur : ->
        if @div_pop != null then @hide_pop_block()
        super


    destroy : ->
        if @div_pop != null then @hide_pop_block()
        super


    show_pop_block : =>
        if @selected == false then return
        if @div_pop != null then return

        items = DCore.Desktop.get_items_by_dir(@id)
        if items.length == 0 then return

        @div_pop = document.createElement("div")
        @div_pop.setAttribute("id", "pop_grid")
        document.body.appendChild(@div_pop)
        @div_pop.addEventListener("mousedown", @event_stoppropagation)

        @show_pop = true

        @fill_pop_block(items)


    reflesh_pop_block : =>
        for i in @div_pop.getElementsByTagName("ul")
            i.parentElement.removeChild(i)

        for i in @div_pop.getElementsByTagName("div")
            if i.id == "pop_downarrow" or i.id == "pop_uparrow"
                i.parentElement.removeChild(i)

        items = DCore.Desktop.get_items_by_dir(@element.id)
        if items.length == 0
            @hide_pop_block()
        else
            @fill_pop_block(items)


    fill_pop_block : (items) =>
        ele_ul = document.createElement("ul")
        ele_ul.setAttribute("title", @id)
        @div_pop.appendChild(ele_ul)

        for s in items
            ele = document.createElement("li")
            ele.setAttribute('id',  s.EntryPath)
            ele.draggable = true
            ele.innerHTML = "<img src=\"#{s.Icon}\"><div>#{shorten_text(s.Name, MAX_ITEM_TITLE)}</div>"

            ele.addEventListener('mousedown', (evt) ->
                evt.stopPropagation()
                false
            )
            ele.addEventListener('dragstart', (evt) ->
                    evt.dataTransfer.setData("text/uri-list", "file://#{this.id}")
                    evt.dataTransfer.setData("text/plain", "#{this.id}")
                    evt.dataTransfer.effectAllowed = "all"
            )
            ele.addEventListener('dragend', (evt) ->
                #reflesh_desktop_new_items()
            )
            if s.Exec?
                ele.setAttribute("title", s.Exec)
                ele.addEventListener('dblclick', (evt) ->
                    DCore.run_command this.title
                    Widget.look_up(this.parentElement.title)?.hide_pop_block()
                )
            else
                ele.addEventListener('dblclick', (evt) ->
                    DCore.run_command1 "gvfs-open", this.id
                    Widget.look_up(this.parentElement.title)?.hide_pop_block()
                )
            ele_ul.appendChild(ele)


        if items.length <= 3
            col = items.length
        else if items.length <= 6
            col = 3
        else if items.length <= 12
            col = 4
        else if items.length <= 20
            col = 5
        else
            col = 6
        @div_pop.style.width = "#{col * i_width + 10}px"

        arrow = document.createElement("div")

        n = Math.ceil(items.length / col)
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
            @div_pop.parentElement?.removeChild(@div_pop)
            delete @div_pop
            @div_pop = null
        @show_pop = false


    move_in: (c_path) ->
        echo "move to #{c_path} from #{@path}"
        p = c_path.replace("file://", "")
        DCore.run_command2("mv", p, @path)


class NormalFile extends DesktopEntry


class Application extends DesktopEntry
#TODO: if drag target.constructor.name = "Application" then DCore.Desktop.merge_files(itself, target)
    do_drop : (evt) ->
        super

        echo "123456"
        if not evt.fromElement? then return


class DesktopApplet extends Item
