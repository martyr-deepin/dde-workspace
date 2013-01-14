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

#grid block size for items
grid_item_width = 0
grid_item_height = 0

# gird size
cols = 0
rows = 0

# grid html element
div_grid = null
# grid occupy table
o_table = null

# all file items on desktop
all_item = new Array
# speical items on desktop
speical_item = new Array
# all selected items on desktop
selected_item = new Array
# the last widget which been operated last time
last_widget = ""

# store the buffer canvas
drag_canvas = null
# store the context of the buffer canvas
drag_context = null
# store the left top point of drag image start point
drag_start = {x : 0, y: 0}

# store the area selection box for grid
sel = null

# we need to ingore keyup event when rename files
ingore_keyup_counts = 0


# calc the best row and col number for desktop
calc_row_and_cols = (wa_width, wa_height) ->
    n_cols = Math.floor(wa_width / _ITEM_WIDTH_)
    n_rows = Math.floor(wa_height / _ITEM_HEIGHT_)
    xx = wa_width % _ITEM_WIDTH_
    yy = wa_height % _ITEM_HEIGHT_
    g_ITEM_WIDTH_ = _ITEM_WIDTH_ + Math.floor(xx / n_cols)
    g_ITEM_HEIGHT_ = _ITEM_HEIGHT_ + Math.floor(yy / n_rows)

    return [n_cols, n_rows, g_ITEM_WIDTH_, g_ITEM_HEIGHT_]


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

    place_desktop_items()


load_position = (id) ->
    if typeof(id) != "string" then echo "error load_position #{id}"
    pos = localStorage.getObject("id:" + id)
    if pos == null then return null

    if cols > 0 and pos.x + pos.width - 1 >= cols then pos.x = cols - pos.width
    if cols > 0 and pos.y + pos.height - 1 >= rows then pos.y = rows - pos.height
    pos


save_position = (id, pos) ->
    localStorage.setObject("id:" + id, pos)
    return


discard_position = (id) ->
    localStorage.removeItem("id:" + id)
    return


update_position = (old_id, new_id) ->
    o_p = load_position(old_id)
    discard_position(old_id)
    save_position(new_id, o_p)
    return


place_desktop_items = ->
    init_occupy_table()

    for i in speical_item
        w = Widget.look_up(i)
        if w? then move_to_anywhere(w)

    for i in all_item
        w = Widget.look_up(i)
        if w? then move_to_anywhere(w)


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


calc_pos_to_pos_distance = (base, pos) ->
    Math.sqrt(Math.pow(Math.abs(base.x - pos.x), 2) + Math.pow(Math.abs(base.y - pos.y), 2))


find_item_by_coord_delta = (start_item, x_delta, y_delta) ->
    items = speical_item.concat(all_item)
    pos = load_position(start_item.id)
    while true
        if x_delta != 0
            pos.x += x_delta
            if x_delta > 0 and pos.x > cols then break
            else if x_delta < 0 and pos.x < 0 then break
        if y_delta != 0
            pos.y += y_delta
            if y_delta > 0 and pos.y > rows then break
            else if y_delta < 0 and pos.y < 0 then break

        if detect_occupy(pos) == false then continue

        for i in items
            w = Widget.look_up(i)
            if not w? then continue
            find_pos = load_position(w.id)
            if (find_pos.x <= pos.x <= find_pos.x + find_pos.width - 1) and (find_pos.y <= pos.y <= find_pos.y + find_pos.height - 1)
                return w
    null


init_occupy_table = ->
    o_table = new Array()
    for i in [0..cols]
        o_table[i] = new Array(rows)


clear_occupy_table = ->
    for i in [0 ... cols]
        for j in [0 ... rows]
            o_table[i][j] = null


clear_occupy = (info) ->
    for i in [0..info.width - 1] by 1
        for j in [0..info.height - 1] by 1
            o_table[info.x+i][info.y+j] = null


set_occupy = (info) ->
    assert(info!=null, "set_occupy")
    for i in [0..info.width - 1] by 1
        for j in [0..info.height - 1] by 1
            o_table[info.x+i][info.y+j] = true


detect_occupy = (info) ->
    assert(info!=null, "detect_occupy")
    for i in [0..info.width - 1] by 1
        for j in [0..info.height - 1] by 1
            if o_table[info.x+i][info.y+j]
                return true
    return false


