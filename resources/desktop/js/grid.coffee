#Copyright (c) 2011 ~ 2014 Deepin, Inc.
#              2011 ~ 2014 snyh
#
#Author:      snyh <snyh@snyh.org>
#             Cole <phcourage@gmail.com>
#             bluth <yuanchenglu001@gmail.com>
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

# gird size cols lie ---59; rows  hang ---30
# i cols lie ----59;  j rows hang----30
cols = 0
rows = 0

# grid html element;not per item but only one! it is the whole Invalid Screen for desktop
div_grid = null
# grid occupy table
o_table = null

# all file items on desktop
all_item = new Array
# special items on desktop
speical_item = new Array
# all widget items on grid
widget_item = new Array
# all selected items on desktop
selected_item = new Array
# the last widget which been operated last time
last_widget = ""

# store the buffer canvas for drag the items
drag_canvas = null
# store the context of the buffer canvas for drag the items
drag_context = null
# store the left top point of drag image start point
drag_start = {x : 0, y: 0}

# store the area selection box for grid
sel = null

# we need to ignore keyup event when rename files
ingore_keyup_counts = 0

# store the pos the user pop the context menu
rightclick_pos = {clientX : 0, clientY : 0}

name_add_before = _("Untitled") + " "
#templates
TEMPLATES_FILE_ID_FIRST = 22
templates = []


#direction
LEFT = -1
CENTER = 0
RIGHT = 1
UP  = -1
DOWN = 1



#draw icon and title to canvas surface
draw_icon_on_canvas = (canvas_cantext, start_x, start_y, icon, title)->
    # draw icon
    if icon.src.length
        canvas_cantext.shadowColor = "rgba(0, 0, 0, 0)"
        canvas_cantext.drawImage(
            icon,
            start_x + (_ITEM_WIDTH_ - icon.width) / 2,
            start_y,
            icon.width,
            icon.height)
    # draw text
    canvas_cantext.shadowOffsetX = 1
    canvas_cantext.shadowOffsetY = 1
    canvas_cantext.shadowColor = "rgba(0, 0, 0, 1.0)"
    canvas_cantext.shadowBlur = 1.5
    canvas_cantext.font = "small san-serif"
    canvas_cantext.fillStyle = "rgba(255, 255, 255, 1.0)"
    canvas_cantext.textAlign = "center"
    rest_text = title
    line_number = 0
    while rest_text.length > 0
        if rest_text.length < 10 then n = rest_text.length
        else n = 10
        m = canvas_cantext.measureText(rest_text.substr(0, n)).width
        if m == 90
        else if m > 90
            --n
            while n > 0 and canvas_cantext.measureText(rest_text.substr(0, n)).width > 90
                --n
        else
            ++n
            while n <= rest_text.length and canvas_cantext.measureText(rest_text.substr(0, n)).width < 90
                ++n

        line_text = rest_text.substr(0, n)
        rest_text = rest_text.substr(n)

        canvas_cantext.fillText(line_text, start_x + 46, start_y + 64 + line_number * 14, 90)
        ++line_number


# calc the best row and col number for desktop
calc_row_and_cols = (wa_width, wa_height) ->
    n_cols = Math.floor(wa_width / _GRID_WIDTH_INIT_)
    n_rows = Math.floor(wa_height / _GRID_HEIGHT_INIT_)
    xx = wa_width % _GRID_WIDTH_INIT_
    yy = wa_height % _GRID_HEIGHT_INIT_
    return [n_cols, n_rows, _GRID_WIDTH_INIT_, _GRID_HEIGHT_INIT_]


#limit_in_desktop_range
# i cols lie ----59;  j rows hang----30
limit_in_desktop_range = (pos) ->
    i = pos.x
    j = pos.y
    if i?
        if i < 0 then i = 0
        else if i > cols then i = cols
    if j?
        if j < 0 then j  = 0
        else if j > rows then j = rows
    pos.x = i
    pos.y = j
    return pos

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
    return


load_position = (id) ->
    if typeof(id) != "string" then echo "error load_position #{id}"

    pos = localStorage.getObject("id:" + id)

    if pos == null then return null

    if cols > 0 and pos.x + pos.width - 1 >= cols then pos.x = cols - pos.width
    if rows > 0 and pos.y + pos.height - 1 >= rows then pos.y = rows - pos.height
    pos

save_position = (id, pos) ->
    assert("string" == typeof(id), "[save_position]id not string")
    assert(pos != null, "[save_position]pos null")
    localStorage.setObject("id:" + id, pos)
    return


discard_position = (id) ->
    assert("string" == typeof(id), "[discard_position]id not string")
    localStorage.removeItem("id:" + id)
    return


clear_all_positions = ->
    for i in all_item
        localStorage.removeItem("id:#{i}")
    for i in speical_item
        localStorage.removeItem("id:#{i}")
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
    return top_left <= pos.x <= top_right and bottom_left <= pos.y <= bottom_right


calc_pos_to_pos_distance = (base, pos) ->
    Math.sqrt(Math.pow(Math.abs(base.x - pos.x), 2) + Math.pow(Math.abs(base.y - pos.y), 2))


