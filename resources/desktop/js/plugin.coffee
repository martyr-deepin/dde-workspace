class DesktopPluginItem extends Widget
    constructor: (@id)->
        super
        @_position = {x:-1, y:-1, width:1, height:1}
        attach_item_to_grid(@)
        widget_item.push(@id)


    get_id : =>
        @id


    get_pos : =>
        ret_pos = {x : @_position.x, y : @_position.y, width : @_position.width, height : @_position.height}


    set_pos : (info) =>
        [@_position.x, @_position.y, @_position.width, @_position.height] = [info.x, info.y, info.width, info.height]
        return


    move: (x, y) =>
        style = @element.style
        style.position = "absolute"
        style.left = x
        style.top = y


class DesktopPlugin extends Plugin
    constructor: (@path, @name)->
        @host = new DesktopPluginItem(@name).element
        super(@path, @name, @host)


load_plugins = ->
    for p in DCore.get_plugins("desktop")
        w = new DesktopPlugin(get_path_base(p), get_path_name(p))
    return
