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


# canvas cache for drawing rich dir draging mouse image
richdir_drag_canvas = document.createElement("canvas")
richdir_drag_context = richdir_drag_canvas.getContext('2d')

class RichDir extends DesktopEntry
    COLUMN_MAX = 6
    ROW_SHOW_MAX = 3
    col = 0
    row = 0
    arrow_pos_at_bottom = false
    ele_ul = null
    scroll_flag = false
    constructor : (entry) ->
        super(entry, true, true)
        @div_pop = null
        @show_pop = false
        @pop_div_item_contextmenu_flag = false

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
        echo "do_rightclick"
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


    buildmenu : ->
        menus = []
        menus.push([1, _("_Open")])
        menus.push([])
        menus.push([3, _("_Rename"), not is_selected_multiple_items()])
        menus.push([])
        menus.push([5, _("_Ungroup")])
        menus.push([])
        menus.push([7, _("_Delete")])
        menus


    on_itemselected : (evt) =>
        id = parseInt(evt)
        switch id
            when 1 then @item_exec()
            when 3 then @item_rename()
            when 5 then @item_ungroup()
            when 7 then delete_selected_items(evt.shiftKey)
            else echo "menu clicked:id=#{env.id} title=#{env.title}"
        return


    item_normal : =>
        if @div_pop != null then @hide_pop_block()
        super


    item_blur : =>
        echo "item_blur"
        if @div_pop != null && !@pop_div_item_contextmenu_flag then @hide_pop_block()
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
                @sub_items_ele = []
                @sub_items_seleted_i = -1
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
        @div_pop.setAttribute("tabindex","-1")
        @div_pop.focus()
        @div_pop.addEventListener("mousedown", @on_event_stoppropagation)
        @div_pop.addEventListener("click", @on_event_stoppropagation)
        @div_pop.addEventListener("contextmenu",(e)=>
            e.preventDefault()
            e.stopPropagation()
        )
        @div_pop.addEventListener("keydown", @richdir_do_keydown_to_shortcut)
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

        @sub_items_ele = []
        @sub_items_seleted_i = -1
        sub_items_i = 0
        for id, e of @sub_items
            ele = create_element("li","RichDirItem",ele_ul)
            ele.setAttribute('id', id)
            ele.setAttribute('title', DCore.DEntry.get_name(e))
            ele.draggable = true

            sb = document.createElement("div")
            sb.className = "item_icon"
            ele.appendChild(sb)
            s = document.createElement("img")
            s.style.width = "48px"
            s.style.height = "48px"
            # s.src = DCore.DEntry.get_icon(e)
            if (s.src = DCore.DEntry.get_icon(e)) == null
                s.src = DCore.get_theme_icon("invalid-dock_app", D_ICON_SIZE_NORMAL)
                echo "warning: richdir child get_icon is null:" + s.src
            sb.appendChild(s)
            s = document.createElement("div")
            s.className = "item_name"
            s.innerText = DCore.DEntry.get_name(e)
            ele.appendChild(s)

            that = @
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
            ele.addEventListener('mouseover', (evt) ->
                evt.stopPropagation()
                that.sub_items_selected_css(this.id) if not scroll_flag
                scroll_flag = false
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
                        if confirm(_("The link is invalid. Do you want to delete it?"), _("Warning"))
                            list = []
                            list.push(e)
                            DCore.DEntry.trash(list)
                if w? then w.hide_pop_block()
            )

            ele.addEventListener('contextmenu', (evt) ->
                evt.stopPropagation()
                evt.preventDefault()
                that.pop_div_item_contextmenu_flag = true

                w = Widget.look_up(this.parentElement.id)
                if w? then e = w.sub_items[this.id]
                menu = build_menu(w.build_block_item_menu())
                menu.unregisterHook(->
                    that.hide_pop_block()
                )
                menu.addListener(w.block_do_itemselected.bind(this))
                    .showMenu(evt.screenX, evt.screenY)
            )

            @sub_items_ele.push({id:id,index:sub_items_i,name:ele.title,element:ele,w:e})
            sub_items_i++
        @drawPanel(ele_ul)
        return

    set_div_pop_size_pos :(ele_ul) ->
        echo "set_div_pop_size"
        #-----------------------size-----------------------#
        # how many we can hold per line due to workarea width
        # 20px for ul padding, 2px for border, 8px for scrollbar
        num_max = Math.floor((s_width - 30) / _ITEM_WIDTH_)
        # calc ideal columns --lie
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

        # calc ideal rows --hang
        row  = Math.ceil(@sub_items_count / col)
        if row < 1 then row = 1
        if row > 4 then row = 4
        #calc ideal pop div width
        pop_width = col * _ITEM_WIDTH_ + 22
        pop_height = row * _ITEM_HEIGHT_

        n = @element.offsetTop + Math.min(_ITEM_HEIGHT_, @element.offsetHeight)
        num_max = s_height - n
        canvas_add_height = TRIANGLE.height + (BORDER_WIDTH + SHADOW.blur) * 2
        canvas_height = pop_height + canvas_add_height
        if num_max < canvas_height
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
        pop_height = row * _ITEM_HEIGHT_
        echo "=========@sub_items_count:#{@sub_items_count};row:hang:#{row};col:lie:#{col}"

        @div_pop.style.width = pop_width
        @div_pop.style.height = pop_height
        ele_ul.style.height = pop_height
        echo "pop_width:#{pop_width};pop_height:#{pop_height}"

        #-----------------------pos-----------------------#
        if arrow_pos_at_bottom == true
            pop_top = @element.offsetTop - @div_pop.offsetHeight - 20
        else
            pop_top = n + 35#default 14

        # calc and make the arrow
        n = @div_pop.offsetWidth / 2 + 1
        p = @element.offsetLeft + @element.offsetWidth / 2

        pop_left = s_offset_x
        if p < n
            pop_left = s_offset_x
        else if p + n > s_width
            pop_left = s_width - 2 * n
        else
            pop_left = p - n + 6

        @div_pop.style.top = pop_top
        @div_pop.style.left = pop_left

        offset = pop_left + n - p - 6
        pop_size_pos =
            pop_width:pop_width
            pop_height:ele_ul.offsetHeight
            pop_top:pop_top
            pop_left:pop_left
            pop_offset: offset

        return pop_size_pos

    drawPanel:(ele_ul) =>
        size = @set_div_pop_size_pos(ele_ul)

        @canvas = @canvas || create_element(tag:"canvas", class:"pop_bg", @div_pop)
        @canvas.width = size.pop_width + (SHADOW.blur + BORDER_WIDTH) * 2
        add_height = TRIANGLE.height + (BORDER_WIDTH + SHADOW.blur) * 2
        @canvas.height = size.pop_height + add_height
        if arrow_pos_at_bottom then @canvas.style.top = -10
        else @canvas.style.top = -18
        ctx = @canvas.getContext("2d")
        ctx.save()
        ctx.clearRect(0, 0, @canvas.width, @canvas.height)
        ctx.fillStyle = FILL_STYLE
        ctx.lineWidth = BORDER_WIDTH
        ctx.strokeStyle = STROKE_STYLE
        ctx.shadowColor = SHADOW.color
        ctx.shadowOffsetX = SHADOW.xOffset
        ctx.shadowOffsetY = SHADOW.yOffset
        ctx.shadowBlur = SHADOW.blur

        _this = @
        offset = CORNER_RADIUS + SHADOW.blur + BORDER_WIDTH
        axisX =
            left: offset
            right: _this.canvas.width - offset
        axisY =
            top: offset
            bottom: _this.canvas.height - offset

        if arrow_pos_at_bottom
            axisY.bottom = axisY.bottom - TRIANGLE.height
        else
            axisY.top = axisY.top + TRIANGLE.height

        ctx.moveTo(axisX.left - CORNER_RADIUS, axisY.top)
        ctx.arc(axisX.left, axisY.top, CORNER_RADIUS, Math.PI, Math.PI*1.5)

        if !arrow_pos_at_bottom
            x = @canvas.width/2 - size.pop_offset
            y = axisY.top - CORNER_RADIUS
            ctx.lineTo(x - TRIANGLE.width/2, y)
            ctx.lineTo(x, y - TRIANGLE.height)
            ctx.lineTo(x + TRIANGLE.width/2, y)

        ctx.lineTo(axisX.right, axisY.top - CORNER_RADIUS)

        ctx.arc(axisX.right, axisY.top, CORNER_RADIUS, Math.PI*1.5, Math.PI*2)
        ctx.lineTo(axisX.right + CORNER_RADIUS, axisY.bottom)
        ctx.arc(axisX.right, axisY.bottom, CORNER_RADIUS, 0, Math.PI*.5)
        if arrow_pos_at_bottom
            x = @canvas.width/2 - size.pop_offset
            y = axisY.bottom + CORNER_RADIUS
            ctx.lineTo(x + TRIANGLE.width/2, y)
            ctx.lineTo(x, y + TRIANGLE.height)
            ctx.lineTo(x - TRIANGLE.width/2, y)
        ctx.lineTo(axisX.left, axisY.bottom + CORNER_RADIUS)
        ctx.arc(axisX.left, axisY.bottom, CORNER_RADIUS, Math.PI*.5, Math.PI)
        ctx.lineTo(axisX.left - CORNER_RADIUS, axisY.top)

        ctx.fill()
        ctx.stroke()
        ctx.restore()
        # calc and make the arrow
        n = @div_pop.offsetWidth / 2 + 1
        p = @element.offsetLeft + @element.offsetWidth / 2

        echo "p:#{p};n:#{n};s_width:#{s_width};arrow_pos_at_bottom:#{arrow_pos_at_bottom}"
        SCALE = 1.5
        echo "SCALE:#{SCALE}"

        #---------1.check is left or center or right----------#
        #---------and set style.left or right----------#
        arrow_outer_x = null
        left = null
        is_right = false
        if p < n
            arrow_outer_x = 8 * SCALE
            left = p - arrow_outer_x
        else if p + n > s_width
            arrow_outer_x = 14 * SCALE
            left = s_width - p - arrow_outer_x
            is_right = true
        else
            arrow_outer_x = 9 * SCALE
            left = n - arrow_outer_x

        #---------2.check arrow_pos_at_bottom or at top----------#
        #---------and set style.top or left----------#
        #---------and set style.borderWidth----------#
        arrow_outer_y = -7 * SCALE
        border_y = Math.abs(arrow_outer_y)
        angel = 1.0
        border_x = border_y / angel

        return

    hide_pop_block : =>
        echo "hide_pop_block"
        @pop_div_item_contextmenu_flag = false

        if @div_pop?
            @sub_items = {}
            @sub_items_ele = []
            @sub_items_seleted_i = -1
            @div_pop.parentElement?.removeChild(@div_pop)
            delete @div_pop
            @div_pop = null
            @canvas = null
        @show_pop = false

        @display_selected()

        @item_focus()

        #@display_focus()
        #@display_full_name()
        return


    build_block_item_menu : =>
        menu = []
        menu.unshift(DEEPIN_MENU_TYPE.NORMAL)
        menu.push([1, _("_Open")])
        menu.push([])
        menu.push([3, _("Cu_t")])
        menu.push([4, _("_Copy")])
        menu.push([])
        menu.push([6, _("_Delete")])
        menu.push([])
        menu.push([8, _("_Properties")])
        menu


    block_do_itemselected : (id) ->
        self = this
        id = parseInt(id)
        switch id
            when 1
                w = Widget.look_up(self.parentElement.id)
                if w? then e = w.sub_items[self.id]
                if e?
                    if !DCore.DEntry.launch(e, [])
                        if confirm(_("The link is invalid. Do you want to delete it?"), _("Warning"))
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
                echo "w.id" + w.id
                if w? then e = w.sub_items[self.id]
                echo e
                if e?
                    list.push(e)
                    DCore.DEntry.trash(list)
            when 8
                list = []
                w = Widget.look_up(self.parentElement.id)
                if w? then e = w.sub_items[self.id]
                show_entries_properties([e]) if e?
            else echo "menu clicked:id=#{id}"
        return

    sub_items_launch: (id) =>
        @sub_items_selected_css(id)
        e = @sub_items[id]
        if e?
            if !DCore.DEntry.launch(e, [])
                if confirm(_("The link is invalid. Do you want to delete it?"), _("Warning"))
                    list = []
                    list.push(e)
                    DCore.DEntry.trash(list)
        @hide_pop_block()

    sub_items_selected_css: (id) =>
        for item in @sub_items_ele
            if item.id == id
                @sub_items_seleted_i = item.index
                item.element.setAttribute("class","RichDirItemSlected")
            else
                item.element.setAttribute("class","RichDirItem")

    check_item_index: (i) ->
        if not i? then i = 0
        if i > @sub_items_count - 1 then i = @sub_items_count - 1
        else if i < 0 then i = 0
        i

    richdir_do_keydown_to_shortcut : (evt) =>
        if not @show_pop
            return
        evt.stopPropagation()
        evt.preventDefault()

        delta = 0
        switch evt.keyCode
            when KEYCODE.LEFT_ARROW
                delta = -1
            when KEYCODE.UP_ARROW
                delta = -1 * col
            when KEYCODE.RIGHT_ARROW
                delta = 1
            when KEYCODE.DOWN_ARROW
                delta = col
            when KEYCODE.ENTER
                delta = 0
                @sub_items_seleted_i = @check_item_index(@sub_items_seleted_i)
                id = @sub_items_ele[@sub_items_seleted_i].id
                @sub_items_launch(id)
                return
            when KEYCODE.ESC
                delta = 0
                @hide_pop_block()
                return
        if delta == 0
            return
        id_origin = null
        if @sub_items_seleted_i in [0...@sub_items_count - 1]
            id_origin = @sub_items_ele[@sub_items_seleted_i].id
        else
            id_origin = @sub_items_ele[0].id
        @sub_items_seleted_i = @check_item_index(@sub_items_seleted_i + delta)
        id = @sub_items_ele[@sub_items_seleted_i].id
        @scroll_to_item(id_origin,id)
        @sub_items_selected_css(id)


    scroll_to_item: (id_origin,id) =>
        SHOW_ITEM_MAX = COLUMN_MAX * ROW_SHOW_MAX
        if @sub_items_count <= SHOW_ITEM_MAX
            return
        item_dest = null
        item_origin = null
        if id_origin == null
           id_origin = @sub_items_ele[0].id
        for item in @sub_items_ele
            if item.id == id then item_dest = item
            if item.id == id_origin then item_origin = item
        if not item_dest? or not item_origin?
            return
        console.debug "scroll_to_item:index:#{item_origin.index} to #{item_dest.index}"
        row_origin = Math.floor(item_origin.index / col) + 1#hang
        row_dest = Math.floor(item_dest.index / col) + 1#hang
        offset_top = (row_dest - row_origin) * _ITEM_HEIGHT_
        scroll_flag = true
        setTimeout(->
            ele_ul.scrollTop += offset_top
        ,20)