find_item_by_coord_delta = (start_item, x_delta, y_delta) ->
    items = speical_item.concat(all_item)
    pos = start_item.get_pos()
    while true
        if x_delta != 0
            pos.x += x_delta * _PART_
            # if  pos.x < 0 or pos.x > cols
            #     pos.x = 0
            #     pos.y += y_delta * _PART_
            #     break
            if x_delta > 0 and pos.x > cols then break
            else if x_delta < 0 and pos.x < 0 then break
        if y_delta != 0
            pos.y += y_delta * _PART_
            # if pos.y < 0 or pos.y > rows
            #     pos.x += x_delta * _PART_
            #     pos.y = 0
            #     break
            if y_delta > 0 and pos.y > rows then break
            else if y_delta < 0 and pos.y < 0 then break

        pos = limit_in_desktop_range(pos)
        if detect_occupy(pos) == false then continue

        #optimization by looking up o_table to get ID
        for i in items
            w = Widget.look_up(i)
            if not w? then continue
            find_pos = w.get_pos()
            if (find_pos.x <= pos.x <= find_pos.x + find_pos.width - 1) and (find_pos.y <= pos.y <= find_pos.y + find_pos.height - 1)
                return w
    null



init_occupy_table = ->
    o_table = new Array()
    # i cols lie ----59;  j rows hang----30
    for i in [0..cols]
        o_table[i] = new Array(rows)
    return

clear_occupy = (id, info) ->
    if info.x == -1 or info.y == -1 then return true
    for i in [0..info.width - 1] by 1
        for j in [0..info.height - 1] by 1
            # here perhaps should not use if checkout , maybe just make 16 o_tabble null
            # should be optimize,maybe make bug
            if o_table[info.x+i][info.y+j] == id
                o_table[info.x+i][info.y+j] = null
            else
                return false
    return true


set_occupy = (id, info) ->
    assert(info != null, "[set_occupy] get null info")
    for i in [0..info.width - 1] by 1
        for j in [0..info.height - 1] by 1
            o_table[info.x+i][info.y+j] = id
    return

# detect_occupy true : pos already be standed,perhaps 1/16 only one grid be standed
#               false :pos not be standed , the 16 grid are all free
#      warning: the id is used for : the self pos is free for detect !
detect_occupy = (info, id = null) ->
    assert(info != null, "[detect_occupy]get null info")
    if (info.x + info.width) > cols  or (info.y + info.height) > rows
        return true
    info = limit_in_desktop_range(info)
    for i in [0..info.width - 1] by 1
        for j in [0..info.height - 1] by 1
            if o_table[info.x+i][info.y+j]? && o_table[info.x+i][info.y+j] isnt id
                return true
    return false


clear_occupy_table = ->
    item_list = all_item.concat(speical_item)
    for i in item_list
        if (w = Widget.look_up(i))?
            pos = w.get_pos()
            clear_occupy(w.get_id(), pos)
            pos.x = -1
            pos.y = -1
            w.set_pos(pos)
    return


find_free_position = (w, h) ->
    # i cols lie ----59;  j rows hang----30
    if not w? then w = _PART_
    if not h? then h = _PART_
    info = {x:0, y:0, width:w, height:h}
    for i in [0..cols - w]
        for j in [0..rows - h]
            if not o_table[i][j]? && not o_table[i + w - 1][j]? && not o_table[i][j + h - 1]? && not o_table[i + w - 1][j + h - 1]?
                info.x = i
                info.y = j
                return info
    return null


pixel_to_pos = (x, y, w, h) ->
    # here '-1' to fix bug of drag DesktopEntry and dragend the DesktopEntry move to right, after -1 ,it will not go to right . drag more actual!
    index_x = Math.min(Math.floor((x - s_offset_x) / grid_item_width) - 1, (cols - 1))
    index_y = Math.min(Math.floor((y - s_offset_y) / grid_item_height) - 1, (rows - 1))
    coord_to_pos(index_x, index_y, w, h)

pos_to_pixel = (pos) ->
    left = pos.x * grid_item_width + s_offset_x
    top = pos.y * grid_item_height + s_offset_y
    width_px = pos.width * grid_item_width
    height_px = pos.height * grid_item_height
    {x: left , y: top , width : width_px , height : height_px}

coord_to_pos = (pos_x, pos_y, w, h) ->
    {x : pos_x, y : pos_y, width : w, height : h}


move_to_position = (widget, pos) ->
    old_pos = widget.get_pos()
    widget.move(pos.x * grid_item_width + s_offset_x, pos.y * grid_item_height + s_offset_y)

    if (old_pos.x > -1) and (old_pos.y > -1) then clear_occupy(widget.get_id(), old_pos)
    set_occupy(widget.get_id(), pos)

    widget.set_pos(pos)
    save_position(widget.get_id(), pos)
    return


# need optimization
move_to_anywhere = (widget) ->
    pos = load_position(widget.get_id())
    if pos? and not detect_occupy(pos,widget.get_id())
        move_to_position(widget, pos)
    else
        #if pos localStorage return null means the pos is occupyed
        old_size = widget.get_pos()
        new_pos = find_free_position(old_size.width, old_size.height)
        move_to_position(widget, new_pos)
    return


move_to_somewhere = (widget, pos) ->
    if not detect_occupy(pos,widget.get_id())
        #echo "free pos"
        move_to_position(widget, pos)
    else
        #echo "to find_free_position"
        pos = find_free_position(pos.width, pos.height)
        move_to_position(widget, pos)
    return