pixel_to_pos = (x, y, w, h) ->
    index_x = Math.min(Math.floor(x / grid_item_width), (cols - 1))
    index_y = Math.min(Math.floor(y / grid_item_height), (rows - 1))
    coord_to_pos(index_x, index_y, w, h)


coord_to_pos = (pos_x, pos_y, w, h) ->
    {x : pos_x, y : pos_y, width : w, height : h}


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
    info = load_position(widget.id)
    if info? and not detect_occupy(info)
        move_to_position(widget, info)
    else
        info = find_free_position(1, 1)
        move_to_position(widget, info)
    return


move_to_somewhere = (widget, pos) ->
    if not detect_occupy(pos)
        move_to_position(widget, pos)
    else
        old_pos = load_position(widget.id)
        if not old_pos?
            pos = find_free_position(1, 1)
            move_to_position(widget, pos)
    return


move_to_position = (widget, info) ->
    old_info = load_position(widget.id)

    if not info? then return

    save_position(widget.id, info)

    widget.move(info.x * grid_item_width, info.y * grid_item_height)

    if old_info? then clear_occupy(old_info)
    set_occupy(info)

    return


sort_list_by_name_from_id = (id1, id2) ->
    w1 = Widget.look_up(id1)
    w2 = Widget.look_up(id2)
    if not w1? or not w2?
        echo("we get error here[sort_list_by_name_from_id]")
        return w1.localeCompare(w2)
    else
        return w1.get_name().localeCompare(w2.get_name())


sort_list_by_mtime_from_id = (id1, id2) ->
    w1 = Widget.look_up(id1)
    w2 = Widget.look_up(id2)
    if not w1? or not w2?
        echo("we get error here[sort_list_by_name_from_id]")
        return w1.localeCompare(w2)
    else
        return w1.get_mtime() - w2.get_mtime()


sort_desktop_item_by_func = (func) ->
    item_ordered_list = all_item.concat()
    item_ordered_list.sort(func)

    for i in [0 ... cols]
        for j in [0 .. rows]
            o_table[i][j] = null

    for i in speical_item
        w = Widget.look_up(i)
        if w?
            discard_position(w.id)
            move_to_anywhere(w)

    for i in item_ordered_list
        w = Widget.look_up(i)
        if w?
            discard_position(w.id)
            move_to_anywhere(w)
    return


menu_sort_desktop_item_by_name = ->
    sort_desktop_item_by_func(sort_list_by_name_from_id)
    return


menu_sort_desktop_item_by_mtime = ->
    sort_desktop_item_by_func(sort_list_by_mtime_from_id)
    return


create_entry_to_new_item = (entry) ->
    w = Widget.look_up(DCore.DEntry.get_id(entry))
    if not w? then w = create_item(entry)

    cancel_all_selected_stats()
    move_to_anywhere(w)
    all_item.push(w.id)
    set_item_selected(w)
    w.item_rename()


menu_create_new_folder = ->
    entry = DCore.Desktop.new_directory()
    create_entry_to_new_item(entry)


menu_create_new_file = ->
    entry = DCore.Desktop.new_file()
    create_entry_to_new_item(entry)


init_grid_drop = ->
    div_grid.addEventListener("drop", (evt) =>
        evt.preventDefault()
        evt.stopPropagation()
        pos = pixel_to_pos(evt.clientX, evt.clientY, 1, 1)
        for file in evt.dataTransfer.files
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
        return
    )


drag_update_selected_pos = (w, evt) ->
    old_pos = load_position(w.id)
    new_pos = pixel_to_pos(evt.clientX, evt.clientY, 1, 1)
    coord_x_shift = new_pos.x - old_pos.x
    coord_y_shift = new_pos.y - old_pos.y

    if coord_x_shift == 0 and coord_y_shift == 0 then return

    ordered_list = new Array()
    distance_list = new Array()
    for i in selected_item
        pos = load_position(i)
        dis = calc_pos_to_pos_distance(new_pos, pos)
        for j in [0 ... distance_list.length]
            if dis < distance_list[j]
                break
        ordered_list.splice(j, 0, i)
        distance_list.splice(j, 0, dis)

    for i in ordered_list
        w = Widget.look_up(i)
        if not w? then continue

        old_pos = load_position(w.id)
        new_pos = coord_to_pos(old_pos.x + coord_x_shift, old_pos.y + coord_y_shift, 1, 1)

        if new_pos.x < 0 or new_pos.y < 0 or new_pos.x >= cols or new_pos.y >= rows then continue

        move_to_somewhere(w, new_pos)

    update_selected_item_drag_image()
    return


