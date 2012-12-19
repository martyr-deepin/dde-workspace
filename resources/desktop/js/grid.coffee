#Copyright (c) 2011 ~ 2012 Deepin, Inc.
#              2011 ~ 2012 snyh
#
#Author:      snyh <snyh@snyh.org>
#             Cole <phcourage@gmail.com>
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

# workarea size
s_width = 0
s_height = 0

# workarea offset
s_offset_x = 0
s_offset_y = 0

# item size
i_width = 80 + 6 * 2
i_height = 84 + 4 * 2

#grid block size for items
grid_item_width = 0
grid_item_height = 0

# gird size
cols = 0
rows = 0

# grid html element
div_grid = null

o_table = null

# all items on desktop
all_item = new Array
# all selected items on desktop
selected_item = new Array

# the last widget which been operated last time
last_widget = ""

# store the buffer canvas
drag_canvas = null
# store the image element to set to the drag image
drag_image = null
# store the left top point of drag image start point
drag_start = {x : 0, y: 0}

# store the area selection box for grid
sel = null

# DBus handler for invoke nautilus filemanager
s_nautilus = DCore.DBus.session("org.freedesktop.FileManager1")

gm = build_menu([
    [_("arrange icons"), [
            [31, _("by name")],
            [32, _("by last modified time")]
        ]
    ],
    [_("New"), [
            [41, _("folder")],
            [42, _("text file")]
        ]
    ],
    [3, _("open terminal here")],
    [4, _("paste")],
    [5, _("Personal")],
    [6, _("Display Settings")]
])

# calc the best row and col number for desktop
calc_row_and_cols = (wa_width, wa_height) ->
    n_cols = Math.floor(wa_width / i_width)
    n_rows = Math.floor(wa_height / i_height)
    xx = wa_width % i_width
    yy = wa_height % i_height
    gi_width = i_width + Math.floor(xx / n_cols)
    gi_height = i_height + Math.floor(yy / n_rows)

    return [n_cols, n_rows, gi_width, gi_height]


# update the coordinate of the gird_div to fit the size of the workarea
update_gird_position = (wa_x, wa_y, wa_width, wa_height) ->
    s_offset_x = wa_x
    s_offset_y = wa_y
    s_width = wa_width
    s_height = wa_height

    div_grid.style.left = s_offset_x
    div_grid.style.top = s_offset_y
    div_grid.style.width = s_width
    div_grid.style.height = s_height

    [cols, rows, grid_item_width, grid_item_height] = calc_row_and_cols(s_width, s_height)

    o_table = new Array()
    for i in [0..cols]
        o_table[i] = new Array(rows)

    for i in all_item
        w = Widget.look_up(i)
        if w? then move_to_anywhere(w)


load_position = (item) ->
    pos = localStorage.getObject(item)
    if pos == null then return null

    if cols > 0 and pos.x + pos.width - 1 >= cols then pos.x = cols - pos.width
    if cols > 0 and pos.y + pos.height - 1 >= rows then pos.y = rows - pos.height
    pos


save_position = (item, pos) ->
    localStorage.setObject(item, pos)


update_position = (old_path, new_path) ->
    o_p = load_position(old_path)
    localStorage.removeItem(old_path)
    localStorage.setObject(new_path, o_p)
    return


discard_position = (path) ->
    localStorage.removeItem(path)
    return


compare_pos_top_left = (base, pos) ->
    if pos.y < base.y
        -1
    else if pos.y >= base.y and pos.y <= base.y + base.height - 1
        if pos.x < base.x
            -1
        else if pos.x >= base.x and pos.x <= base.x + base.width - 1
            0
        else
            1
    else
        1


compare_pos_rect = (base1, base2, pos) ->
    top_left = Math.min(base1.x, base2.x)
    top_right = Math.max(base1.x, base2.x)
    bottom_left = Math.min(base1.y, base2.y)
    bottom_right = Math.max(base1.y, base2.y)
    if top_left <= pos.x <= top_right and bottom_left <= pos.y <= bottom_right
        true
    else
        false


clear_occupy = (info) ->
    for i in [0..info.width - 1] by 1
        for j in [0..info.height - 1] by 1
            o_table[info.x+i][info.y+j] = null


set_occupy = (info) ->
    assert(info!=null, "set_occupy")
    for i in [0..info.width - 1] by 1
        for j in [0..info.height - 1] by 1
            o_table[info.x+i][info.y+j] = true
    #draw_grid()