place_desktop_items = ->
    clear_occupy_table()

    total_item = speical_item.concat(all_item)
    not_founds = []
    for i in total_item
        if not (w = Widget.look_up(i))?
            echo "uncleaned item #{i}"
            continue

        pos = w.get_pos()
        if (pos.x > -1) and (pos.y > -1) # we have a place
            if not detect_occupy(pos,w.get_id())
                move_to_somewhere(w, pos)
        else if (old_pos = load_position(i)) != null # we get position remembered in localStorage
            move_to_somewhere(w, old_pos)
        else
            not_founds.push(i)

    for i in not_founds
        w = Widget.look_up(i)
        if w? then move_to_anywhere(w)
    return


sort_list_by_name_from_id = (id1, id2) ->
    w1 = Widget.look_up(id1)
    w2 = Widget.look_up(id2)
    if not w1? or not w2?
        echo "we get error here[sort_list_by_name_from_id]"
        return id1.localeCompare(id2)
    else
        return w1.get_name().localeCompare(w2.get_name())


sort_list_by_mtime_from_id = (id1, id2) ->
    w1 = Widget.look_up(id1)
    w2 = Widget.look_up(id2)
    if not w1? or not w2?
        echo "we get error here[sort_list_by_mtime_from_id]"
        return w1.localeCompare(w2)
    else
        return w1.get_mtime() - w2.get_mtime()


sort_desktop_item_by_func = (func) ->
    clear_all_positions()

    item_ordered_list = all_item.concat()
    item_ordered_list.sort(func)

    clear_occupy_table()

    for i in speical_item
        if (w = Widget.look_up(i))?
            old_pos = w.get_pos()
            old_pos.x = -1
            old_pos.y = -1
            w.set_pos(old_pos)
            move_to_anywhere(w)

    for i in item_ordered_list
        if (w = Widget.look_up(i))?
            old_pos = w.get_pos()
            old_pos.x = -1
            old_pos.y = -1
            w.set_pos(old_pos)
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
    pos = pixel_to_pos(rightclick_pos.clientX, rightclick_pos.clientY, 1*_PART_, 1*_PART_)
    pos = limit_in_desktop_range(pos)
    pos = find_nearest_free_pos(w,pos)
    move_to_somewhere(w, pos)
    all_item.push(w.get_id())
    set_item_selected(w)
    update_selected_item_drag_image()
    w.item_rename()

# all DND event handlers
init_grid_drop = ->
    div_grid.addEventListener("drop", (evt) =>
        evt.preventDefault()
        evt.stopPropagation()

        file_uri = []
        tmp_copy = []
        tmp_move = []
        if (xdg_target = evt.dataTransfer.getXDSPath()).length > 0 # compatible with XDS protocol
            desktop_uri = "#{DCore.DEntry.get_uri(g_desktop_entry)}/#{xdg_target}"
            evt.dataTransfer.setXDSPath(desktop_uri)
        else if evt.dataTransfer.files.length == 0 # if the drop_target is internet files
            #echo "file from internet , evt.dataTransfer.files.length  = 0"
            xdg_target = evt.dataTransfer.getData("Text")
            enter_indexof = []
            enter_indexof[0] = 0
            k = 1
            for i in [0 ... xdg_target.length] by 1
                if xdg_target[i] == "\n"
                    enter_indexof[k++] = i
            for i in [0 ... enter_indexof.length - 1] by 1
                file_uri[i] = xdg_target.substring(enter_indexof[i],enter_indexof[i+1]-1)#  -1 means delete enter char

            pos = pixel_to_pos(evt.clientX, evt.clientY, 1*_PART_, 1*_PART_)
            w = Math.sqrt(file_uri.length) + 1
            for i in [0 ... file_uri.length] by 1
                file = file_uri[i]
                if (f_e = DCore.DEntry.create_by_path(file))?
                    tmp_copy.push(f_e)
                    # make items as much nearer as possible to the pos that user drag on
                    p = {x : 0, y : 0, width : 1*_PART_, height : 1*_PART_}
                    p.x = pos.x + (i % w)
                    p.y = pos.y + Math.floor(i / w)
                    if p.x >= cols or p.y >= rows then continue
                    p = find_nearest_free_pos_id(DCore.DEntry.get_id(f_e),p)
                    save_position(DCore.DEntry.get_id(f_e), p) if not detect_occupy(p)
            if tmp_copy.length
                DCore.DEntry.copy(tmp_copy, g_desktop_entry)

            evt.dataTransfer.setData("Text",desktop_uri)

        else if not _IS_DND_INTERLNAL_(evt) and not _IS_DND_RICHDIR_(evt) and evt.dataTransfer.files.length > 0
            #echo "file not from desktop_internal and richdir_internal && evt.dataTransfer.files.length = " + evt.dataTransfer.files.length
            pos = pixel_to_pos(evt.clientX, evt.clientY, 1*_PART_, 1*_PART_)
            w = Math.sqrt(evt.dataTransfer.files.length) + 1
            for i in [0 ... evt.dataTransfer.files.length] by 1
                file = evt.dataTransfer.files[i]
                if (f_e = DCore.DEntry.create_by_path(file.path))?
                    tmp_copy.push(f_e)
                    p = {x : 0, y : 0, width : 1*_PART_, height : 1*_PART_}
                    p.x = pos.x + (i % w)
                    p.y = pos.y + Math.floor(i / w)
                    if p.x >= cols or p.y >= rows then continue
                    p = find_nearest_free_pos_id(DCore.DEntry.get_id(f_e),p)
                    save_position(DCore.DEntry.get_id(f_e), p) if not detect_occupy(p)
            if tmp_copy.length
                DCore.DEntry.copy(tmp_copy, g_desktop_entry)

        else if  _IS_DND_RICHDIR_(evt) and evt.dataTransfer.files.length > 0
            #echo "file from richdir_internal && evt.dataTransfer.files.length = " + evt.dataTransfer.files.length
            pos = pixel_to_pos(evt.clientX, evt.clientY, 1*_PART_, 1*_PART_)
            w = Math.sqrt(evt.dataTransfer.files.length) + 1
            for i in [0 ... evt.dataTransfer.files.length] by 1
                file = evt.dataTransfer.files[i]
                if (f_e = DCore.DEntry.create_by_path(file.path))?
                    tmp_move.push(f_e)
                    # make items as much nearer as possible to the pos that user drag on
                    p = {x : 0, y : 0, width : 1*_PART_, height : 1*_PART_}
                    p.x = pos.x + (i % w)
                    p.y = pos.y + Math.floor(i / w)
                    if p.x >= cols or p.y >= rows then continue
                    p = find_nearest_free_pos_id(DCore.DEntry.get_id(f_e),p)
                    save_position(DCore.DEntry.get_id(f_e), p) if not detect_occupy(p)
            if tmp_move.length
                DCore.DEntry.move(tmp_move, g_desktop_entry, true)

        return
    )
    div_grid.addEventListener("dragover", (evt) =>
        evt.preventDefault()
        evt.stopPropagation()
        if evt.dataTransfer.getXDSPath().length > 0 # compatible with XDS protocol
            evt.dataTransfer.dropEffect = "copy"
        else if not _IS_DND_INTERLNAL_(evt)
            evt.dataTransfer.dropEffect = "move"
        else
            evt.dataTransfer.dropEffect = "link"
        return
    )
    div_grid.addEventListener("dragenter", (evt) =>
        if evt.dataTransfer.getXDSPath().length > 0 # compatible with XDS protocol
            evt.dataTransfer.dropEffect = "copy"

        else if not _IS_DND_INTERLNAL_(evt)
            evt.dataTransfer.dropEffect = "move"
        else
            evt.dataTransfer.dropEffect = "link"
        return
    )
    div_grid.addEventListener("dragleave", (evt) =>
        evt.stopPropagation()
        return
    )