selected_copy_to_clipboard = ->
    tmp_list = []
    for i in selected_item
        w = Widget.look_up(i)
        if w? and w.modifiable == true
            tmp_list.push(w.entry)
    DCore.DEntry.clipboard_copy(tmp_list)


selected_cut_to_clipboard = ->
    tmp_list = []
    for i in selected_item
        w = Widget.look_up(i)
        if w? and w.modifiable == true
            tmp_list.push(w.entry)
            w.display_cut()
    DCore.DEntry.clipboard_cut(tmp_list)


paste_from_clipboard = ->
    e = DCore.DEntry.create_by_path(DCore.Desktop.get_desktop_path())
    DCore.DEntry.clipboard_paste(e)


item_dragstart_handler = (widget, evt) ->
    all_selected_items = ""
    if selected_item.length > 0
        for i in [0 ... selected_item.length] by 1
            w = Widget.look_up(selected_item[i])
            if not w? or w.modifiable == false then continue
            path = w.get_path()
            if path.length > 0
                all_selected_items += "file://" + encodeURI(w.get_path()) + "\n"

        evt.dataTransfer.setData("text/uri-list", all_selected_items)
        evt.dataTransfer.effectAllowed = "all"

        x = evt.x - drag_start.x * _ITEM_WIDTH_
        y = evt.y - drag_start.y * _ITEM_HEIGHT_
        evt.dataTransfer.setDragCanvas(drag_canvas, x, y)

    else
        evt.dataTransfer.effectAllowed = "none"

    return


set_item_selected = (w, change_focus = true, add_top = false) ->
    if w.selected == false
        w.item_selected()
        if add_top == true
            selected_item.unshift(w.id)
        else
            selected_item.push(w.id)

        if change_focus
            if last_widget != w.id
                if last_widget.length > 0 then Widget.look_up(last_widget)?.item_blur()
                last_widget = w.id
            if not w.has_focus then w.item_focus()
    return


set_all_item_selected = ->
    for i in speical_item.concat(all_item)
        if selected_item.indexOf(i) >= 0 then continue
        w = Widget.look_up(i)
        if w? then set_item_selected(w, false)


cancel_item_selected = (w, change_focus = true) ->
    i = selected_item.indexOf(w.id)
    if i < 0 then return false
    selected_item.splice(i, 1)
    w.item_normal()

    if change_focus and last_widget != w.id
        if last_widget.length > 0 then Widget.look_up(last_widget)?.item_blur()
        last_widget = w.id
        w.item_focus()
    return true


cancel_all_selected_stats = (clear_last = true) ->
    Widget.look_up(i)?.item_normal() for i in selected_item
    selected_item.splice(0)
    return


