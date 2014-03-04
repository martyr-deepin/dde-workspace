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