selected_copy_to_clipboard = ->
    tmp_list = []
    for i in selected_item
        w = Widget.look_up(i)
        if w? and w.modifiable == true
            tmp_list.push(w.get_entry())
    DCore.DEntry.clipboard_copy(tmp_list)


selected_cut_to_clipboard = ->
    tmp_list = []
    for i in selected_item
        w = Widget.look_up(i)
        if w? and w.modifiable == true
            tmp_list.push(w.get_entry())
            w.display_cut()
    DCore.DEntry.clipboard_cut(tmp_list)


paste_from_clipboard = ->
    DCore.DEntry.clipboard_paste(g_desktop_entry)


item_dragstart_handler = (widget, evt) ->
    #echo "item_dragstart_handler"
    all_selected_items_path = ""
    if selected_item.length > 0
        for i in [0 ... selected_item.length] by 1
            w = Widget.look_up(selected_item[i])
            if not w? or w.modifiable == false then continue
            path = w.get_path()
            echo path
            if path.length > 0
                all_selected_items_path += path + "\r\n"
        if all_selected_items_path.length > 2
            all_selected_items_path = all_selected_items_path.substring(0,all_selected_items_path.length - 2)
        else
            echo "warning:items path is null"
        evt.dataTransfer.setData("text/uri-list", all_selected_items_path)
        _SET_DND_INTERNAL_FLAG_(evt)
        evt.dataTransfer.effectAllowed = "all"

        pos = widget.get_pos()
        x = (pos.x - drag_start.x) * grid_item_width + (_ITEM_WIDTH_ / 2)
        y = (pos.y - drag_start.y) * grid_item_height + 24
        evt.dataTransfer.setDragCanvas(drag_canvas, x, y)

    else
        evt.dataTransfer.effectAllowed = "none"

    return


item_dragend_handler = (w, evt) ->
    #echo evt.dataTransfer.dropEffect
    dropEffect = evt.dataTransfer.dropEffect
    #echo dropEffect
    if dropEffect == "link"
        old_pos = w.get_pos()
        new_pos = pixel_to_pos(evt.clientX, evt.clientY, 1*_PART_, 1*_PART_)
        coord_x_shift = new_pos.x - old_pos.x
        coord_y_shift = new_pos.y - old_pos.y

        if coord_x_shift == 0 and coord_y_shift == 0 then return

        far_pos = {x : 0, y : 0, width : 1*_PART_, height : 1*_PART_}

        if coord_x_shift == 0
            far_pos.x = new_pos.x
        else if coord_y_shift == 0
            far_pos.y = new_pos.y
        else
            k = (new_pos.y - old_pos.y) / (new_pos.x - old_pos.x)
            b = (old_pos.y * new_pos.x - old_pos.x * new_pos.y) / (new_pos.x - old_pos.x)
            if k < 0
                far_pos.x = (0 - b) / k
            else
                far_pos.y = b

        # sort selected items by distance from the base point
        ordered_list = new Array()
        distance_list = new Array()
        for i in selected_item
            if not (w = Widget.look_up(i))? then continue
            dis = calc_pos_to_pos_distance(far_pos, w.get_pos())
            for j in [0 ... distance_list.length]
                if dis < distance_list[j]
                    break
            ordered_list.splice(j, 0, i)
            distance_list.splice(j, 0, dis)

        if (coord_x_shift <= 0 and coord_y_shift > 0) or (coord_x_shift > 0 and coord_y_shift >= 0)
            ordered_list.reverse()

        for i in ordered_list
            if not (w = Widget.look_up(i))? then continue
            widget = w
            old_pos = widget.get_pos()
            id = widget.get_id()
            new_pos = coord_to_pos(old_pos.x + coord_x_shift, old_pos.y + coord_y_shift, old_pos.width, old_pos.height)
            if new_pos.x < 0 or new_pos.y < 0 or new_pos.x >= cols or new_pos.y >= rows then continue

            new_pos = find_nearest_free_pos(widget,new_pos)
            move_to_somewhere(widget, new_pos)

        update_selected_item_drag_image()

    return