update_selected_stats = (w, evt) ->
    if evt.ctrlKey
        if w.selected == true then cancel_item_selected(w)
        else set_item_selected(w)

    else if evt.shiftKey
        if selected_item.length > 1
            last_one_id = selected_item[selected_item.length - 1]
            selected_item.splice(selected_item.length - 1, 1)
            cancel_all_selected_stats()
            selected_item.push(last_one_id)

        if selected_item.length == 1
            end_pos = pixel_to_pos(evt.clientX, evt.clientY, 1, 1)
            start_pos = load_position(Widget.look_up(selected_item[0]).id)

            ret = compare_pos_top_left(start_pos, end_pos)
            if ret < 0
                for key in speical_item.concat(all_item)
                    val = Widget.look_up(key)
                    i_pos = load_position(val.id)
                    if compare_pos_top_left(end_pos, i_pos) >= 0 and compare_pos_top_left(start_pos, i_pos) < 0
                        set_item_selected(val, true, true)
            else if ret == 0
                cancel_item_selected(selected_item[0])
            else
                for key in speical_item.concat(all_item)
                    val = Widget.look_up(key)
                    i_pos = load_position(val.id)
                    if compare_pos_top_left(start_pos, i_pos) > 0 and compare_pos_top_left(end_pos, i_pos) <= 0
                        set_item_selected(val, true, true)

        else
            set_item_selected(w)

    else
        n = selected_item.indexOf(w.id)
        if n < 0
            cancel_all_selected_stats()
            set_item_selected(w)

        if n >= 0
            selected_item.splice(n, 1)
            cancel_all_selected_stats()
            selected_item.push(w.id)
            if last_widget != w.id
                if last_widget.length > 0 then Widget.look_up(last_widget)?.item_blur()
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

    drag_canvas.width = (bottom_right.x - top_left.x + 1) * _ITEM_WIDTH_
    drag_canvas.height = (bottom_right.y - top_left.y + 1) * _ITEM_HEIGHT_

    for i in selected_item
        w = Widget.look_up(i)
        if not w? then continue

        pos = load_position(i)
        pos.x -= top_left.x
        pos.y -= top_left.y

        start_x = pos.x * _ITEM_WIDTH_
        start_y = pos.y * _ITEM_HEIGHT_

        # draw icon
        drag_context.shadowColor = "rgba(0, 0, 0, 0)"
        drag_context.drawImage(w.item_icon, start_x + 22, start_y, 48, 48)
        # draw text
        drag_context.shadowOffsetX = 1
        drag_context.shadowOffsetY = 1
        drag_context.shadowColor = "rgba(0, 0, 0, 1.0)"
        drag_context.shadowBlur = 1.5
        drag_context.font = "bold small san-serif"
        drag_context.fillStyle = "rgba(255, 255, 255, 1.0)"
        drag_context.textAlign = "center"
        rest_text = w.element.innerText
        line_number = 0
        while rest_text.length > 0
            if rest_text.length < 10 then n = rest_text.length
            else n = 10
            m = drag_context.measureText(rest_text.substr(0, n)).width
            if m == 90
            else if m > 90
                --n
                while n > 0 and drag_context.measureText(rest_text.substr(0, n)).width > 90
                    --n
            else
                ++n
                while n <= rest_text.length and drag_context.measureText(rest_text.substr(0, n)).width < 90
                    ++n

            line_text = rest_text.substr(0, n)
            rest_text = rest_text.substr(n)

            drag_context.fillText(line_text, start_x + 46, start_y + 64 + line_number * 14, 90)
            ++line_number

    [drag_start.x, drag_start.y] = [top_left.x , top_left.y]
    return


is_selected_multiple_items = ->
    selected_item.length > 1


open_selected_items = ->
    Widget.look_up(i)?.item_exec() for i in selected_item


delete_selected_items = (real_delete) ->
    tmp = []
    for i in selected_item
        w = Widget.look_up(i)
        if w? and w.modifiable == true then tmp.push(w.entry)

    if real_delete then DCore.DEntry.delete(tmp)
    else DCore.DEntry.trash(tmp)


show_selected_items_Properties = ->
    tmp = []
    for i in selected_item
        w = Widget.look_up(i)
        if w? then tmp.push("file://#{encodeURI(w.get_path())}")

    #XXX: we get an error here when call the nautilus DBus interface
    try
        s_nautilus?.ShowItemProperties_sync(tmp, "")
    catch e


gird_left_mousedown = (evt) ->
    evt.stopPropagation()
    if evt.button == 0 and evt.ctrlKey == false and evt.shiftKey == false
        cancel_all_selected_stats()
        if last_widget.length > 0 then Widget.look_up(last_widget)?.item_blur()


grid_right_click = (evt) ->
    evt.stopPropagation()
    if evt.ctrlKey == false and evt.shiftKey == false
        cancel_all_selected_stats()

    menus = []
    menus.push([_("arrange icons"), [
                [11, _("by name")],
                [12, _("by last modified time")]
            ]
        ])
    menus.push([_("New"), [
                [21, _("folder")],
                [22, _("text file")]
            ]
        ])
    menus.push([3, _("open terminal here")])
    menus.push([4, _("paste"), DCore.DEntry.can_paste()])
    menus.push([])
    menus.push([5, _("Personal")])
    menus.push([6, _("Display Settings")])

    div_grid.parentElement.contextMenu = build_menu(menus)
    return


grid_do_itemselected = (evt) ->
    switch evt.id
        when 11 then menu_sort_desktop_item_by_name()
        when 12 then menu_sort_desktop_item_by_mtime()
        when 21 then menu_create_new_folder()
        when 22 then menu_create_new_file()
        when 3 then DCore.Desktop.run_terminal()
        when 4 then paste_from_clipboard()
        when 5 then DCore.Desktop.run_deepin_settings("individuation")
        when 6 then DCore.Desktop.run_deepin_settings("display")
        else echo "not implemented function #{evt.id},#{evt.title}"
    return


