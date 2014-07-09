#Copyright (c) 2012 ~ 2014 Deepin, Inc.
#              2012 ~ 2014 bluth
#
#Author:      bluth <yuanchenglu001@gmail.com>
#
#Maintainer:  bluth <yuanchenglu001@gmail.com>
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

class PluginHandle extends Widget
    IMG_URL_PRESS = "../img/plugin/Press"
    widget_drag_canvas = document.createElement("canvas")
    widget_drag_context = widget_drag_canvas.getContext('2d')

    constructor : (@parent_id) ->
        @id = "handle-#{@parent_id}"
        super(@id)
        @element.setAttribute("draggable", "true")
        @offset_pos = {x : -1 * _PART_, y : -1 * _PART_}

        @plugin_close = create_element("div","plugin_close",@element)
        @plugin_close.addEventListener("click",(evt)=>
            @plugin_close.style.backgroundImage = IMG_URL_PRESS + "/window_close_press.png"
            if not (w = Widget.look_up(@parent_id))? then return
            delete_widget(w)
            )

    do_mouseover : (evt) =>
        if not (w = Widget.look_up(@parent_id))? then return
        w.add_css_class("plugin_hover_border")
        return


    do_mouseout : (evt) =>
        if not (w = Widget.look_up(@parent_id))? then return
        w.remove_css_class("plugin_hover_border")
        return


    do_dragstart : (evt) =>
        evt.stopPropagation()
        _SET_DND_INTERNAL_FLAG_(evt)
        evt.dataTransfer.effectAllowed = "all"

        drag_pos = pixel_to_pos(evt.clientX, evt.clientY, 1 * _PART_, 1 * _PART_)
        @offset_pos.x = drag_pos.x
        @offset_pos.y = drag_pos.y
        if not (w = Widget.look_up(@parent_id))? then return
        w.add_css_class("plugin_DND_border")

        parent = @element.parentElement
        offset_x = evt.clientX - parent.offsetLeft
        offset_y = evt.clientY - parent.offsetTop
        widget_drag_canvas.width = parent.offsetWidth
        widget_drag_canvas.height = parent.offsetHeight
        widget_drag_context.strokeStyle = "rgba(0, 0, 0, 0.5)"
        widget_drag_context.strokeRect(1,1,widget_drag_canvas.width - 2,widget_drag_canvas.height - 2)
        widget_drag_context.fillStyle = "rgba(255, 255, 255, 0.3)"
        widget_drag_context.fillRect(1,1,widget_drag_canvas.width - 2,widget_drag_canvas.height - 2)
        evt.dataTransfer.setDragCanvas(widget_drag_canvas, offset_x, offset_y)
        return


    do_dragend : (evt) =>
        evt.stopPropagation()

        if not (w = Widget.look_up(@parent_id))? then return
        w.remove_css_class("plugin_DND_border")
        if evt.dataTransfer.dropEffect != "link" then return
        old_pos = w.get_pos()
        new_pos = pixel_to_pos(evt.clientX, evt.clientY, old_pos.width, old_pos.height)
        new_pos.x -= (@offset_pos.x - old_pos.x)
        new_pos.x = 0 if new_pos.x < 0
        new_pos.y -= (@offset_pos.y - old_pos.y)
        new_pos.y = 0 if new_pos.y < 0
        if not detect_occupy(new_pos, @parent_id)
            move_to_somewhere(w, new_pos)
        return

    do_click:(evt)=>
        evt.stopPropagation()
        echo @element

    destroy:->
        echo "PluginHandle destroy"
        remove_element(@element)

class DesktopPluginItem extends Widget
    constructor: (@id)->
        super
        @_position = {x:-1 * _PART_, y:-1 * _PART_, width:1 * _PART_, height:1 * _PART_}
        widget_item.push(@id)
        attach_item_to_grid(@)
        @handle = new PluginHandle(@id)
        @element.appendChild(@handle.element)
        @container = create_element("div", "PluginContainer", @element)


    get_id : =>
        @id


    set_plugin : (id) =>
        @plugin_id = id


    get_plugin : =>
        @plugin_id


    get_pos : =>
        x : @_position.x
        y : @_position.y
        width : @_position.width
        height : @_position.height


    set_pos : (info) =>
        @_position.x = info.x
        @_position.y = info.y
        return


    set_size : (info) =>
        @_position.width = info.width
        @_position.height = info.height
        real_width = @_position.width * _GRID_WIDTH_INIT_
        real_height = @_position.height * _GRID_HEIGHT_INIT_
        @element.style.width = "#{real_width}px"
        @element.style.height = "#{real_height}px"
        real_height = real_height - @handle.element.offsetHeight
        @container.style.width = "#{real_width}px"
        @container.style.height = "#{real_height}px"
        return


    do_mousedown : (evt) ->
        evt.stopPropagation()
        return


    do_click : (evt) ->
        evt.stopPropagation()
        return


    do_mouseup : (evt) ->
        evt.stopPropagation()
        return


    do_rightclick : (evt) ->
        evt.stopPropagation()
        evt.preventDefault()
        return


    do_buildmenu : (evt) ->
        []


    do_keydown : (evt) ->
        evt.stopPropagation()
        return


    do_keypress : (evt) ->
        evt.stopPropagation()
        return


    do_keyup : (evt) ->
        evt.stopPropagation()
        return


    move: (x, y) =>
        style = @element.style
        style.position = "absolute"
        style.left = x
        style.top = y


    destroy:->
        echo "DesktopPluginItem destroy"
        remove_element(@element)
        #@handle.destroy()


class DesktopPlugin extends Plugin
    constructor: (@path, @name)->
        @item = new DesktopPluginItem(@name)
        super('desktop', @path, @name, @item.container)
        @item.set_plugin(@id)
        pos = @item.get_pos()
        pos.height = @info.height
        pos.width = @info.width
        @item.set_size(pos)
        echo @item.get_id()
        if not load_position(@item.get_id())?
            echo "init position"
            if @info.x?
                if @info.x < 0
                    pos.x = cols + @info.x - @info.width + 1
                else
                    pos.x = if (cols - @info.x ) < @info.width then (cols - @info.width + 1) else @info.x
            if @info.y?
                if @info.y < 0
                    pos.y = rows + @info.y - @info.height + 1
                else
                    pos.y = if (rows - @info.y ) < @info.height then (rows - @info.height + 1) else @info.y
            if @info.x? or @info.y?
                save_position(@item.get_id(),pos)

    destroy:->
        echo "DesktopPlugin destory"
        @item.destroy()

    set_pos: (info)->
        move_to_somewhere(@item, info)


load_plugins = ->
    DCore.init_plugins('desktop')
    for p in DCore.get_plugins("desktop")
        new DesktopPlugin(get_path_base(p), get_path_name(p))
    return


find_free_position_for_widget = (info, id = null) ->
    new_pos = {x : -1 * _PART_, y : -1 * _PART_, width : info.width, height : info.height}
    x_pos = cols - 1
    while (x_pos = x_pos - info.width + 1) > -1
        new_pos.x = x_pos
        for i in [0 ... (rows - info.height)] by 1
            new_pos.y = i
            if not detect_occupy(new_pos, id)
                return new_pos
    return null


place_all_widgets = ->
    not_found = new Array
    for i in widget_item
        if not (pos = load_position(i))?
            not_found.push(i)
        else
            continue if not (w = Widget.look_up(i))?
            move_to_anywhere(w)

    for i in not_found
        continue if not (w = Widget.look_up(i))?
        if (new_pos = find_free_position_for_widget(w.get_pos(), w.get_id()))?
            move_to_somewhere(w, new_pos)

    return
