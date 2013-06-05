class Clock extends Widget
    constructor: (@id)->
        super
        @face = create_img("ClockFace", "#{plugin.path}/clockface.png", @element)
        @sec = create_img("HandleSec", "#{plugin.path}/sechand.png", @element)
        @min= create_img("HandleMin", "#{plugin.path}/minhand.png", @element)
        @hour = create_img("HandleHour", "#{plugin.path}/hourhand.png", @element)

        @update_look()
        setInterval(=>
            @update_look()
        , 1000)

    update_look: ->
        date = new Date()
        srotate = "rotate(#{date.getSeconds() * 6}deg)"
        mrotate = "rotate(#{date.getMinutes() * 6}deg)"
        hrotate = "rotate(#{date.getHours() * 30 + date.getMinutes() / 2}deg)"

        @sec.style.webkitTransform = srotate
        @min.style.webkitTransform = mrotate
        @hour.style.webkitTransform = hrotate

plugin = window.plugin_manager.get_plugin("clock")
plugin.inject_css("clock")
plugin.wrap_element(new Clock(plugin.id).element, 2, 2)
