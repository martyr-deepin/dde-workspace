#Copyright (c) 2011 ~ 2012 Deepin, Inc.
#Author:      yuanjq <yuanjq91@gmail.com>

class DesktopPlugin extends Widget
    @relative_x = 0
    @relative_y = 0
    constructor : (name, x, y, width, height) ->
        @set_id()
        pos = {x:0, y:0, width:0, height:0}
        pos.x = x
        pos.y = y
        pos.width = width
        pos.height = height
        super(@id)
        @element.draggable = true
        return

    set_id : =>
        @id = "gadget"

    get_id : =>
        @id
        
    do_mousedown : (evt) ->
        evt.stopPropagation()
        cancel_all_selected_stats()
        return

    do_dragstart : (evt) =>
        evt.stopPropagation()
        desktop_plugin_dragstart_handler(this, evt)
        return

    do_dragend : (evt) ->
        evt.stopPropagation()
        evt.preventDefault()
        desktop_plugin_dragend_handler(this, evt)
        return

    do_rightclick : (evt) ->
        evt.stopPropagation()
        evt.preventDefault()
        return

    move: (x, y) =>
        style = @element.style
        style.position = "absolute"
        style.left = x
        style.top = y
        return

