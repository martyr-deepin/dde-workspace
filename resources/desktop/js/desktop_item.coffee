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

# canvas cache for drawing rich dir draging mouse image
richdir_drag_canvas = document.createElement("canvas")
richdir_drag_context = richdir_drag_canvas.getContext('2d')

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
            if DCore.DEntry.can_thumbnail(@_entry)
                if (icon = DCore.DEntry.get_thumbnail(@_entry)) == null
                    #1. first use the get_icon to show
                    if (icon = DCore.DEntry.get_icon(@_entry)) != null
                        @item_icon.className = ""
                    else
                        icon = DCore.get_theme_icon("invalid-dock_app", D_ICON_SIZE_NORMAL)
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

            else if (icon = DCore.DEntry.get_icon(@_entry)) != null
                @item_icon.className = ""
            else
                icon = DCore.get_theme_icon("invalid-dock_app", D_ICON_SIZE_NORMAL)
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
        DCore.DEntry.set_name(@_entry, new_name)


    item_focus : =>
        @has_focus = true
        @display_full_name()
        @display_focus()
        return


    item_blur : =>
        @clear_delay_rename_timer()
        if @in_rename then @item_complete_rename(true)

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


    item_rename : =>
        # first make the contextmenu not showed when is in_renaming 
        menu = []
        @item_name.parentElement.contextMenu = build_menu(menu)
        
        input_x = _ITEM_WIDTH_ * @_position.x
        input_y = _ITEM_HEIGHT_ * @_position.y + im_below_input_pixel
        DCore.Desktop.set_position_input(input_x,input_y)
        if @delay_rename_tid != -1 then
        if @selected == false then return
        if @in_rename == false
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
            @item_name.addEventListener("contextmenu", @on_event_stoppropagation)
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
                if not @on_rename(new_name)
                    @in_rename = false
                    move_widget_to_grid_after_rename(@)
                    return

        move_widget_to_grid_after_rename(@)
        @element.draggable = true
        @item_name.contentEditable = "false"
        @item_name.className = "item_name"
        @item_name.innerText = @get_name()
        @item_name.removeEventListener("mousedown", @on_event_stoppropagation)
        @item_name.removeEventListener("mouseup", @on_event_stoppropagation)
        @item_name.removeEventListener("click", @on_event_stoppropagation)
        @item_name.removeEventListener("dblclick", @on_event_stoppropagation)
        @item_name.removeEventListener("contextmenu", @on_event_preventdefault)
        @item_name.removeEventListener("keydown", @on_item_rename_keydown)
        @item_name.removeEventListener("keypress", @on_item_rename_keypress)
        @item_name.removeEventListener("keyup", @on_item_rename_keyup)
        #XXX: workaround -> fix up get Enter keys before begining of rename
        #@item_name.removeEventListener("input", @on_item_rename_input)

        @display_selected()

        @clear_delay_rename_timer()
        @in_rename = false

        return


    move: (x, y) =>
        style = @element.style
        style.position = "absolute"
        style.left = x
        style.top = y


class DesktopEntry extends Item
    constructor : ->
        super
        @add_css_class("DesktopEntry")


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

    do_buildmenu : ->
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


    do_itemselected : (evt) ->
        switch evt.id
            when 1 then open_selected_items()
            when 3 then selected_cut_to_clipboard()
            when 4 then selected_copy_to_clipboard()
            when 6 then @item_rename()
            when 9 then delete_selected_items(evt.shiftKey == true)
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