detect_occupy = (info) ->
    assert(info!=null, "detect_occupy")
    for i in [0..info.width - 1] by 1
        for j in [0..info.height - 1] by 1
            if o_table[info.x+i][info.y+j]
                return true
    return false


pixel_to_coord = (x, y) ->
    index_x = Math.min(Math.floor(x / grid_item_width), (cols - 1))
    index_y = Math.min(Math.floor(y / grid_item_height), (rows - 1))
    #echo "#{index_x},#{index_y}"
    return [index_x, index_y]


coord_to_pos = (coord, size) ->
    {x : coord[0], y : coord[1], width : size[0], height : size[1]}


find_free_position = (w, h) ->
    info = {x:0, y:0, width:w, height:h}
    for i in [0..cols - 1]
        for j in [0..rows - 1]
            if not o_table[i][j]?
                info.x = i
                info.y = j
                return info
    return null


move_to_anywhere = (widget) ->
    info = load_position(widget.path)
    if info? and not detect_occupy(info)
        move_to_position(widget, info)
    else
        info = find_free_position(1, 1)
        move_to_position(widget, info)

    #echo "#{widget.name} move to #{info.x},#{info.y}"
    return


move_to_somewhere = (widget, pos) ->
    if not detect_occupy(pos)
        move_to_position(widget, pos)
    else
        old_pos = load_position(widget.path)
        if not old_pos?
            pos = find_free_position(1, 1)
            move_to_position(widget, pos)

    return


move_to_position = (widget, info) ->
    old_info = load_position(widget.path)

    if not info? then return

    save_position(widget.path, info)

    widget.move(info.x * grid_item_width, info.y * grid_item_height)

    if old_info? then clear_occupy(old_info)
    set_occupy(info)

    return


sort_desktop_item_by_name = ->
    item_ordered_list = all_item.concat()
    item_ordered_list.sort()

    for i in [0 ... cols]
        for j in [0 .. rows]
            o_table[i][j] = null

    for i in item_ordered_list
        w = Widget.look_up(i)
        if w?
            discard_position(w.id)
            move_to_anywhere(w)
    return


#TODO: sort_desktop_item_by_last_modified_time


init_grid_drop = ->
    div_grid.addEventListener("drop", (evt) =>
        evt.preventDefault()
        evt.stopPropagation()
        for file in evt.dataTransfer.files
            pos = coord_to_pos(pixel_to_coord(evt.clientX, evt.clientY), [1, 1])

            path = DCore.Desktop.move_to_desktop(file.path)
            if path.length > 1
                save_position(path, pos)
        return
    )
    div_grid.addEventListener("dragover", (evt) =>
        evt.preventDefault()
        evt.stopPropagation()
        evt.dataTransfer.dropEffect = "move"
        return
    )
    div_grid.addEventListener("dragenter", (evt) =>
        evt.stopPropagation()
        evt.dataTransfer.dropEffect = "move"
        return
    )
    div_grid.addEventListener("dragleave", (evt) =>
        evt.stopPropagation()
        #evt.dataTransfer.dropEffect = "move"
        #echo("grid dragleave #{evt.dataTransfer.dropEffect}")
        return
    )


sort_list_by_pos_top_left = (i1, i2) ->
    pos_1 = load_position(i1)
    pos_2 = load_position(i2)
    return compare_pos_top_left(pos_1, pos_2)


drag_update_selected_pos = (w, evt) ->
    old_pos = load_position(w.id)
    new_pos = coord_to_pos(pixel_to_coord(evt.x, evt.y), [1, 1])
    coord_x_shift = new_pos.x - old_pos.x
    coord_y_shift = new_pos.y - old_pos.y

    if coord_x_shift == 0 and coord_y_shift == 0 then return

    ordered_list = selected_item.concat()
    ordered_list.sort(sort_list_by_pos_top_left)
    if coord_x_shift < 0 or coord_y_shift < 0 then ordered_list.reverse()

    for i in ordered_list
        w = Widget.look_up(i)
        if not w? then continue

        old_pos = load_position(w.id)
        new_pos = coord_to_pos([old_pos.x + coord_x_shift, old_pos.y + coord_y_shift], [1, 1])

        if new_pos.x < 0 or new_pos.y < 0 or new_pos.x >= cols or new_pos.y >= rows then continue

        move_to_somewhere(w, new_pos)

    update_selected_item_drag_image()
    return


