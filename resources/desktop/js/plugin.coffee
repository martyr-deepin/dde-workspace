class DesktopPluginItem extends Widget
    constructor: (@id)->
        super
        document.getElementById("item_grid").appendChild(@element)

class DesktopPlugin extends Plugin
    constructor: (@path, @name)->
        @host = new DesktopPluginItem().element
        super(@path, @name, @host)

load_plugins = ->
    for p in DCore.get_plugins("desktop")
        new DesktopPlugin(get_path_base(p), get_path_name(p))

#this should put in main.coffee when everything is ok
load_plugins()
