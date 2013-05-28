class Lines extends Widget
    constructor: (@id)->
        super

        @current_value = 0
        _widths = [5, 7, 9, 13, 15, 17]

        @lines = []
        @lines.push(@create_line(_widths[0]))
        @lines.push(@create_line(_widths[2]))
        @lines.push(@create_line(_widths[1]))
        @lines.push(@create_line(_widths[4]))
        @lines.push(@create_line(_widths[3]))
        @lines.push(@create_line(_widths[4]))
        @lines.push(@create_line(_widths[2]))
        @lines.push(@create_line(_widths[5]))
        @lines.push(@create_line(_widths[3]))
        @lines.push(@create_line(_widths[5]))
        @lines.push(@create_line(_widths[3]))
        @lines.push(@create_line(_widths[1]))
        @adjust_lines()

    adjust_lines: ->
        for l, i in @lines
            l.style.opacity = 0.2 + i * 1.0 / @lines.length
        @lines.reverse()

    create_line: (width)->
        line = create_element("div", "line", @element)
        line.style.width = width
        return line

    active_line: (n)->
        return if n > @lines.length
        if n > @current_value
            while n > @current_value
                @lines[@current_value++].style.background = "#23fff8"
        else if n < @current_value
            while n < @current_value
                @lines[@current_value--].style.background = "rgba(0,0,0,0)"
        @current_value = clamp(n, 0, @lines.length-1)


class AudioHelper extends Widget
    constructor: (@id) ->
        super
        @running = create_img("running", "#{plugin.path}/running.png", @element)
        @lighter = create_img("light", "#{plugin.path}/light.png", @element)
        @element.style.background = "url(#{plugin.path}/static.png)"
        @lines = new Lines()
        @element.appendChild(@lines.element)
        @dbus_init()
    do_click: (e)->
        @lines.active_line(e.detail - 1)
    dbus_init: ->
        try
            @dbus = DCore.DBus.session("com.deepin.speech")
        @dbus.connect("RecordStart", =>
            @lighter.style.display = "block"
            @running.style.display = "none"
            echo "recordstart"
        )
        @dbus.connect("RecordEnd", =>
            @lighter.style.display = "none"
            @running.style.display = "none"
            echo "recordend"
        )
        @dbus.connect("ParseStart", =>
            @lighter.style.display = "none"
            @running.style.display = "block"
            echo "parsestart"
        )
        @dbus.connect("ParseEnd", =>
            @lighter.style.display = "none"
            @running.style.display = "none"
            echo "parseend"
        )



plugin = window._plugins["audio_helper"]
plugin.inject_css("audio_helper")
plugin.wrap_element(new AudioHelper(plugin.id).element)
plugin.set_pos(
    x: 4
    y: 0
    width: 2
    height: 2
)
