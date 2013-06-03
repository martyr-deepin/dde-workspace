class PluginManager
    # key: plugin's name
    # value: Plugin class
    @_plugins: null

    constructor: ->
        PluginManager._plugins = {} if not PluginManager._plugins

    enable_plugin: (id, value)->
        double_name = get_path_name(id)
        name = double_name.substring(double_name.length / 2)
        DCore.enable_plugin(name, value)
        plugin = PluginManager._plugins[name]
        if plugin
            if value
                echo "enable #{name}"
                plugin.inject_css(name)
            else
                echo "disable #{name}"
                plugin.destroy()
                echo delete PluginManager._plugins[name]
                PluginManager._plugins[name] = null
        else
            echo 'plugin is not exists'

    get_plugin: (name) ->
        PluginManager._plugins[name]

    add_plugin: (name, obj) ->
        PluginManager._plugins[name] = obj

    @plugin_changed_handler: (info) ->
        all_plugins = DCore.get_plugins('desktop')

        for plugin in all_plugins
            base = get_path_base(plugin)
            name = get_path_name(plugin)
            id = "plugin:" + base + name
            if info[name]
                echo 'plugin_changed_handler: enable plugin'
                if not PluginManager._plugins or not PluginManager._plugins[name]
                    new DesktopPlugin(base, name)
                    plugin_manager.enable_plugin(id, true)
            else
                echo 'plugin_changed_handler: disable plugin'
                plugin_manager.enable_plugin(id, false)
        return


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

DCore.signal_connect("plugins_changed", PluginManager.plugin_changed_handler)