#TODO: copy selected items to clipboard
selected_copy_to_clipboard = ->
    tmp_list = []
    tmp_list.push i for i in selected_item
    #DCore.Desktop.copy_selected_to_clipboard(tmp_list)
    alert("copy #{tmp_list.length} file(s) to clipboard")


#TODO: cut selected items to clipboard
selected_cut_to_clipboard = ->
    tmp_list = []
    tmp_list.push i for i in selected_item
    #DCore.Desktop.cut_selected_to_clipboard(tmp_list)
    alert("cut #{tmp_list.length} file(s) to clipboard")


#TODO: paste file from clipborad to folder
paste_from_clipboard = ->
    #DCore.Desktop.paste_from_clipboard()
    alert("paste file(s) from clipboard")


item_dragstart_handler = (widget, evt) ->
    if selected_item.length > 0
        all_selected_items = selected_item[0]
        all_selected_items += "\n" + selected_item[i] for i in [1 ... selected_item.length] by 1
        evt.dataTransfer.setData("text/deepin_id_list", all_selected_items)
        evt.dataTransfer.effectAllowed = "moveCopy"

    x = evt.x - drag_start.x * i_width
    y = evt.y - drag_start.y * i_height
    echo "setDragImage #{drag_start.x},#{drag_start.y}"
    evt.dataTransfer.setDragImage(drag_image, x, y)


set_item_selected = (w, top = false) ->
    if w.selected == false
        w.item_selected()
        if top == true
            selected_item.unshift(w.id)
        else
            selected_item.push(w.id)

        if last_widget != w.id
            if last_widget then Widget.look_up(last_widget)?.item_blur()
            last_widget = w.id
            w.item_focus()

    return


cancel_item_selected = (w) ->
    ret = false
    i = selected_item.indexOf(w.id)
    if i >= 0
        selected_item.splice(i, 1)
        w.item_normal()
        ret = true

        if last_widget == w.id
            w.item_blur()
            last_widget = ""

    return ret


cancel_all_selected_stats = (clear_last = true) ->
    Widget.look_up(i)?.item_normal() for i in selected_item
    selected_item.splice(0)

    if clear_last and last_widget
        Widget.look_up(last_widget)?.item_blur()
        last_widget = ""

    return


update_selected_stats = (w, evt) ->
    if evt.ctrlKey
        if evt.type == "mousedown" or evt.type == "contextmenu"
            if w.selected == true then cancel_item_selected(w)
            else set_item_selected(w)

    else if evt.shiftKey
        if evt.type == "mousedown" or evt.type == "contextmenu"
            if selected_item.length > 1
                last_one_id = selected_item[selected_item.length - 1]
                selected_item.splice(selected_item.length - 1, 1)
                cancel_all_selected_stats(false)
                selected_item.push(last_one_id)

            if selected_item.length == 1
                end_pos = coord_to_pos(pixel_to_coord(evt.clientX, evt.clientY), [1, 1])
                start_pos = load_position(Widget.look_up(selected_item[0]).path)

                ret = compare_pos_top_left(start_pos, end_pos)
                if ret < 0
                    for key in all_item
                        val = Widget.look_up(key)
                        i_pos = load_position(val.path)
                        if compare_pos_top_left(end_pos, i_pos) >= 0 and compare_pos_top_left(start_pos, i_pos) < 0
                            set_item_selected(val, true)
                else if ret == 0
                    cancel_item_selected(selected_item[0])
                else
                    for key in all_item
                        val = Widget.look_up(key)
                        i_pos = load_position(val.path)
                        if compare_pos_top_left(start_pos, i_pos) > 0 and compare_pos_top_left(end_pos, i_pos) <= 0
                            set_item_selected(val, true)

            else
                set_item_selected(w)

    else
        n = selected_item.indexOf(w.id)

        if evt.type == "mousedown" or evt.type == "contextmenu"
            if n < 0
                cancel_all_selected_stats(false)
                set_item_selected(w)

        else if evt.type == "click"
            if n >= 0
                selected_item.splice(n, 1)
                cancel_all_selected_stats(false)
                selected_item.push(w.id)
                last_widget = w.id

    update_selected_item_drag_image()
    return


