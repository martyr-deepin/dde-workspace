get_name = (id) ->
    index = id.lastIndexOf(':')
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

    enable_plugin_front: (id, value) ->
        name = get_name(id)
        echo "plugin's name: #{name}"
        plugin = PluginManager._plugins[name]
        if plugin
            if value
                echo "enable #{id}"
                plugin.inject_css(name)
            else
                echo "disable #{id}"
                plugin.destroy()
                delete PluginManager._plugins[name]
                PluginManager._plugins[name] = null
        else
            echo "plugin #{id} does not exists"

    get_plugin: (name) ->
        PluginManager._plugins[name]

    add_plugin: (name, obj) ->
        PluginManager._plugins[name] = obj

    @plugin_changed_handler: (info) ->
        id_prefix = info.app_name + ":"
        all_plugins = DCore.get_plugins(info.app_name)
        delete info.app_name

        for plugin in all_plugins
            name = get_path_name(plugin)
            id = id_prefix + name
            if info[id]
                delete info[id]
                if not PluginManager._plugins or not PluginManager._plugins[name]
                    if id_prefix == 'desktop:'
                        new DesktopPlugin(get_path_base(plugin), name)
                        echo "id: #{id}"
                        plugin_manager.enable_plugin_front(id, true)
                        place_all_widgets()

        for own k, v of info
            plugin_manager.enable_plugin_front(k, false)

        return


class Plugin
    constructor: (@app_name, @path, @name, @host)->
        @id = @app_name + ':' + @name
        window.plugin_manager = new PluginManager() unless window.plugin_manager
        window.plugin_manager.add_plugin(@name, @)
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
