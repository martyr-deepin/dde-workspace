class PluginManager
    enable_plugin: (id, value)->

class Plugin
    constructor: (@path, @name, @host)->
        window._plugin = @
        @inject_js(@name)
        @id = "plugin:" + @path + @name

    wrap_element: (child)->
        @host.appendChild(child)

    inject_js: (name) ->
        @js_element = create_element("script", null, @host)
        @js_element.src = "#{@path}/#{name}.js"

    inject_css: (name)->
        @css_element = create_element('link', null, @host)
        @css_element.rel = "stylesheet"
        @css_element.href = "#{@path}/#{name}.css"