update_selected_item_drag_image = ->
    drag_draw_delay_timer = -1

    if selected_item.length == 0 then return

    pos = load_position(selected_item[0])
    top_left = {x : (cols - 1), y : (rows - 1)}
    bottom_right = {x : 0, y : 0}

    for i in selected_item
        pos = load_position(i)
        if top_left.x > pos.x then top_left.x = pos.x
        if bottom_right.x < pos.x then bottom_right.x = pos.x

        if top_left.y > pos.y then top_left.y = pos.y
        if bottom_right.y < pos.y then bottom_right.y = pos.y

    if top_left.x > bottom_right.x then top_left.x = bottom_right.x
    if top_left.y > bottom_right.y then top_left.y = bottom_right.y

    #if drag_canvas? then delete drag_canvas
    #drag_canvas = document.createElement("canvas")
    drag_canvas.width = (bottom_right.x - top_left.x + 1) * i_width
    drag_canvas.height = (bottom_right.y - top_left.y + 1) * i_height
    #drag_canvas.width = s_width
    #drag_canvas.height = s_height

    context = drag_canvas.getContext('2d')

    for i in selected_item
        w = Widget.look_up(i)
        if not w? then continue

        pos = load_position(i)
        pos.x -= top_left.x
        pos.y -= top_left.y

        start_x = pos.x * i_width
        start_y = pos.y * i_height

        # draw icon
        context.shadowColor = "rgba(0, 0, 0, 0)"
        context.drawImage(w.item_icon, start_x + 22, start_y)
        # draw text
        context.shadowOffsetX = 1
        context.shadowOffsetY = 1
        context.shadowColor = "rgba(0, 0, 0, 1.0)"
        context.shadowBlur = 1.5
        context.font = "bold small san-serif"
        context.fillStyle = "rgba(255, 255, 255, 1.0)"
        context.textAlign = "center"
        rest_text = w.element.innerText
        line_number = 0
        while rest_text.length > 0
            if rest_text.length < 10 then n = rest_text.length
            else n = 10
            m = context.measureText(rest_text.substr(0, n)).width
            if m == 90
                pass
            else if m > 90
                --n
                while n > 0 and context.measureText(rest_text.substr(0, n)).width > 90
                    --n
            else
                ++n
                while n <= rest_text.length and context.measureText(rest_text.substr(0, n)).width < 90
                    ++n

            line_text = rest_text.substr(0, n)
            rest_text = rest_text.substr(n)

            context.fillText(line_text, start_x + 46, start_y + 64 + line_number * 14, 90)
            ++line_number


    drag_image.src = drag_canvas.toDataURL()
    [drag_start.x, drag_start.y] = [top_left.x , top_left.y]


open_selected_items = ->
    Widget.look_up(i)?.item_exec() for i in selected_item


delete_selected_items = ->
    tmp = []
    tmp.push(i) for i in selected_item
    DCore.Desktop.item_delete(tmp)


show_selected_items_Properties = ->
    tmp = []
    tmp.push("file://#{i}") for i in selected_item
    s_nautilus.ShowItemProperties_sync(tmp, '')


gird_left_mousedown = (evt) ->
    if evt.ctrlKey == false and evt.shiftKey == false
        cancel_all_selected_stats()
        update_selected_item_drag_image()


grid_right_click = (evt) ->
    if evt.ctrlKey == false and evt.shiftKey == false
        cancel_all_selected_stats()
        update_selected_item_drag_image()


grid_do_itemselected = (evt) ->
    switch evt.id
        when 31 then sort_desktop_item_by_name()
        when 3 then DCore.Desktop.run_terminal()
        when 4 then paste_from_clipboard()
        when 5 then DCore.Desktop.run_deepin_settings("individuation")
        when 6 then DCore.Desktop.run_deepin_settings("display")
        else echo "not implemented function #{evt.id},#{evt.title}"


#TODO: create new folder and text file


create_item_grid = ->
    div_grid = document.createElement("div")
    div_grid.setAttribute("id", "item_grid")
    document.body.appendChild(div_grid)
    update_gird_position(s_offset_x, s_offset_y, s_width, s_height)
    init_grid_drop()
    div_grid.parentElement.addEventListener("mousedown", gird_left_mousedown)
    div_grid.parentElement.addEventListener("contextmenu", grid_right_click)
    div_grid.parentElement.addEventListener("itemselected", grid_do_itemselected)
    div_grid.parentElement.contextMenu = gm
    sel = new Mouse_Select_Area_box(div_grid.parentElement)

    drag_canvas = document.createElement("canvas")
    drag_image = document.createElement("img")
#FIXME: test propose only, should disable on public release
    #document.body.appendChild(drag_image)


