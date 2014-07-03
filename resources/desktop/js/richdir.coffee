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
    
    arrow_pos_at_bottom = false
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


    on_itemselected : (evt) =>
        id = parseInt(evt)
        switch id
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
        @div_pop.addEventListener("contextmenu",(e)=>
            e.preventDefault()
            e.stopPropagation()
        )
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
                    .showMenu(evt.clientX, evt.clientY)
            )

            ele_ul.appendChild(ele)

        #@drawPanel_old(ele_ul)
        @drawPanel(ele_ul)
        return

    set_div_pop_size_pos :(ele_ul) ->
        echo "set_div_pop_size"
        #-----------------------size-----------------------#
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
        #calc ideal pop div width
        pop_width = col * _ITEM_WIDTH_ + 22
        pop_height = row * _ITEM_HEIGHT_

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
        pop_height = row * _ITEM_HEIGHT_
        
        @div_pop.style.width = pop_width
        @div_pop.style.height = pop_height
        ele_ul.style.height = pop_height
        echo "pop_width:#{pop_width};pop_height:#{pop_height}"

        #-----------------------pos-----------------------#
        if arrow_pos_at_bottom == true
            pop_top = @element.offsetTop - @div_pop.offsetHeight
        else
            pop_top = n + 30#default 14

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
        
        pop_size_pos =
            pop_width:pop_width
            pop_height:pop_height
            #pop_height:ele_ul.offsetHeight
            pop_top:pop_top
            pop_left:pop_left
        return pop_size_pos

    drawPanel_old:(ele_ul) ->
        @div_pop.appendChild(ele_ul)
        size = @set_div_pop_size_pos(ele_ul)
        
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
        
        #---------3.choose method for arrow----------#
        #---------method 1: use arrow_img----------#
        #---------method 2: use arrow outer mid inner and borderWidth----------#
        #---------method 3: use canvas----------#
        method = 3
        switch method
            when 1
                @arrow_img = create_img("arrow_img","",@div_pop)
                w = 26
                h = 18
                @arrow_img.style.width = w
                @arrow_img.style.height = h
                if is_right then @arrow_img.style.right = left
                else @arrow_img.style.left = left
                if arrow_pos_at_bottom
                    @div_pop.style.top = size.pop_top - 5
                    @arrow_img.src = "img/arrow_bottom.png"
                    @arrow_img.style.bottom = -1 * h
                else
                    @div_pop.style.top = size.pop_top + 5
                    @arrow_img.src = "img/arrow_top.png"
                    @arrow_img.style.top = -1 * h
            when 2
                arrow_outer = document.createElement("div")
                arrow_mid = document.createElement("div")
                arrow_inner = document.createElement("div")
                if is_right
                    arrow_outer.style.right = "#{left}px"
                    arrow_mid.style.right = "#{left}px"
                    arrow_inner.style.right = "#{left + 1}px"
                else
                    arrow_outer.style.left = "#{left}px"
                    arrow_mid.style.left = "#{left}px"
                    arrow_inner.style.left = "#{left + 1}px"
       
                if arrow_pos_at_bottom == true
                    arrow_outer.setAttribute("id", "pop_arrow_up_outer")
                    arrow_mid.setAttribute("id", "pop_arrow_up_mid")
                    arrow_inner.setAttribute("id", "pop_arrow_up_inner")
                    
                    arrow_outer.style.bottom = arrow_outer_y
                    arrow_mid.style.bottom = arrow_outer_y + 1
                    arrow_inner.style.bottom = arrow_outer_y + 2
                    
                    # top right bottom left
                    arrow_outer.style.borderWidth = "#{border_y}px #{border_x}px 0px #{border_x}px"
                    arrow_mid.style.borderWidth = "#{border_y}px #{border_x}px 0px #{border_x}px"
                    arrow_inner.style.borderWidth = "#{border_y - 1}px #{border_x - 1}px 0px #{border_x - 1}px"
                    
                    @div_pop.appendChild(arrow_outer)
                    @div_pop.appendChild(arrow_mid)
                    @div_pop.appendChild(arrow_inner)
                else
                    arrow_outer.setAttribute("id", "pop_arrow_down_outer")
                    arrow_mid.setAttribute("id", "pop_arrow_down_mid")
                    arrow_inner.setAttribute("id", "pop_arrow_down_inner")
                    arrow_outer.style.top = arrow_outer_y
                    arrow_mid.style.top = arrow_outer_y + 1
                    arrow_inner.style.top = arrow_outer_y + 2
                    
                    # top right down left
                    arrow_outer.style.borderWidth = "0px #{border_x}px #{border_y}px #{border_x}px"
                    arrow_mid.style.borderWidth = "0px #{border_x}px #{border_y}px #{border_x}px"
                    arrow_inner.style.borderWidth = "0px #{border_x - 1}px #{border_y - 1}px #{border_x - 1}px"
                    
                    @div_pop.insertBefore(arrow_outer, ele_ul)
                    @div_pop.insertBefore(arrow_mid, ele_ul)
                    @div_pop.insertBefore(arrow_inner, ele_ul)
            when 3
                echo "canvas richdir arrow"
        
        drawTriangle: (x,y,parent) ->
            PREVIEW_CONTAINER_BORDER_WIDTH = 2
            PREVIEW_SHADOW_BLUR = 6
            PREVIEW_CORNER_RADIUS = 4
            PREVIEW_TRIANGLE =
                width: 18
                height: 10
            @bg = create_element(tag:'canvas', class:"bg", parent)
            @bg.style.position = "absolute"
            
            ctx = @bg.getContext('2d')
            ctx = @bg.getContext('2d')

            if is_right then @bg.style.right = left
            else @bg.style.left = left
            if !arrow_pos_at_bottom then ctx.rotate(Math.PI)
            
            ctx.clearRect(0, 0, @bg.width, @bg.height)
            ctx.save()

            ctx.shadowBlur = PREVIEW_SHADOW_BLUR
            ctx.shadowColor = 'black'
            ctx.shadowOffsetY = PREVIEW_CONTAINER_BORDER_WIDTH

            ctx.strokeStyle = 'rgba(255,255,255,0.4)'
            ctx.lineWidth = PREVIEW_CONTAINER_BORDER_WIDTH

            ctx.fillStyle = "rgba(0,0,0,0.75)"
    
            radius = PREVIEW_CORNER_RADIUS
            contentWidth = @bg.width + radius * 2 + ctx.lineWidth * 2 + ctx.shadowBlur * 2
            topY = radius + ctx.lineWidth
            bottomY = @bg.height - PREVIEW_TRIANGLE.height - ctx.lineWidth * 2 - ctx.shadowBlur
            leftX = radius + ctx.shadowBlur
            rightX = leftX + contentWidth
            
            # bottom line
            halfWidth = leftX + contentWidth / 2
            triOffset = 0
            triX = size.pop_left + size.pop_width / 2
            if triX < halfWidth
                console.log("left overflow")
                triOffset = triX - halfWidth
            else if halfWidth + triX > screen.width
                console.log("right overflow")
                triOffset = (halfWidth + triX) - screen.width

            ctx.beginPath()
            ctx.moveTo(ctx.shadowBlur, topY)
            # triangle
            ctx.lineTo(halfWidth + triOffset,
                       bottomY + radius + PREVIEW_TRIANGLE.height)

            ctx.lineTo(halfWidth + triOffset - PREVIEW_TRIANGLE.width / 2,
                       bottomY + radius)

            ctx.stroke()
            ctx.fill()

            #ctx.restore()

            @bg.style.display = "block"

    drawPanel:(ele_ul)->
        
        @bg = create_element(tag:'canvas', class:"bg", @div_pop)
        @bg.style.position = "absolute"
        @bg.style.top = @bg.style.left = 0
        #@bg.style.zIndex = 21000
        ele_ul.style.position = "absolute"
        ele_ul.style.top = ele_ul.style.left = 0
        #ele_ul.style.zIndex = 22000
        @bg.appendChild(ele_ul)
        size = @set_div_pop_size_pos(ele_ul)
        
        PREVIEW_CORNER_RADIUS = 4
        PREVIEW_SHADOW_BLUR = 6
        PREVIEW_CONTAINER_HEIGHT = 160
        PREVIEW_CONTAINER_BORDER_WIDTH = 2
        PREVIEW_BORDER_LENGTH = 5.0
        PREVIEW_WINDOW_WIDTH = size.pop_width
        PREVIEW_WINDOW_HEIGHT = size.pop_height
        PREVIEW_WINDOW_MARGIN = 15
        PREVIEW_WINDOW_BORDER_WIDTH = 1
        PREVIEW_CANVAS_WIDTH = PREVIEW_WINDOW_WIDTH - PREVIEW_WINDOW_BORDER_WIDTH * 2
        PREVIEW_CANVAS_HEIGHT = PREVIEW_WINDOW_HEIGHT - PREVIEW_WINDOW_BORDER_WIDTH * 2
        PREVIEW_TRIANGLE =
            width: 18
            height: 10
       
        @bg.style.width = size.pop_width + PREVIEW_TRIANGLE.width
        @bg.style.height = size.pop_height + PREVIEW_TRIANGLE.height

        triX = size.pop_left + size.pop_width / 2

        ctx = @bg.getContext('2d')
        ctx.clearRect(0, 0, @bg.width, @bg.height)
        ctx.save()

        ctx.shadowBlur = PREVIEW_SHADOW_BLUR
        ctx.shadowColor = 'black'
        ctx.shadowOffsetY = PREVIEW_CONTAINER_BORDER_WIDTH

        ctx.strokeStyle = 'rgba(255,255,255,0.4)'
        ctx.lineWidth = PREVIEW_CONTAINER_BORDER_WIDTH

        ctx.fillStyle = "rgba(0,0,0,0.75)"

        radius = PREVIEW_CORNER_RADIUS
        contentWidth = @bg.width + radius * 2 + ctx.lineWidth * 2 + ctx.shadowBlur * 2
        topY = radius + ctx.lineWidth
        bottomY = @bg.height - PREVIEW_TRIANGLE.height - ctx.lineWidth * 2 - ctx.shadowBlur
        leftX = radius + ctx.shadowBlur
        rightX = leftX + contentWidth

        arch =
            TopLeft:
                ox: leftX
                oy: topY
                radius: radius
                startAngle: Math.PI
                endAngle: Math.PI * 1.5
            TopRight:
                ox: rightX
                oy: topY
                radius: radius
                startAngle: Math.PI * 1.5
                endAngle: Math.PI * 2
            BottomRight:
                ox: rightX
                oy: bottomY
                radius: radius
                startAngle: 0
                endAngle: Math.PI * 0.5
            BottomLeft:
                ox: leftX
                oy: bottomY
                radius: radius
                startAngle: Math.PI * 0.5
                endAngle: Math.PI
        ctx.beginPath()
        ctx.moveTo(ctx.shadowBlur, topY)
        ctx.arc(arch['TopLeft'].ox, arch['TopLeft'].oy, arch['TopLeft'].radius,
                arch['TopLeft'].startAngle, arch['TopLeft'].endAngle)

        ctx.lineTo(rightX, topY - radius)

        ctx.arc(arch['TopRight'].ox, arch['TopRight'].oy, arch['TopRight'].radius,
                arch['TopRight'].startAngle, arch['TopRight'].endAngle)

        ctx.lineTo(rightX + radius, bottomY)

        ctx.arc(arch['BottomRight'].ox, arch['BottomRight'].oy, arch['BottomRight'].radius,
                arch['BottomRight'].startAngle, arch['BottomRight'].endAngle)

        # bottom line
        halfWidth = leftX + contentWidth / 2
        triOffset = 0
        if triX < halfWidth
            console.log("left overflow")
            triOffset = triX - halfWidth
        else if halfWidth + triX > screen.width
            console.log("right overflow")
            triOffset = (halfWidth + triX) - screen.width

        ctx.lineTo(halfWidth + triOffset + PREVIEW_TRIANGLE.width / 2,
                   bottomY + radius)

        # triangle
        ctx.lineTo(halfWidth + triOffset,
                   bottomY + radius + PREVIEW_TRIANGLE.height)

        ctx.lineTo(halfWidth + triOffset - PREVIEW_TRIANGLE.width / 2,
                   bottomY + radius)

        # bottom line
        ctx.lineTo(leftX, bottomY + radius)

        ctx.arc(arch['BottomLeft'].ox, arch['BottomLeft'].oy, arch['BottomLeft'].radius,
                arch['BottomLeft'].startAngle, arch['BottomLeft'].endAngle)

        ctx.lineTo(ctx.shadowBlur, topY)

        if arrow_pos_at_bottom then ctx.rotate(Math.PI)
        ctx.stroke()
        ctx.fill()

        ctx.restore()

        @bg.style.display = "block"

    hide_pop_block : =>
        echo "hide_pop_block"
        return
        @pop_div_item_contextmenu_flag = false
        
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
                echo "6 delete"
                list = []
                w = Widget.look_up(self.parentElement.id)
                echo "w.id" + w.id
                if w? then e = w.sub_items[self.id]
                echo e
                if e?
                    list.push(e)
                    DCore.DEntry.trash(list)
            when 8
                echo "6 properties"
                list = []
                w = Widget.look_up(self.parentElement.id)
                if w? then e = w.sub_items[self.id]
                show_entries_properties([e]) if e?
            else echo "menu clicked:id=#{id}"
        return