find_nearest_free_pos_id = (id,dest_pos,radius = _PART_) ->
    width = dest_pos.width
    height = dest_pos.height
    final_pos = coord_to_pos(dest_pos.x, dest_pos.y, width, height)
    if detect_occupy(final_pos,id)
        distance_list = new Array()
        distance_list_sorted = new Array()
        pos_list = new Array()
        minest = new Array()

        # i cols lie ----59;  j rows hang----30
        i_start = dest_pos.x - radius
        if i_start < 0 then i_start = 0
        i_end = dest_pos.x + radius
        if i_end > cols then i_end = cols
        j_start = dest_pos.y - radius
        if j_start < 0 then j_start = 0
        j_end = dest_pos.y + radius
        if j_end > rows then j_end = rows
        #echo "i: #{i_start}---#{i_end}; j: #{j_start}--#{j_end}"
        for i in [i_start .. i_end]
            for j in [j_start .. j_end]
                final_pos.x = i
                final_pos.y = j
                if not detect_occupy(final_pos,id)
                    x_dis = Math.abs(final_pos.x - dest_pos.x)
                    y_dis = Math.abs(final_pos.y - dest_pos.y)
                    distance = Math.sqrt(Math.pow(x_dis,2) + Math.pow(y_dis,2))
                    distance_list.push(distance)
                    pos_list.push(final_pos.x)
                    pos_list.push(final_pos.y)
                    #echo "#{k++},#{distance},#{final_pos.x},#{final_pos.y}"
        distance_list_sorted = distance_list.concat()
        array_sort_min2max(distance_list_sorted)

        for dis,i in distance_list
            if dis is distance_list_sorted[0]
                minest.push(i)
                #echo "#{i},#{distance_list_sorted[0]},#{pos_list[i * 2]},#{pos_list[i *2 + 1]}"
        switch minest.length
            when 0 then final_pos = coord_to_pos(dest_pos.x, dest_pos.y, width, height)
            when 1 then final_pos = coord_to_pos(pos_list[minest[0] * 2] , pos_list[minest[0] * 2 + 1],width,height)
            else final_pos = coord_to_pos(pos_list[minest[0] * 2] , pos_list[minest[0] * 2 + 1],width,height)

        distance_list.splice(0,pos_list.length)
        distance_list_sorted.splice(0,pos_list.length)
        pos_list.splice(0,pos_list.length)
        minest.splice(0,pos_list.length)
    else
        final_pos = coord_to_pos(dest_pos.x, dest_pos.y, width, height)
    final_pos = limit_in_desktop_range(final_pos)
    return final_pos


find_nearest_free_pos = (w,dest_pos,radius = _PART_) ->
    #echo "find_nearest_free_pos"
    id = w.get_id()
    return find_nearest_free_pos_id(id,dest_pos,radius)

set_item_selected = (w, change_focus = true, add_top = false) ->
    if w.selected == false
        w.is_in_select_area = true
        w.item_selected()
        if add_top == true
            selected_item.unshift(w.get_id())
        else
            selected_item.push(w.get_id())

        if change_focus
            if last_widget != w.get_id()
                if last_widget.length > 0 then Widget.look_up(last_widget)?.item_blur()
                last_widget = w.get_id()
            if not w.has_focus then w.item_focus()
    return


set_all_item_selected = ->
    for i in speical_item.concat(all_item)
        if selected_item.indexOf(i) >= 0 then continue
        w = Widget.look_up(i)
        if w? then set_item_selected(w, false)


cancel_item_selected = (w, change_focus = true) ->
    w.is_in_select_area = false
    i = selected_item.indexOf(w.get_id())
    if i < 0 then return false
    selected_item.splice(i, 1)
    w.item_normal()

    if change_focus and last_widget != w.get_id()
        if last_widget.length > 0 then Widget.look_up(last_widget)?.item_blur()
        last_widget = w.get_id()
        w.item_focus()
    return true


