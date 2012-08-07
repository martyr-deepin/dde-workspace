class Widget extends Module
    _$: ->
        $("##{@id}")

    get_id: ->
        @id
    set_id: (id) ->
        @id = id

    get_x: ->
        @get_position()[0]
    set_x: (x)->
        @set_position(x, -1)

    get_y: ->
        @get_position()[1]
    set_y: (y)->
        @set_position(-1, y)

    get_width: ->
        @_$().outerWidth()

    get_height: ->
        @_$().outerHeight()

    get_position: ->
        node = @_$()[0]
        return pixel_to_position(
            node.style.left.replace("px", ""),
            node.style.top.replace("px", "")
        )

    set_position: (x, y) ->
        x = this.get_x() if x == -1
        y = this.get_y() if y == -1
        node = @_$()[0]
        move_to_position(node, x, y)