class ItemGrid
    constructor : (parentElement) ->
        @_parent_element = parentElement
        @_workarea_width = 0
        @_workarea_height = 0
        @_offset_x = 0
        @_offset_y = 0


class Mouse_Select_Area_box
    constructor : (parentElement) ->
        @parent_element = parentElement
        @element = document.createElement("div")
        @element.setAttribute("id", "mouse_select_area_box")
        @element.style.border = "1px solid #eee"
        @element.style.backgroundColor = "rgba(167,167,167,0.5)"
        @element.style.zIndex = "30"
        @element.style.position = "absolute"
        @element.style.visibility = "hidden"
        @parent_element.appendChild(@element)
        @parent_element.addEventListener("mousedown", @mousedown_event)
        @last_effect_item = new Array


    mousedown_event : (evt) =>
        evt.preventDefault()
        if evt.button == 0
            @parent_element.addEventListener("mousemove", @mousemove_event)
            @parent_element.addEventListener("mouseup", @mouseup_event)
            @start_point = evt
            @start_pos = coord_to_pos(pixel_to_coord(evt.clientX - s_offset_x, evt.clientY - s_offset_y), [1, 1])
            @last_pos = @start_pos
        return


    mousemove_event : (evt) =>
        evt.preventDefault()
        sl = Math.min(Math.max(Math.min(@start_point.clientX, evt.clientX), s_offset_x), s_offset_x + s_width)
        st = Math.min(Math.max(Math.min(@start_point.clientY, evt.clientY), s_offset_y), s_offset_y + s_height)
        sw = Math.min(Math.abs(evt.clientX - @start_point.clientX), s_width - sl)
        sh = Math.min(Math.abs(evt.clientY - @start_point.clientY), s_height - st)
        @element.style.left = "#{sl}px"
        @element.style.top = "#{st}px"
        @element.style.width = "#{sw}px"
        @element.style.height = "#{sh}px"
        @element.style.visibility = "visible"

        new_pos = coord_to_pos(pixel_to_coord(evt.clientX - s_offset_x, evt.clientY - s_offset_y), [1, 1])
        if compare_pos_top_left(@last_pos, new_pos) != 0
            if compare_pos_top_left(@start_pos, new_pos) < 0
                pos_a = new_pos
                pos_b = @start_pos
            else
                pos_a = @start_pos
                pos_b = new_pos

            effect_item = new Array
            for i in all_item
                w = Widget.look_up(i)
                if not w? then continue
                item_pos = load_position(w.path)
                if compare_pos_rect(pos_a, pos_b, item_pos) == true
                    effect_item.push(i)

            temp_list = effect_item.concat()
            sel_list = @last_effect_item.concat()
            if temp_list.length > 0 and sel_list.length > 0
                for i in [temp_list.length - 1 ... -1] by -1
                    for n in [sel_list.length - 1 ... -1] by -1
                        if temp_list[i] == sel_list[n]
                            temp_list.splice(i, 1)
                            sel_list.splice(n, 1)
                            break

            # all items in temp_list are new item included
            # all items in sel_list are items excluded

            if evt.ctrlKey == true
                for i in temp_list
                    w = Widget.look_up(i)
                    if not w? then continue
                    else if w.selected == false then set_item_selected(w)
                    else cancel_item_selected(w)
                for i in sel_list
                    w = Widget.look_up(i)
                    if not w? then continue
                    else if w.selected == false then set_item_selected(w)
                    else cancel_item_selected(w)

            else if evt.shiftKey == true
                for i in temp_list
                    w = Widget.look_up(i)
                    if not w? then continue
                    if w.selected == false then set_item_selected(w)

            else
                for i in temp_list
                    w = Widget.look_up(i)
                    if not w? then continue
                    if w.selected == false then set_item_selected(w)
                for i in sel_list
                    w = Widget.look_up(i)
                    if not w? then continue
                    if w.selected == true then cancel_item_selected(w)

            @last_pos = new_pos
            @last_effect_item = effect_item

            if temp_list.length > 0 or sel_list.length > 0 then update_selected_item_drag_image()

        return


    mouseup_event : (evt) =>
        evt.preventDefault()
        @parent_element.removeEventListener("mousemove", @mousemove_event)
        @parent_element.removeEventListener("mouseup", @mouseup_event)
        @element.style.visibility = "hidden"
        @last_effect_item.splice(0)
        return


    destory : =>
        @parent_element.removeChild(@element)
