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


Flag_setTimeout = null
t_set = 3000 # warning: must > 2s (THUMBNAIL_CREATION_DELAY  3s  - file save time 1s )

im_below_input_pixel = 100

cleanup_filename = (str) ->
    new_str = str.replace(/\n|\//g, "")
    if new_str == "." or new_str == ".."
        ""
    else
        new_str


_GET_ENTRY_FROM_PATH_ = (path) ->
    DCore.DEntry.create_by_path(decodeURI(path).replace(/^file:\/\//i, ""))


class Item extends Widget
    constructor: (@_entry, @modifiable = true, @deletable = true) ->
        @set_id()

        @is_in_select_area = false
        @ctrl_selected = false
        @selected = false
        @has_focus = false
        @clicked_before = 0

        @in_rename = false
        @delay_rename_tid = -1

        super(@id)

        el = @element
        @_position = {x:-1, y:-1, width:1*_PART_, height:1*_PART_}

        #el.setAttribute("tabindex", 0)
        el.draggable = true

        icon_box = document.createElement("div")
        icon_box.className = "item_icon"
        icon_box.draggable = false
        el.appendChild(icon_box)
        @item_icon = document.createElement("img")
        @item_icon.draggable = false
        icon_box.appendChild(@item_icon)
        @item_icon.addEventListener("load", ->
            @style.width = ""
            @style.height = ""
            @style.maxWidth = ""
            @style.maxHeight = ""
            @style.minWidth = ""
            @style.minHeight = ""

            if @width == @height
                @style.width = "48px"
                @style.height = "48px"
            else if @width > @height
                if @width >= 48
                    @style.maxWidth = "48px"
                else
                    @style.minWidth = "48px"
            else
                if @height >= 48
                    @style.maxHeight = "48px"
                else
                    @style.minHeight = "48px"
        )


        @item_attrib = document.createElement("ul")
        @item_attrib.className = "item_attrib"
        el.appendChild(@item_attrib)

        @item_name = document.createElement("div")
        @item_name.className = "item_name"
        el.appendChild(@item_name)
        @item_update()


    destroy : ->
        if (@_position.x > -1) and (@_position.y > -1) then clear_occupy(@id, @_position)
        super


    set_entry : (entry) =>
        @_entry = entry


    get_entry : =>
        @_entry


    set_id : =>
        @id = DCore.DEntry.get_id(@_entry)


    get_id : =>
        @id


    get_name : =>
        DCore.DEntry.get_name(@_entry)


    set_icon : (src = null) =>
        if src == null
            # TEST_GFILE
            if DCore.DEntry.can_thumbnail(@_entry)
                if (icon = DCore.DEntry.get_thumbnail(@_entry)) == null
                    #1. first use the get_icon to show
                    if (icon = DCore.DEntry.get_icon(@_entry)) != null
                        @item_icon.className = ""
                    else
                        icon = DCore.get_theme_icon(APP_DEFAULT_ICON, D_ICON_SIZE_NORMAL)
                        @item_icon.className = ""
                    #2. then set the 2s timeout to check the get_thumbnail
                    that = @
                    clearInterval(Flag_setTimeout) if Flag_setTimeout
                    Flag_setTimeout = setInterval(->
                        if (icon = DCore.DEntry.get_thumbnail(that._entry)) != null
                            that.item_icon.className = "previewshadow"
                            that.item_icon.src = icon
                            that = null
                            clearInterval(Flag_setTimeout)
                    ,t_set)

                else
                    @item_icon.className = "previewshadow"

            # TEST_GAPP
            else if (icon = DCore.DEntry.get_icon(@_entry)) != null
                @item_icon.className = ""
            # TEST_GAPP icon is not find
            else
                icon = DCore.get_theme_icon(FILE_DEFAULT_ICON, D_ICON_SIZE_NORMAL)
                @item_icon.className = ""
        else
            icon = src
        @item_icon.src = icon
        return


    get_path : =>
        DCore.DEntry.get_uri(@_entry)


    get_mtime : =>
        DCore.DEntry.get_mtime(@_entry)


    get_pos : =>
        ret_pos = {x : @_position.x, y : @_position.y, width : @_position.width, height : @_position.height}


    set_pos : (pos) =>
        [@_position.x, @_position.y] = [pos.x, pos.y]
        return


    _set_size : (pos) =>
        [@_position.width, @_position.height] = [pos.width, pos.height]
        return


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
            update_selected_stats(this, evt)
            if !is_selected_multiple_items()
                if @has_focus and evt.srcElement.className == "item_name" and @delay_rename_tid == -1
                    @delay_rename_tid = setTimeout(@item_rename, _RENAME_TIME_DELAY_)
                else if @in_rename
                    @item_complete_rename(true)
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


    display_full_name : =>
        @add_css_class("full_name")
        return


    display_short_name : =>
        @remove_css_class("full_name")
        return


    display_selected : =>
        @add_css_class("item_selected")


    display_not_selected : =>
        @remove_css_class("item_selected")
        return


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


    display_cut : =>
        @element.style.opacity = "0.5"
        return


    display_not_cut : =>
        @element.style.opacity = "1"
        return


    on_event_stoppropagation : (evt) ->
        evt.stopPropagation()
        return


    on_event_preventdefault : (evt) ->
        evt.stopPropagation()
        evt.preventDefault()
        return


    on_rename : (new_name) =>
        echo "on_rename:#{new_name}"
        DCore.DEntry.set_name(@_entry, new_name)
        #return false


    item_focus : =>
        @has_focus = true
        @display_full_name()
        @display_focus()
        return


    item_blur : =>
        @clear_delay_rename_timer()
        if @in_rename then @item_complete_rename(false)

        @display_short_name()
        @display_not_focus()
        @has_focus = false
        return


    item_selected : =>
        @display_selected()
        @item_name.style.pointerEvents = "auto"
        @selected = true
        return


    item_normal : =>
        @clear_delay_rename_timer()
        if @in_rename then @item_complete_rename(false)
        @display_not_selected()
        @item_name.style.pointerEvents = "none"
        @selected = false
        @clicked_before = 0
        return


    item_update : =>
        @set_icon()

        if @in_rename == false
            @item_name.innerText = @get_name()

        for i in @item_attrib.getElementsByTagName("li") by -1
            @item_attrib.removeChild(i)

        if @modifiable == false && @deletable == false then return

        flags = DCore.DEntry.get_flags(@_entry)
        if flags.read_only? and flags.read_only == 1
            ele = document.createElement("li")
            ele.innerHTML = "<img src=\"#{DCore.get_theme_icon(_FAI_READ_ONLY_, D_ICON_SIZE_SMALL)}\" draggable=\"false\" />"
            @item_attrib.appendChild(ele)
        if flags.symbolic_link? and flags.symbolic_link == 1
            ele = document.createElement("li")
            ele.innerHTML = "<img src=\"#{DCore.get_theme_icon(_FAT_SYM_LINK_, D_ICON_SIZE_SMALL)}\" draggable=\"false\" />"
            @item_attrib.appendChild(ele)
        if flags.unreadable? and flags.unreadable == 1
            ele = document.createElement("li")
            ele.innerHTML = "<img src=\"#{DCore.get_theme_icon(_FAT_UNREADABLE_, D_ICON_SIZE_SMALL)}\" draggable=\"false\" />"
            @item_attrib.appendChild(ele)
        return


    item_exec : =>
        DCore.DEntry.launch(@_entry, [])

    contextmenu_event_handler: (e)=>
        if not @in_rename
            e.preventDefault()
        else
            e.stopPropagation()

    item_rename : =>
        echo "item_name 1"
        # first make the contextmenu not showed when is in_renaming
        # menu = []
        # @item_name.parentElement.contextMenu = build_menu(menu)

        input_x = _ITEM_WIDTH_ * @_position.x
        input_y = _ITEM_HEIGHT_ * @_position.y + im_below_input_pixel
        DCore.Desktop.set_position_input(input_x,input_y)
        if @delay_rename_tid != -1 then
        if @selected == false then return
        if @in_rename == false
            echo "item_name 2"
            move_widget_to_rename_div(@)
            @display_full_name()
            @display_not_selected()
            @element.draggable = true
            @item_name.contentEditable = "true"
            @item_name.className = "item_renaming"
            @item_name.addEventListener("mousedown", @on_event_stoppropagation)
            @item_name.addEventListener("mouseup", @on_event_stoppropagation)
            @item_name.addEventListener("click", @on_event_stoppropagation)
            @item_name.addEventListener("dblclick", @on_event_stoppropagation)
            @item_name.addEventListener("contextmenu", @contextmenu_event_handler)
            @item_name.addEventListener("keydown", @on_item_rename_keydown)
            @item_name.addEventListener("keypress", @on_item_rename_keypress)
            @item_name.addEventListener("keyup", @on_item_rename_keyup)

            #XXX: workaround -> fix up get Enter keys before begining of rename
            @item_name.addEventListener("input", @on_item_rename_input)

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


    on_item_rename_keydown : (evt) =>
        evt.stopPropagation()
        echo "on_item_rename_keydown"
        echo "#{@item_name.innerText}"
        switch evt.keyCode
            when 35 # 'End' key, cant't handled in keypress; set caret to the end of whole name
                evt.preventDefault()
                ws = window.getSelection()
                range = document.createRange()
                if evt.shiftKey == true
                    range.setStart(@item_name.childNodes[0], ws.getRangeAt().startOffset)
                else
                    range.setStart(@item_name.childNodes[0], @item_name.childNodes[0].length)
                range.setEnd(@item_name.childNodes[0], @item_name.childNodes[0].length)
                ws.removeAllRanges()
                ws.addRange(range)
            when 36 # 'Home' key, cant't handled in keypress; set caret to the start of whole name
                evt.preventDefault()
                ws = window.getSelection()
                range = document.createRange()
                if evt.shiftKey == true
                    range.setEnd(@item_name.childNodes[0], ws.getRangeAt().endOffset)
                else
                    range.setEnd(@item_name.childNodes[0], 0)
                range.setStart(@item_name.childNodes[0], 0)
                ws.removeAllRanges()
                ws.addRange(range)
        return


    on_item_rename_keypress : (evt) =>
        evt.stopPropagation()
        echo "on_item_rename_keypress #{evt.keyCode}"
        switch evt.keyCode
            when 13   # enter
                evt.preventDefault()
                @item_complete_rename(true)
                # tell grid to ingore the same event after this event handler has been unregisterd
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

    on_item_rename_input : (evt) =>
        evt.stopPropagation()
        return


    item_complete_rename : (modify = true) =>
        if modify == true
            new_name = cleanup_filename(@item_name.innerText)
            if new_name.length > 0 and new_name != @get_name()
                rename = @on_rename(new_name)
                if not rename
                    @in_rename = false
                    #move_widget_to_grid_after_rename(@)
                    #return

        move_widget_to_grid_after_rename(@)
        @element.draggable = true
        @item_name.contentEditable = "false"
        @item_name.className = "item_name"
        @item_name.innerText = @get_name()
        @item_name.removeEventListener("mousedown", @on_event_stoppropagation)
        @item_name.removeEventListener("mouseup", @on_event_stoppropagation)
        @item_name.removeEventListener("click", @on_event_stoppropagation)
        @item_name.removeEventListener("dblclick", @on_event_stoppropagation)
        @item_name.removeEventListener("contextmenu", @contextmenu_event_handler)
        @item_name.removeEventListener("keydown", @on_item_rename_keydown)
        @item_name.removeEventListener("keypress", @on_item_rename_keypress)
        @item_name.removeEventListener("keyup", @on_item_rename_keyup)
        #XXX: workaround -> fix up get Enter keys before begining of rename
        @item_name.removeEventListener("input", @on_item_rename_input)

        @display_selected()

        @clear_delay_rename_timer()
        @in_rename = false

        return


    move: (x, y) =>
        style = @element.style
        style.position = "absolute"
        style.left = x
        style.top = y

