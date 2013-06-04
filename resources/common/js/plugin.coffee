get_name = (id) ->
    index = id.indexOf(':')
    if index == -1
        return id
    else
        id.substring(index + 1)

class PluginManager
    # key: plugin's name
    # value: Plugin class
    @_plugins: null

    constructor: ->
        PluginManager._plugins = {} if not PluginManager._plugins

    enable_plugin: (id, value)->
        DCore.enable_plugin(id, value)
        name = get_name(id)
        plugin = PluginManager._plugins[id]
        if plugin
            if value
                echo "enable #{id}"
                plugin.inject_css(name)
            else
                echo "disable #{id}"
                plugin.destroy()
                echo delete PluginManager._plugins[id]
                PluginManager._plugins[id] = null
        else
            echo 'plugin is not exists'

    get_plugin: (id) ->
        PluginManager._plugins[id]

    add_plugin: (id, obj) ->
        PluginManager._plugins[id] = obj

    @plugin_changed_handler: (info) ->
        all_plugins = DCore.get_plugins('desktop')

        id_prefix = info.app_name + ":"
        delete info.app_name
        for own k, v of info
            id = id_prefix + k
            echo id
            if not v
                echo 'plugin_changed_handler: disable plugin'
                plugin_manager.enable_plugin(id, false)
        for plugin in all_plugins
            name = get_path_name(plugin)
            id = id_prefix + name
            if info[name]
                echo 'plugin_changed_handler: enable plugin'
                if not PluginManager._plugins or not PluginManager._plugins[id]
                    new DesktopPlugin(get_path_base(plugin), name)
                    echo 'enable created plugin'
                    plugin_manager.enable_plugin(id, true)
            else
        return


class Plugin
    constructor: (@app_name, @path, @name, @host)->
        @id = @app_name + ':' + @name
        window.plugin_manager = new PluginManager() unless window.plugin_manager
        window.plugin_manager.add_plugin(@id, @)
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

DCore.signal_connect("plugins_changed", PluginManager.plugin_changed_handler)
