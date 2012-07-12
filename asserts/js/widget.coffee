class Widget extends Module
    _$: ->
        $("##{@id}")

    get_id: ->
        @id
    set_id: (id) ->
        @id = id

    get_x: ->
        @_$().position().left
    set_x: (x)->
        @set_position(x, -1)

    get_y: ->
        @_$().position().top
    set_y: (y)->
        @set_position(-1, y)

    get_width: ->
        @_$().outerWidth()

    get_height: ->
        @_$().outerHeight()

    get_position: ->
        pos = @_$().position()
        [pos.top, pos.left]

    set_position: (x, y) ->
        x = this.get_x() if x == -1
        y = this.get_y() if y == -1
        @_$().position
            of: @_$().parent()
            my: "left top"
            at: "left top"
            offset: "#{x} #{y}"