cancel_all_selected_stats = () ->
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

        else if selected_item.length == 1
            end_pos = pixel_to_pos(evt.clientX, evt.clientY, 1*_PART_, 1*_PART_)
            start_pos = Widget.look_up(selected_item[0]).get_pos()

            ret = compare_pos_top_left(start_pos, end_pos)
            if ret < 0
                for w_id in speical_item.concat(all_item)
                    if not (val = Widget.look_up(w_id))? then continue
                    i_pos = Widget.look_up(w_id).get_pos()
                    if compare_pos_top_left(end_pos, i_pos) >= 0 and compare_pos_top_left(start_pos, i_pos) < 0
                        set_item_selected(val, true, true)
            else if ret == 0
                cancel_item_selected(selected_item[0])
            else
                for w_id in speical_item.concat(all_item)
                    if not (val = Widget.look_up(w_id))? then continue
                    i_pos = Widget.look_up(w_id).get_pos()
                    if compare_pos_top_left(start_pos, i_pos) > 0 and compare_pos_top_left(end_pos, i_pos) <= 0
                        set_item_selected(val, true, true)

        else
            set_item_selected(w)

    else
        n = selected_item.indexOf(w.get_id())
        if n < 0
            cancel_all_selected_stats()
            set_item_selected(w)

        if n >= 0
            selected_item.splice(n, 1)
            cancel_all_selected_stats()
            selected_item.push(w.get_id())
            if last_widget != w.get_id()
                if last_widget.length > 0 then Widget.look_up(last_widget)?.item_blur()
                last_widget = w.get_id()

    update_selected_item_drag_image()
    return


# draw selected item icons DND image on special html canvas
update_selected_item_drag_image = ->
    drag_draw_delay_timer = -1

    if selected_item.length == 0 then return

    pos = Widget.look_up(selected_item[0]).get_pos()
    top_left = {x : (cols - 1), y : (rows - 1)}
    bottom_right = {x : 0, y : 0}

    for i in selected_item
        if not (w = Widget.look_up(i))? then continue
        pos = w.get_pos()

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

        pos = w.get_pos()
        pos.x -= top_left.x
        pos.y -= top_left.y

        start_x = pos.x * _GRID_WIDTH_INIT_
        start_y = pos.y * _GRID_HEIGHT_INIT_

        draw_icon_on_canvas(drag_context, start_x, start_y, w.item_icon, w.item_name.innerText)

    [drag_start.x, drag_start.y] = [top_left.x , top_left.y]
    return


is_selected_multiple_items = ->
    selected_item.length > 1


open_selected_items = ->
    Widget.look_up(i)?.item_exec() for i in selected_item
    return


delete_selected_items = (real_delete) ->
    tmp = []
    for i in selected_item
        w = Widget.look_up(i)
        if w? and w.deletable == true then tmp.push(w.get_entry())

    return if tmp.length == 0
    if real_delete then DCore.DEntry.delete_files(tmp, true)
    else DCore.DEntry.trash(tmp)
    return


show_entries_properties = (entries) ->
    try
        if (entry =  DCore.DEntry.create_by_path("/usr/bin/deepin-nautilus-properties"))?
            DCore.DEntry.launch(entry, entries)
    catch e
    return


show_selected_items_properties = ->
    tmp = []
    for i in selected_item
        if (w = Widget.look_up(i))? then tmp.push(w.get_entry())
    show_entries_properties(tmp)
    return


compress_selected_items = ->
    tmp = []
    for i in selected_item
        if (w = Widget.look_up(i))? then tmp.push(w.get_entry())
    try
        DCore.DEntry.compress_files(tmp)
    catch e
    return


decompress_selected_items = ->
    tmp = []
    for i in selected_item
        if (w = Widget.look_up(i))? then tmp.push(w.get_entry())
    try
        DCore.DEntry.decompress_files(tmp)
    catch e
    return


decompress_selected_items_here = ->
    if selected_item?
        tmp = []
        for i in selected_item
            if (w = Widget.look_up(i))? then tmp.push(w.get_entry())
        try
            DCore.DEntry.decompress_files_here(tmp)
        catch e
        return
    else
        return

get_items_compressibility = ->
    if selected_item?
        tmp = []
        for i in selected_item
            if (w = Widget.look_up(i))
                if(false == w.modifiable)
                    return 0
                else
                    tmp.push(w.get_entry())
        return DCore.DEntry.files_compressibility(tmp)
    else
        return 0



gird_left_mousedown = (evt) ->
    evt.stopPropagation()
    if evt.button == 0 and not evt.shiftKey
        if not evt.ctrlKey
            cancel_all_selected_stats()
        if last_widget.length > 0 then Widget.look_up(last_widget)?.item_blur()
    return


grid_right_click = (evt) ->
    evt.preventDefault()
    evt.stopPropagation()
    rightclick_pos.clientX = evt.clientX
    rightclick_pos.clientY = evt.clientY
    if evt.ctrlKey == false and evt.shiftKey == false
        cancel_all_selected_stats()

    submenu_sort = new Menu(
        DEEPIN_MENU_TYPE.NORMAL,
        new MenuItem(11, _("_Name")),
        new MenuItem(12, _("Last modified _time"))
    )

    submenu_new = new Menu(
        DEEPIN_MENU_TYPE.NORMAL,
        new MenuItem(20, _("_Folder")),
        new MenuItem(21, _("_Text document"))
    )
    templates_all = DCore.DEntry.get_templates_files()
    templates = DCore.DEntry.get_templates_filter(templates_all)
    if templates_all.length > 0
        submenu_new.addSeparator()
        for i in [0...templates.length] by 1
            templates_name = DCore.DEntry.get_name(templates[i])
            templates_id = i + TEMPLATES_FILE_ID_FIRST
            submenu_new.append(new MenuItem(templates_id, templates_name))

    # warning: the templates id can > 30 ,so ,the menu 3 couldnot has child menu id 31\32\33
    menu = new Menu(
        DEEPIN_MENU_TYPE.NORMAL,
        new MenuItem(1, _("_Sort by"), submenu_sort),
        new MenuItem(2, _("_New"), submenu_new),
        new MenuItem(3, _("Open in _terminal")),
        new MenuItem(4, _("_Paste")).setActive(DCore.DEntry.can_paste()),
        new MenuSeparator(),
        new MenuItem(5, _("_Display settings")),
        new MenuItem(6, _("_Corner navigation")),
        new MenuItem(7, _("Pe_rsonalize"))
    )
    menu.addListener(grid_do_itemselected).showMenu(evt.clientX, evt.clientY)
    return


