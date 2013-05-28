class PluginManager
    # key: plugin's name
    # value: Plugin class
    _plugins: null

    constructor: ->
        PluginManager._plugins = {} if not PluginManager._plugins

    enable_plugin: (id, value)->
        DCore.Desktop.enable_plugin(id, value)

    get_plugin: (name) ->
        PluginManager._plugins[name]

    add_plugin: (name, obj) ->
        PluginManager._plugins[name] = obj
        @enable_plugin(obj.id, true)


class Plugin
    constructor: (@path, @name, @host)->
        @id = "plugin:" + @path + @name
        window.plugin_manager = new PluginManager() unless window.plugin_manager
        window.plugin_manager.add_plugin(@name, @)
        # window._plugins = {} if not window._plugins
        # window._plugins[@name] = @
        @inject_js(@name)


    wrap_element: (child)->
        @host.appendChild(child)

    inject_js: (name) ->
        @js_element = create_element("script", null, document.body)
        @js_element.src = "#{@path}/#{name}.js"

    inject_css: (name)->
        @css_element = create_element('link', null, @host)
        @css_element.rel = "stylesheet"
        @css_element.href = "#{@path}/#{name}.css"