grid_do_keydown_to_shortcut = (evt) ->
    if evt.keyCode >= 37 and evt.keyCode <= 40
        evt.stopPropagation()
        evt.preventDefault()

        if last_widget.length == 0 or not (w = Widget.look_up(last_widget))?
            w = Widget.look_up(_ITEM_ID_COMPUTER_)

        w_f = null
        if evt.keyCode == 37         # left arrow
            w_f = find_item_by_coord_delta(w, -1, 0)
        else if evt.keyCode == 38    # up arrow
            w_f = find_item_by_coord_delta(w, 0, -1)
        else if evt.keyCode == 39    # right arrow
            w_f = find_item_by_coord_delta(w, 1, 0)
        else if evt.keyCode == 40    # down arrow
            w_f = find_item_by_coord_delta(w, 0, 1)
        if not w_f? then return

        if evt.ctrlKey == true
            w.item_blur()
            w_f.item_focus()
            last_widget = w_f.id

        else if evt.shiftKey == true
            if selected_item.length > 1
                start_item = selected_item[0]
                selected_item.splice(0, 1)
                cancel_all_selected_stats()
                selected_item.push(start_item)

            if selected_item.length == 1
                start_pos = load_position(selected_item[0])
                end_pos = load_position(w_f.id)
                if compare_pos_top_left(start_pos, end_pos) < 0
                    pos_a = start_pos
                    pos_b = end_pos
                else
                    pos_b = start_pos
                    pos_a = end_pos
                for i in speical_item.concat(all_item)
                    if not (w_i = Widget.look_up(i))? then continue
                    item_pos = load_position(w_i.id)
                    if compare_pos_rect(pos_a, pos_b, item_pos) == true
                        set_item_selected(w_i) if not w_i.selected

                if last_widget != w_f.id
                    w.item_blur() if last_widget.length > 0 and (w = Widget.look_up(last_widget))?
                    last_widget = w_f.id
            else
                w_f.itemselected()
        else
            cancel_all_selected_stats()
            set_item_selected(w_f)
    return


grid_do_keyup_to_shrotcut = (evt) ->
    msg_disposed = false
    if ingore_keyup_counts > 0
        --ingore_keyup_counts
        msg_disposed = true

    else if evt.keyCode == 65    # CTRL+A
        if evt.ctrlKey == true and evt.shiftKey == false and evt.altKey == false
            set_all_item_selected()
            msg_disposed = true

    else if evt.keyCode == 88    # CTRL+X
        if evt.ctrlKey == true and evt.shiftKey == false and evt.altKey == false
            selected_cut_to_clipboard()
            msg_disposed = true

    else if evt.keyCode == 67    # CTRL+C
        if evt.ctrlKey == true and evt.shiftKey == false and evt.altKey == false
            selected_copy_to_clipboard()
            msg_disposed = true

    else if evt.keyCode == 86    # CTRL+V
        if evt.ctrlKey == true and evt.shiftKey == false and evt.altKey == false
            paste_from_clipboard()
            msg_disposed = true

    else if evt.keyCode == 46    # Delete
        if evt.ctrlKey == false and evt.altKey == false
            delete_selected_items(evt.shiftKey == true)
            msg_disposed = true

    else if evt.keyCode == 113   # F2
        if evt.ctrlKey == false and evt.shiftKey == false and evt.altKey == false
            if selected_item.length == 1
                w = Widget.look_up(selected_item[0])
                if w? then w.item_rename()
            msg_disposed = true

    else if evt.keyCode == 13    # Enter
        if evt.ctrlKey == false and evt.shiftKey == false and evt.altKey == false
            if selected_item.length > 0
                Widget.look_up(last_widget)?.item_exec()
            msg_disposed = true

    else if evt.keyCode == 32    # space
        if evt.ctrlKey == true
            if last_widget.length > 0 and (w = Widget.look_up(last_widget))?
                if w.selected == false
                    set_item_selected(w)
                    w.item_focus() if not w.has_focus
                else
                    cancel_item_selected(w)
            msg_disposed = true

    if msg_disposed == true
        evt.stopPropagation()
        evt.preventDefault()


init_speical_desktop_items = ->
    item = new ComputerVDir
    if item?
        div_grid.appendChild(item.element)
        speical_item.push(item.get_id())

    item = new HomeVDir
    if item?
        div_grid.appendChild(item.element)
        speical_item.push(item.get_id())

    item = new TrashVDir
    if item?
        div_grid.appendChild(item.element)
        speical_item.push(item.get_id())


