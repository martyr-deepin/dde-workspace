#Copyright (c) 2011 ~ 2012 Deepin, Inc.
#Author:      yuanjq <yuanjq91@gmail.com>

class Gadget extends Widget
    constructor : (name, x, y, width, height) ->
        @set_id()
        super(@id)
        @element.draggable = true
        @pos = {x:0, y:0, width:0, height:0}
        @set_pos(x, y, width, height)
        return

    set_id : =>
        @id = "gadget"

    get_id : =>
        @id

    set_pos : (x, y, width, height) =>
        @pos.x = x
        @pos.y = y
        @pos.width = width
        @pos.height = height

    get_pos : =>
        @pos

    do_mousedown : (evt) ->
        evt.stopPropagation()
        cancel_all_selected_stats()
        return

    do_dragstart : (evt) =>
        evt.stopPropagation()
        gadget_dragstart_handler(this, evt)
        return

    do_dragend : (evt) ->
        evt.stopPropagation()
        evt.preventDefault()
        gadget_dragend_handler(this, evt)
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