grid_do_itemselected = (id) ->
    id = parseInt(id)
    echo "grid_do_itemselected id #{id}"
    switch id
        when 11 then menu_sort_desktop_item_by_name()
        when 12 then menu_sort_desktop_item_by_mtime()
        when 20 then menu_create_new_folder(name_add_before)
        when 21 then menu_create_new_file(name_add_before)
        when 3 then DCore.Desktop.run_terminal()
        when 4 then paste_from_clipboard()
        when 5
            try
                DSS_DBUS = DCore.DBus.session(DSS)
                DSS_DBUS?.ShowModule_sync("display")
            catch e
                echo "#{DSS} ERROR:#{e}"
        when 6 then DCore.Desktop.run_deepin_settings("zone")
        when 7
            try
                DSS_DBUS = DCore.DBus.session(DSS)
                DSS_DBUS?.ShowModule_sync("personalization")
            catch e
                echo "#{DSS} ERROR:#{e}"
        else
            # warning: the templates.length + TEMPLATES_FILE_ID_FIRST must < 30 .
            # if it > 30 ,and when menu 3 has child menu id 31\31\33,and this will be the same id with the templates id
            if id >= TEMPLATES_FILE_ID_FIRST && id <= templates.length + TEMPLATES_FILE_ID_FIRST
                menu_create_templates(id)
            else
                echo "not implemented function #{id}"
    return


menu_create_new_folder = (name_add_before) ->
    entry = DCore.Desktop.new_directory(name_add_before)
    create_entry_to_new_item(entry)


menu_create_new_file = (name_add_before) ->
    entry = DCore.Desktop.new_file(name_add_before)
    create_entry_to_new_item(entry)

menu_create_templates = (id) ->
    i = id - TEMPLATES_FILE_ID_FIRST
    if 0 <= i < templates.length
        entry = DCore.DEntry.create_templates(templates[i],name_add_before)
        create_entry_to_new_item(entry)
        echo "create_templates finish!"
    return


# handle up/down/left/right arrow keys to navigate between items
grid_do_keydown_to_shortcut = (evt) ->
    if rename_div_process_events then return
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
            last_widget = w_f.get_id()

        else if evt.shiftKey == true
            if selected_item.length > 1
                start_item = selected_item[0]
                selected_item.splice(0, 1)
                cancel_all_selected_stats()
                selected_item.push(start_item)

            if selected_item.length == 1
                start_pos = Widget.look_up(selected_item[0]).get_pos()
                end_pos = w_f.get_pos()
                if compare_pos_top_left(start_pos, end_pos) < 0
                    pos_a = start_pos
                    pos_b = end_pos
                else
                    pos_b = start_pos
                    pos_a = end_pos
                for i in speical_item.concat(all_item)
                    if not (w_i = Widget.look_up(i))? then continue
                    item_pos = w_i.get_pos()
                    if compare_pos_rect(pos_a, pos_b, item_pos) == true
                        set_item_selected(w_i) if not w_i.selected

                if last_widget != w_f.get_id()
                    w.item_blur() if last_widget.length > 0 and (w = Widget.look_up(last_widget))?
                    last_widget = w_f.get_id()
            else
                w_f.item_selected()
        else
            cancel_all_selected_stats()
            set_item_selected(w_f)
    return


# handle shortcuts keys
grid_do_keyup_to_shrotcut = (evt) ->
    if rename_div_process_events then return
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
    return


grid_do_keypress_to_shrotcut = (evt) ->
    if rename_div_process_events then return
    evt.stopPropagation()
    evt.preventDefault()
    if evt.keyCode == 13    # Enter
        if evt.ctrlKey == false and evt.shiftKey == false and evt.altKey == false
            if selected_item.length > 0
                Widget.look_up(last_widget)?.item_exec()
    return


create_item_grid = ->
    div_grid = document.createElement("div")
    div_grid.setAttribute("id", "item_grid")
    #echo "s_offset_x,y: " + s_offset_x + "," + s_offset_y
    update_gird_position(s_offset_x, s_offset_y, s_width, s_height)
    document.body.appendChild(div_grid)
    init_grid_drop()
    div_grid.parentElement.addEventListener("mousedown", gird_left_mousedown)
    div_grid.parentElement.addEventListener("contextmenu", grid_right_click)
    div_grid.parentElement.addEventListener("keydown", grid_do_keydown_to_shortcut)
    div_grid.parentElement.addEventListener("keyup", grid_do_keyup_to_shrotcut)
    div_grid.parentElement.addEventListener("keypress", grid_do_keypress_to_shrotcut)
    sel = new Mouse_Select_Area_box(div_grid.parentElement)

    drag_canvas = document.createElement("canvas")
    drag_context = drag_canvas.getContext('2d')
    return


