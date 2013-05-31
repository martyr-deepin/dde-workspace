class PluginHandle extends Widget
    constructor : (@parent_id) ->
        @id = "handle-#{@parent_id}"
        super(@id)
        @element.setAttribute("draggable", "true")


    do_dragstart : (evt) =>
        evt.stopPropagation()
        _SET_DND_INTERNAL_FLAG_(evt)


    do_dragend : (evt) =>
        evt.stopPropagation()
        if not (w = Widget.look_up(@parent_id))? then return
        old_pos = w.get_pos()
        new_pos = pixel_to_pos(evt.clientX, evt.clientY, old_pos.width, old_pos.height)
        if not detect_occupy(new_pos)
            move_to_somewhere(w, new_pos)


class DesktopPluginItem extends Widget
    constructor: (@id)->
        super
        @_position = {x:-1, y:-1, width:1, height:1}
        widget_item.push(@id)
        attach_item_to_grid(@)
        @handle = new PluginHandle(@id)
        @element.appendChild(@handle.element)


    get_id : =>
        @id


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
        return


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


class DesktopPlugin extends Plugin
    constructor: (@path, @name)->
        @item = new DesktopPluginItem(@name)
        super(@path, @name, @item.element)


    set_pos: (info)->
        move_to_somewhere(@item, info)


    wrap_element: (child, width, height)->
        super(child)
        pos = @item.get_pos()
        pos.width = width
        pos.height = height
        @item.set_size(pos)


load_plugins = ->
    for p in DCore.get_plugins("desktop")
        new DesktopPlugin(get_path_base(p), get_path_name(p))
    return


find_free_position_for_widget = (info) ->
    new_pos = {x : 0, y : 0, width : info.width, height : info.height}
    x_pos = cols - 1
    while (x_pos = x_pos - info.width + 1) > -1
        new_pos.x = x_pos
        for i in [0 ... (rows - info.height)]
            new_pos.y = i
            if not detect_occupy(new_pos)
                return new_pos
    return null


place_all_widgets = ->
    for i in widget_item
        continue if not (w = Widget.look_up(i))?
        if not load_position(i)? and (new_pos = find_free_position_for_widget(w.get_pos()))?
            echo new_pos
            move_to_somewhere(w, new_pos)
        else
            move_to_anywhere(w)
    return
