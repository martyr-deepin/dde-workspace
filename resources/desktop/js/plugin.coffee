class PluginHandle extends Widget


class DesktopPluginItem extends Widget
    constructor: (@id)->
        super
        @_position = {x:-1, y:-1, width:1, height:1}
        attach_item_to_grid(@)
        widget_item.push(@id)
        @handle = new PluginHandle("handle"+@id)
        @element.appendChild(@handle.element)


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
        @_position.width = info.width
        @_position.height = info.height
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
        @item.set_pos(info)
        move_to_somewhere(@item, info)


load_plugins = ->
    for p in DCore.get_plugins("desktop")
        new DesktopPlugin(get_path_base(p), get_path_name(p))
    return
