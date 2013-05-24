class Lines extends Widget
    constructor: (@id)->
        super
        MIN_WIDTH = 14
        MID_WIDTH = 16
        BIG_WIDTH = 18
        HUGE_WIDTH = 20
        @lines = []
        @lines.push(@create_line(MIN_WIDTH))
        @lines.push(@create_line(MID_WIDTH))
        @lines.push(@create_line(MIN_WIDTH))
        @lines.push(@create_line(BIG_WIDTH))
        @lines.push(@create_line(MIN_WIDTH))
        @lines.push(@create_line(HUGE_WIDTH))
        @lines.push(@create_line(BIG_WIDTH))
        @lines.push(@create_line(MIN_WIDTH))

    create_line: (width)->
        line = create_element("div", "line", @element)
        line.style.width = width
        return line

    active_line: ->
        for line, i in @lines
            line.style.webkitAnimation = "blink #{i+1 / 2.0}s linear infinite"



class AudioHelper extends Widget
    constructor: (@id) ->
        super
        @img = create_img("running", "#{_plugin.path}/running.png", @element)
        @element.style.background = "url(#{_plugin.path}/static.png)"
        @lines = new Lines()
        @element.appendChild(@lines.element)
        @active_id = -1
    do_click: (e)->
        @lines.active_line()



_plugin.inject_css("audio_helper")
_plugin.wrap_element(new AudioHelper(_plugin.id).element)
