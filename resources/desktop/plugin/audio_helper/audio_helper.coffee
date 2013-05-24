class Lines extends Widget
    constructor: (@id)->
        super

        @current_value = 0

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
        @lines.reverse()

    create_line: (width)->
        line = create_element("div", "line", @element)
        line.style.width = width
        return line

    active_line: (n)->
        return if n > @lines.length
        if n > @current_value
            while n > @current_value
                @lines[@current_value++].style.background = "#10fdfb"
        else if n < @current_value
            while n < @current_value
                @lines[@current_value--].style.background = "white"
        @current_value = clamp(n, 0, @lines.length-1)


class AudioHelper extends Widget
    constructor: (@id) ->
        super
        #@img = create_img("running", "#{_plugin.path}/running.png", @element)
        @element.style.background = "url(#{_plugin.path}/static.png)"
        @lines = new Lines()
        @element.appendChild(@lines.element)
        @active_id = -1
    do_click: (e)->
        @lines.active_line(e.detail - 1)



_plugin.inject_css("audio_helper")
_plugin.wrap_element(new AudioHelper(_plugin.id).element)
_plugin.set_pos(
    x: 5
    y: 0
    width: 2
    height: 2
)