create_item_grid = ->
    div_grid = document.createElement("div")
    div_grid.setAttribute("id", "item_grid")
    document.body.appendChild(div_grid)
    update_gird_position(s_offset_x, s_offset_y, s_width, s_height)
    init_grid_drop()
    div_grid.parentElement.addEventListener("mousedown", gird_left_mousedown)
    div_grid.parentElement.addEventListener("contextmenu", grid_right_click)
    div_grid.parentElement.addEventListener("itemselected", grid_do_itemselected)
    div_grid.parentElement.addEventListener("keydown", grid_do_keydown_to_shortcut)
    div_grid.parentElement.addEventListener("keyup", grid_do_keyup_to_shrotcut)
    sel = new Mouse_Select_Area_box(div_grid.parentElement)

    drag_canvas = document.createElement("canvas")
    drag_context = drag_canvas.getContext('2d')

    init_speical_desktop_items()


#class ItemGrid
#    constructor : (parentElement) ->
#        @_parent_element = parentElement
#        @_workarea_width = 0
#        @_workarea_height = 0
#        @_offset_x = 0
#        @_offset_y = 0


class Mouse_Select_Area_box
    constructor : (parentElement) ->
        @parent_element = parentElement
        @last_effect_item = new Array
        @element = document.createElement("div")
        @element.setAttribute("id", "mouse_select_area_box")
        @element.style.visibility = "hidden"
        @parent_element.appendChild(@element)
        @parent_element.addEventListener("mousedown", @mousedown_event)


    mousedown_event : (evt) =>
        evt.stopPropagation()
        evt.preventDefault()
        if evt.button == 0
            @parent_element.addEventListener("mousemove", @mousemove_event)
            @parent_element.addEventListener("mouseup", @mouseup_event)
            @parent_element.addEventListener("contextmenu", @contextmenu_event, true)
            @start_point = evt
            @start_pos = pixel_to_pos(evt.clientX - s_offset_x, evt.clientY - s_offset_y, 1, 1)
            @last_pos = @start_pos
        return


    contextmenu_event : (evt) ->
        evt.stopPropagation()
        evt.preventDefault()
        return


    mousemove_event : (evt) =>
        evt.stopPropagation()
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

        new_pos = pixel_to_pos(evt.clientX - s_offset_x, evt.clientY - s_offset_y, 1, 1)
        if compare_pos_top_left(@last_pos, new_pos) != 0
            if compare_pos_top_left(@start_pos, new_pos) < 0
                pos_a = new_pos
                pos_b = @start_pos
            else
                pos_a = @start_pos
                pos_b = new_pos

            effect_item = new Array
            for i in speical_item.concat(all_item)
                w = Widget.look_up(i)
                if not w? then continue
                item_pos = load_position(w.id)
                if compare_pos_rect(pos_a, pos_b, item_pos) == true
                    effect_item.push(i)

            temp_list = effect_item.concat()
            sel_list = @last_effect_item.concat()
            if temp_list.length > 0 and sel_list.length > 0
                w.item_blur() if (w = Widget.look_up(last_widget))? and w.has_focus
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
                    else if w.selected == false then set_item_selected(w, false)
                    else cancel_item_selected(w, false)
                for i in sel_list
                    w = Widget.look_up(i)
                    if not w? then continue
                    else if w.selected == false then set_item_selected(w, false)
                    else cancel_item_selected(w, false)

            else if evt.shiftKey == true
                for i in temp_list
                    w = Widget.look_up(i)
                    if not w? then continue
                    if w.selected == false then set_item_selected(w, false)

            else
                for i in temp_list
                    w = Widget.look_up(i)
                    if not w? then continue
                    if w.selected == false then set_item_selected(w, false)
                for i in sel_list
                    w = Widget.look_up(i)
                    if not w? then continue
                    if w.selected == true then cancel_item_selected(w, false)

            @last_pos = new_pos
            @last_effect_item = effect_item

            if temp_list.length > 0 or sel_list.length > 0 then update_selected_item_drag_image()
        return


    mouseup_event : (evt) =>
        evt.stopPropagation()
        evt.preventDefault()
        @parent_element.removeEventListener("mousemove", @mousemove_event)
        @parent_element.removeEventListener("mouseup", @mouseup_event)
        @parent_element.removeEventListener("contextmenu", @contextmenu_event, true)
        @element.style.visibility = "hidden"
        @last_effect_item.splice(0)
        return


    destory : =>
        @parent_element.removeChild(@element)
