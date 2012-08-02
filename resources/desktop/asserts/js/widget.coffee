class Widget extends Module
    _$: ->
        $("##{@id}")

    get_id: ->
        @id
    set_id: (id) ->
        @id = id

    get_x: ->
        node = @_$()[0]
        return node.style.left
    set_x: (x)->
        @set_position(x, -1)

    get_y: ->
        node = @_$()[0]
        return node.style.top
    set_y: (y)->
        @set_position(-1, y)

    get_width: ->
        @_$().outerWidth()

    get_height: ->
        @_$().outerHeight()

    get_position: ->
        node = @_$()[0]
        [node.style.left, node.style.top]

    set_position: (x, y) ->
        x = this.get_x() if x == -1
        y = this.get_y() if y == -1
        node = @_$()[0]
        node.style.position = "fixed"
        node.style.left = x
        node.style.top = y