class Folder extends DesktopEntry
    set_icon : (src = null) =>
        if src == null
            icon = DCore.get_theme_icon("folder", D_ICON_SIZE_NORMAL)
        else
            icon = src
        super(icon)


    do_drop : (evt) ->
        super
        if _IS_DND_INTERLNAL_(evt) and @selected
        else
            tmp_list = []
            for file in evt.dataTransfer.files
                if (e = DCore.DEntry.create_by_path(decodeURI(file.path).replace(/^file:\/\//i, "")))?
                    tmp_list.push(e)
            if tmp_list.length > 0 then DCore.DEntry.move(tmp_list, @_entry, true)
        return


    do_dragenter : (evt) ->
        super
        if _IS_DND_INTERLNAL_(evt) and @selected
        else
            evt.dataTransfer.dropEffect = "move"
        return


    do_dragover : (evt) ->
        super
        if _IS_DND_INTERLNAL_(evt) and @selected
        else
            evt.dataTransfer.dropEffect = "move"
        return


    do_dragleave : (evt) ->
        super
        if _IS_DND_INTERLNAL_(evt) and @selected
        else
            evt.dataTransfer.dropEffect = "move"
        return


class RichDir extends DesktopEntry
    constructor : (entry) ->
        super(entry, false, true)
        @div_pop = null
        @show_pop = false


    destroy : ->
        if @div_pop != null then @hide_pop_block()
        super


    get_name : =>
        DCore.Desktop.get_rich_dir_name(@_entry)


    set_icon : (src = null) =>
        if src == null
            icon = DCore.Desktop.get_rich_dir_icon(@_entry)
        else
            icon = src
        super(icon)

    do_click : (evt) ->
        evt.stopPropagation()
        if @clicked_before == 1
            @clicked_before = 2
            if @show_pop == false and evt.shiftKey == false and evt.ctrlKey == false then @show_pop_block()
        else
            update_selected_stats(this, evt)
            if !is_selected_multiple_items()
                if @show_pop == false
                    if @in_rename
                        @item_complete_rename(true)
                    else
                        @clear_delay_rename_timer()
                        if evt.shiftKey == false and evt.ctrlKey == false then @show_pop_block()
                else
                    @hide_pop_block()
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


    do_rightclick : (evt) ->
        if @show_pop == true then @hide_pop_block()
        super


    do_dragstart : (evt) ->
        if @show_pop == true then @hide_pop_block()
        super


    do_drop : (evt) ->
        super
        if _IS_DND_INTERLNAL_(evt) and @selected
        else
            tmp_list = []
            for file in evt.dataTransfer.files
                e = DCore.DEntry.create_by_path(decodeURI(file.path).replace(/^file:\/\//i, ""))
                if not e? then continue
                if DCore.DEntry.get_type(e) == FILE_TYPE_APP then tmp_list.push(e)
                # tmp_list.push(e)
            if tmp_list.length > 0 then DCore.DEntry.move(tmp_list, @_entry, true)
        return

    do_dragenter : (evt) ->
        super
        if _IS_DND_INTERLNAL_(evt) and @selected
        else
            evt.dataTransfer.dropEffect = "move"
        return


    do_dragover : (evt) ->
        super
        if _IS_DND_INTERLNAL_(evt) and @selected
        else
            evt.dataTransfer.dropEffect = "move"
        return


    do_dragleave : (evt) ->
        super
        if _IS_DND_INTERLNAL_(evt) and @selected
        else
            evt.dataTransfer.dropEffect = "move"
        return


    do_buildmenu : ->
        menus = []
        menus.push([1, _("_Open")])
        menus.push([])
        menus.push([3, _("_Rename"), not is_selected_multiple_items()])
        menus.push([])
        menus.push([5, _("_Ungroup")])
        menus.push([])
        menus.push([7, _("_Delete")])
        menus


    do_itemselected : (evt) ->
        switch evt.id
            when 1 then @item_exec()
            when 3 then @item_rename()
            when 5 then @item_ungroup()
            when 7
                list = []
                list.push(@_entry)
                DCore.DEntry.trash(list)
            else echo "menu clicked:id=#{env.id} title=#{env.title}"
        return


    item_normal : =>
        if @div_pop != null then @hide_pop_block()
        super


    item_blur : =>
        if @div_pop != null then @hide_pop_block()
        super


    item_update : =>
        list = DCore.DEntry.list_files(@_entry)
        if list.length <= 1
            if @show_pop == true
                @hide_pop_block()

            pos = @get_pos()
            clear_occupy(@id, @_position)
            [@_position.x, @_position.y] = [-1, -1]
            if list.length > 0
                save_position(DCore.DEntry.get_id(list[0]), pos)
                DCore.DEntry.move(list, g_desktop_entry, false)
            DCore.DEntry.delete_files([@_entry], false)
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


    item_hint : =>
        apply_animation(@item_icon, "item_flash", "1s", "cubic-bezier(0, 0, 0.35, -1)")
        id = setTimeout(=>
            @item_icon.style.webkitAnimation = ""
            clearTimeout(id)
        , 1000)


    item_exec : =>
        if @show_pop == false then @show_pop_block()


    item_rename : =>
        if @show_pop == true then @hide_pop_block()
        super


    item_ungroup: =>
        clear_occupy(@id, @_position)
        [@_position.x, @_position.y] = [-1, -1]
        DCore.DEntry.move(DCore.DEntry.list_files(@_entry), g_desktop_entry, false)
        DCore.DEntry.delete_files([@_entry], false)


    on_rename : (new_name) =>
        DCore.Desktop.set_rich_dir_name(@_entry, new_name)


    on_drag_event_none : (evt) ->
        evt.stopPropagation()
        evt.dataTransfer.dropEffect = "none"
        return


    show_pop_block : =>
        if @selected == false then return
        if @div_pop != null then return

        @sub_items = {}
        @sub_items_count = 0
        for e in DCore.DEntry.list_files(@_entry)
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
        @div_pop.addEventListener("dragenter", @on_drag_event_none)
        @div_pop.addEventListener("dragover", @on_drag_event_none)

        @show_pop = true

        @display_not_selected()
        @display_not_focus()
        @display_short_name()

        @fill_pop_block()
        return


    reflesh_pop_block : =>
        for i in @div_pop.getElementsByTagName("ul") by -1
            i.parentElement.removeChild(i)

        for i in @div_pop.getElementsByTagName("div") by -1
            i.parentElement.removeChild(i) if i.id.match(/^pop_arrow_.+/)
        @fill_pop_block()
        return


    fill_pop_block : =>
        ele_ul = document.createElement("ul")
        ele_ul.setAttribute("id", @id)
        @div_pop.appendChild(ele_ul)
        
        menus_div_pop = []
        @div_pop.parentElement.contextMenu = build_menu(menus_div_pop)
        
        # how many we can hold per line due to workarea width
        # 20px for ul padding, 2px for border, 8px for scrollbar
        num_max = Math.floor((s_width - 30) / _ITEM_WIDTH_)
        # calc ideal columns
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
        # restrict the col item number
        if col > num_max then col = num_max

        # calc ideal rows
        row = col - 1
        if row < 1 then row = 1
        if row > 4 then row = 4

        for i, e of @sub_items
            ele = document.createElement("li")
            ele.setAttribute('id', i)
            ele.setAttribute('title', DCore.DEntry.get_name(e))
            ele.draggable = true

            if @sub_items_count <= 3 then ele.className = "auto_height"

            sb = document.createElement("div")
            sb.className = "item_icon"
            ele.appendChild(sb)
            s = document.createElement("img")
            # s.src = DCore.DEntry.get_icon(e)
            if (s.src = DCore.DEntry.get_icon(e)) == null
                s.src = DCore.get_theme_icon("invalid-dock_app", D_ICON_SIZE_NORMAL)
                echo "warning: richdir child get_icon is null:" + s.src
            sb.appendChild(s)
            s = document.createElement("div")
            s.className = "item_name"
            s.innerText = DCore.DEntry.get_name(e)
            ele.appendChild(s)

            ele.addEventListener('dragstart', (evt) ->
                evt.stopPropagation()
                w = Widget.look_up(this.parentElement.id)
                if w? then e = w.sub_items[this.id]
                if e?
                    evt.dataTransfer.setData("text/uri-list", DCore.DEntry.get_uri(e))
                    _SET_DND_RICHDIR_FLAG_(evt)
                    evt.dataTransfer.effectAllowed = "all"
                else
                    evt.dataTransfer.effectAllowed = "none"

                richdir_drag_canvas.width = _ITEM_WIDTH_
                richdir_drag_canvas.height = _ITEM_HEIGHT_
                draw_icon_on_canvas(richdir_drag_context, 0, 0, @getElementsByTagName("img")[0], this.innerText)
                evt.dataTransfer.setDragCanvas(richdir_drag_canvas, 48, 24)
                return
            )
            ele.addEventListener('dragend', (evt) ->
                evt.stopPropagation()
            )
            ele.addEventListener('dragenter', (evt) ->
                evt.stopPropagation()
                evt.dataTransfer.dropEffect = "none"
            )
            ele.addEventListener('dragover', (evt) ->
                evt.stopPropagation()
                evt.dataTransfer.dropEffect = "none"
            )
            ele.addEventListener('dblclick', (evt) ->
                evt.stopPropagation()
                w = Widget.look_up(this.parentElement.id)
                if w? then e = w.sub_items[this.id]
                if e?
                    if !DCore.DEntry.launch(e, [])
                        if confirm(_("The link has expired. Do you want to delete it?"), _("Warning"))
                            list = []
                            list.push(e)
                            DCore.DEntry.trash(list)
                if w? then w.hide_pop_block()
            )

            ele.addEventListener('contextmenu', (evt) ->
                evt.stopPropagation()
                w = Widget.look_up(this.parentElement.id)
                @contextMenu = build_menu(w.build_block_item_menu())
            )

            ele.addEventListener("itemselected", (evt) ->
                evt.stopPropagation()
                w = Widget.look_up(this.parentElement.id)
                w.block_do_itemselected(evt, this)
            )

            ele_ul.appendChild(ele)

        #calc ideal pop div width
        @div_pop.style.width = "#{col * _ITEM_WIDTH_ + 22}px"
        ele_ul.style.maxHeight = "#{row * _ITEM_HEIGHT_}px"

        n = @element.offsetTop + Math.min(_ITEM_HEIGHT_, @element.offsetHeight)
        num_max = s_height - n
        if (num_max < @div_pop.offsetHeight) and (num_max < @element.offsetTop)
            arrow_pos_at_bottom = true
            num_max = @element.offsetTop
        else
            arrow_pos_at_bottom = false

        # how many we can hold per column due to workarea height
        num_max = Math.max(Math.floor((num_max - 22) / _ITEM_HEIGHT_), 1)
        if row > num_max then row = num_max
        # restrict the real pop div size
        if @sub_items_count > col * row
            pop_width = col * _ITEM_WIDTH_ + 30
            @div_pop.style.width = "#{pop_width}px"
        pop_height = row * _ITEM_HEIGHT_
        ele_ul.style.maxHeight = "#{pop_height}px"

        if arrow_pos_at_bottom == true
            pop_top = @element.offsetTop - @div_pop.offsetHeight - 6
        else
            pop_top = n + 14
        @div_pop.style.top = "#{pop_top}px"

        # calc and make the arrow
        n = @div_pop.offsetWidth / 2 + 1
        p = @element.offsetLeft + @element.offsetWidth / 2
        arrow_outer = document.createElement("div")
        arrow_mid = document.createElement("div")
        arrow_inner = document.createElement("div")
        if p < n
            @div_pop.style.left      = "#{s_offset_x}px"
            arrow_outer.style.left  = "#{p - 8}px"
            arrow_mid.style.left     = "#{p - 8}px"
            arrow_inner.style.left   = "#{p - 7}px"
        else if p + n > s_width
            @div_pop.style.left      = "#{s_width - 2 * n}px"
            arrow_outer.style.right = "#{s_width - p - 14}px"
            arrow_mid.style.right    = "#{s_width - p - 14}px"
            arrow_inner.style.right  = "#{s_width - p - 13}px"
        else
            @div_pop.style.left      = "#{p - n + 6}px"
            arrow_outer.style.left  = "#{n - 9}px"
            arrow_mid.style.left     = "#{n - 9}px"
            arrow_inner.style.left   = "#{n - 8}px"

        if arrow_pos_at_bottom == true
            arrow_outer.setAttribute("id", "pop_arrow_up_outer")
            arrow_mid.setAttribute("id", "pop_arrow_up_mid")
            arrow_inner.setAttribute("id", "pop_arrow_up_inner")
            @div_pop.appendChild(arrow_outer)
            @div_pop.appendChild(arrow_mid)
            @div_pop.appendChild(arrow_inner)
        else
            arrow_outer.setAttribute("id", "pop_arrow_down_outer")
            arrow_mid.setAttribute("id", "pop_arrow_down_mid")
            arrow_inner.setAttribute("id", "pop_arrow_down_inner")
            @div_pop.insertBefore(arrow_outer, ele_ul)
            @div_pop.insertBefore(arrow_mid, ele_ul)
            @div_pop.insertBefore(arrow_inner, ele_ul)
        return


    hide_pop_block : =>
        if @div_pop?
            @sub_items = {}
            @div_pop.parentElement?.removeChild(@div_pop)
            delete @div_pop
            @div_pop = null
        @show_pop = false

        @display_selected()
        
        @item_focus()
        
        #@display_focus()
        #@display_full_name()
        return


    build_block_item_menu : =>
        menu = []
        menu.push([1, _("_Open")])
        menu.push([])
        menu.push([3, _("Cu_t")])
        menu.push([4, _("_Copy")])
        menu.push([])
        menu.push([6, _("_Delete")])
        menu.push([])
        menu.push([8, _("_Properties")])
        menu


    block_do_itemselected : (evt, self) ->
        switch evt.id
            when 1
                w = Widget.look_up(self.parentElement.id)
                if w? then e = w.sub_items[self.id]
                if e?
                    if !DCore.DEntry.launch(e, [])
                        if confirm(_("The link has expired. Do you want to delete it?"), _("Warning"))
                            list = []
                            list.push(e)
                            DCore.DEntry.trash(list)
                if w? then w.hide_pop_block()
            when 3
                list = []
                w = Widget.look_up(self.parentElement.id)
                if w? then e = w.sub_items[self.id]
                if e?
                    list.push(e)
                    DCore.DEntry.clipboard_cut(list)
                if w? then w.hide_pop_block()
            when 4
                list = []
                w = Widget.look_up(self.parentElement.id)
                if w? then e = w.sub_items[self.id]
                if e?
                    list.push(e)
                    DCore.DEntry.clipboard_copy(list)
                if w? then w.hide_pop_block()
            when 6
                list = []
                w = Widget.look_up(self.parentElement.id)
                if w? then e = w.sub_items[self.id]
                if e?
                    list.push(e)
                    DCore.DEntry.trash(list)
            when 8
                list = []
                w = Widget.look_up(self.parentElement.id)
                if w? then e = w.sub_items[self.id]
                show_entries_properties([e]) if e?
            else echo "menu clicked:id=#{env.id} title=#{env.title}"
        return


class Application extends DesktopEntry
    constructor : ->
        super
        @show_launcher_box = null
        @animate_background = null


    set_icon : (src = null) =>
        if src == null
            if (icon = DCore.DEntry.get_icon(@_entry)) == null
                icon = DCore.get_theme_icon("invalid_app", D_ICON_SIZE_NORMAL)
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
            if confirm(_("The link has expired. Do you want to delete it?"), _("Warning"))
                list = []
                list.push(@_entry)
                DCore.DEntry.trash(list)


class NormalFile extends DesktopEntry


class InvalidLink extends DesktopEntry
    set_icon : (src = null) =>
        if src == null
            icon = DCore.get_theme_icon("invalid-link", D_ICON_SIZE_NORMAL)
        else
            icon = src
        super(icon)


    do_buildmenu : ->
        [
            [9, _("_Delete")]
        ]


    item_exec : =>
        return


    item_update : =>
        @set_icon()
        @item_name.innerText = @get_name()


    item_rename : =>
        return


class DesktopApplet extends Item


class ComputerVDir extends DesktopEntry
    constructor : ->
        entry = DCore.Desktop.get_computer_entry()
        super(entry, false, false)

    set_id : =>
        @id = _ITEM_ID_COMPUTER_


    get_name : =>
        _("Computer")


    set_icon : (src = null) =>
        if src == null
            icon = DCore.get_theme_icon(_ICON_ID_COMPUTER_, D_ICON_SIZE_NORMAL)
        else
            icon = src
        super(icon)


    # get_path : =>
    #     ""


    do_buildmenu : ->
        [
            [1, _("_Open")],
            [],
            [2, _("_Properties")]
        ]


    do_itemselected : (evt) ->
        switch evt.id
            when 1
                @item_exec()
            when 2
                DCore.Desktop.run_deepin_settings("system_information")
            else
                echo "computer unkown command id:#{evt.id} title:#{evt.title}"
        return


    item_rename : =>
        return


class HomeVDir extends DesktopEntry
    constructor : ->
        entry = DCore.Desktop.get_home_entry()
        super(entry, false, false)


    set_id : =>
        @id = _ITEM_ID_USER_HOME_


    get_name : =>
        _("Home")


    set_icon : (src = null) =>
        if src == null
            icon = DCore.get_theme_icon(_ICON_ID_USER_HOME_, D_ICON_SIZE_NORMAL)
        else
            icon = src
        super(icon)


    get_path : =>
        ""


    do_drop : (evt) ->
        super
        if _IS_DND_INTERLNAL_(evt) and @selected
        else
            tmp_list = []
            for file in evt.dataTransfer.files
                e = DCore.DEntry.create_by_path(decodeURI(file.path).replace(/^file:\/\//i, ""))
                if not e? then continue
                tmp_list.push(e)
            if tmp_list.length > 0 then DCore.DEntry.move(tmp_list, @_entry, true)
        return


    do_dragenter : (evt) ->
        super
        if _IS_DND_INTERLNAL_(evt) and @selected
        else
            evt.dataTransfer.dropEffect = "move"
        return


    do_dragover : (evt) ->
        super
        if _IS_DND_INTERLNAL_(evt) and @selected
        else
            evt.dataTransfer.dropEffect = "move"
        return


    do_dragleave : (evt) ->
        super
        if _IS_DND_INTERLNAL_(evt) and @selected
        else
            evt.preventDefault()
            evt.dataTransfer.dropEffect = "move"
        return


    do_buildmenu : ->
        [
            [1, _("_Open")],
            [],
            [2, _("_Properties")]
        ]


    do_itemselected : (evt) ->
        switch evt.id
            when 1
                @item_exec()
            when 2
                show_entries_properties([@_entry])
            else
                echo "computer unkown command id:#{evt.id} title:#{evt.title}"
        return


    item_rename : =>
        return


class TrashVDir extends DesktopEntry
    constructor : ->
        entry = DCore.DEntry.get_trash_entry()
        super(entry, false, false)

    # XXX: try to avoid that get empty state when system startup
    setTimeout(@item_update, 400) if DCore.DEntry.get_trash_count() == 0


    set_id : =>
        @id = _ITEM_ID_TRASH_BIN_


    get_name : =>
        _("Trash")


    set_icon : (src = null) =>
        if src == null
            if DCore.DEntry.get_trash_count() > 0
                icon = DCore.get_theme_icon(_ICON_ID_TRASH_BIN_FULL_, D_ICON_SIZE_NORMAL)
            else
                icon = DCore.get_theme_icon(_ICON_ID_TRASH_BIN_, D_ICON_SIZE_NORMAL)
        else
            icon = src
        super(icon)


    get_path : =>
        ""


    do_drop : (evt) ->
        super
        if _IS_DND_INTERLNAL_(evt) and @selected
        else
            tmp_list = []
            for file in evt.dataTransfer.files
                e = DCore.DEntry.create_by_path(decodeURI(file.path).replace(/^file:\/\//i, ""))
                if not e? then continue
                tmp_list.push(e)

            if tmp_list.length > 0 then DCore.DEntry.trash(tmp_list)
        return


    do_dragenter : (evt) ->
        super
        if _IS_DND_INTERLNAL_(evt) and @selected
        else
            evt.dataTransfer.dropEffect = "move"
        return


    do_dragover : (evt) ->
        super
        if _IS_DND_INTERLNAL_(evt) and @selected
        else
            evt.dataTransfer.dropEffect = "move"
        return


    do_dragleave : (evt) ->
        super
        if _IS_DND_INTERLNAL_(evt) and @selected
        else
            evt.preventDefault()
            evt.dataTransfer.dropEffect = "move"
        return


    do_buildmenu : ->
        menus = []
        menus.push([1, _("_Open")])
        menus.push([])
        count = DCore.DEntry.get_trash_count()
        if count > 1
            menus.push([3, _("_Clean up %1 items").args(count)])
        else if count == 1
            menus.push([3, _("_Clean up 1 item")])
        else
            menus.push([3, _("_Clean up"), false])
        menus


    do_itemselected : (evt) ->
        switch evt.id
            when 1
                @item_exec()
            when 3
                DCore.DEntry.confirm_trash()
            else
                echo "computer unkown command id:#{evt.id} title:#{evt.title}"
        return


    item_rename : =>
        return


class DeepinSoftwareCenter extends DesktopEntry
    constructor : ->
        super(null, false, false)


    set_id : =>
        @id = _ITEM_ID_DSC_


    get_name : =>
        _("Software Center")


    set_icon : (src = null) =>
        if src == null
            icon = DCore.get_theme_icon(_ICON_ID_DSC_, D_ICON_SIZE_NORMAL)
        else
            icon = src
        super(icon)


    get_path : =>
        ""


    do_buildmenu : ->
        menus = [[1, _("_Open")]]


    item_rename : =>
        return


    item_exec : =>
        DCore.Desktop.run_deepin_software_center()