class Mouse_Select_Area_box
    constructor : (parentElement) ->
        @parent_element = parentElement
        @element = document.createElement("div")
        @element.setAttribute("id", "mouse_select_area_box")
        @element.style.display = "none"
        @parent_element.appendChild(@element)
        @parent_element.addEventListener("mousedown", @mousedown_event)

    destory : =>
        @parent_element.removeChild(@element)

    mousedown_event : (evt) =>
        evt.stopPropagation()
        evt.preventDefault()
        if evt.button == 0
            @parent_element.addEventListener("mousemove", @mousemove_event)
            @parent_element.addEventListener("mouseup", @mouseup_event)
            @parent_element.addEventListener("contextmenu", @contextmenu_event, true)
            @start_point = evt
            @start_pos = pixel_to_pos(evt.clientX, evt.clientY, 1*_PART_, 1*_PART_)
            @last_pos = @start_pos
            @total_item = speical_item.concat(all_item)

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
        @element.style.display = "block"

        new_pos = pixel_to_pos(evt.clientX, evt.clientY, 1*_PART_, 1*_PART_)

        for i in @total_item
            if not (w = Widget.look_up(i))? then continue
            item_pos = w.get_pos()
            if compare_pos_rect(new_pos, @start_pos, item_pos) == true
                if not w.selected and not w.is_in_select_area
                    set_item_selected(w)
                else
                    if not w.is_in_select_area
                        cancel_item_selected(w)
                        w.is_in_select_area = true
            else
                w.is_in_select_area = false
                if w.selected == true and not w.ctrl_selected
                    cancel_item_selected(w)
                else if w.ctrl_selected and w.ctrlKey
                    set_item_selected(w)
        return


    mouseup_event : (evt) =>
        evt.stopPropagation()
        evt.preventDefault()
        for i in @total_item
            if not (w = Widget.look_up(i))? then continue
            w.is_in_select_area = false
            w.ctrl_selected = w.selected
        @parent_element.removeEventListener("mousemove", @mousemove_event)
        @parent_element.removeEventListener("mouseup", @mouseup_event)
        @parent_element.removeEventListener("contextmenu", @contextmenu_event, true)
        @element.style.display = "none"

        if selected_item.length > 0 then update_selected_item_drag_image()
        return

# fullscreen div for item renaming
rename_div_process_events = false
item_rename_div = document.createElement("div")
item_rename_div.setAttribute("class", "pop_rename")
item_rename_div.style.display = "none"
document.body.appendChild(item_rename_div)
item_rename_div.addEventListener("mousedown", (evt) ->
        evt.stopPropagation()
        return
)
item_rename_div.addEventListener("mouseup", (evt) ->
        evt.stopPropagation()
        return
)
item_rename_div.addEventListener("click", (evt) ->
        evt.stopPropagation()
        if @id.length?
            if (w = Widget.look_up(@id))?
                w.item_complete_rename(true)
        return
)
item_rename_div.addEventListener("contextmenu", (evt) ->
        evt.stopPropagation()
        if @id.length?
            if (w = Widget.look_up(@id))?
                w.item_complete_rename(true)
        return
)

item_rename_div.parentElement.addEventListener("keydown", (evt) ->
        if not rename_div_process_events then return
        evt.stopPropagation()
        if @id.length?
            if (w = Widget.look_up(@id))?
                w.on_item_rename_keydown(evt)
        return
)
item_rename_div.parentElement.addEventListener("keypress", (evt) ->
        if  not rename_div_process_events then return
        evt.stopPropagation()
        if @id.length?
            if (w = Widget.look_up(@id))?
                w.on_item_rename_keypress(evt)
        return
)
item_rename_div.parentElement.addEventListener("keyup", (evt) ->
        if  not rename_div_process_events then return
        evt.stopPropagation()
        if @id.length?
            if (w = Widget.look_up(@id))?
                w.on_item_rename_keyup(evt)
        return
)


move_widget_to_rename_div = (w) ->
    if rename_div_process_events == true then return
    #w.element.style.left = "#{jQuery(w.element).offset().left}px"
    #w.element.style.top = "#{jQuery(w.element).offset().top}px"
    w.element.style.left = "#{w.element.offsetLeft + s_offset_x - 1}px"
    w.element.style.top = "#{w.element.offsetTop + s_offset_y - 1 + 10}px"
    div_grid.removeChild(w.element)
    item_rename_div.appendChild(w.element)
    item_rename_div.setAttribute("id", w.get_id())
    item_rename_div.style.zIndex = 50
    #w.style.zIndex = 60
    item_rename_div.focus()
    item_rename_div.style.display = "block"
    rename_div_process_events = true
    return


move_widget_to_grid_after_rename = (w) ->
    if rename_div_process_events == false then return
    #w.element.style.left = "#{jQuery(w.element).offset().left}px"
    #w.element.style.top = "#{jQuery(w.element).offset().top}px"
    w.element.style.left = "#{w.element.offsetLeft - s_offset_x - 1}px"
    w.element.style.top = "#{w.element.offsetTop - s_offset_y - 1 - 10}px"
    item_rename_div.removeChild(w.element)
    div_grid.appendChild(w.element)
    item_rename_div.style.zIndex = 0
    #w.style.zIndex = 0
    item_rename_div.blur()
    item_rename_div.style.display = "none"
    rename_div_process_events = false
    return

set_version_desktop = (version)->
    check = true
    check  = DCore.Desktop.check_version_equal_set(version)
    if check is false
        localStorage.clear()
