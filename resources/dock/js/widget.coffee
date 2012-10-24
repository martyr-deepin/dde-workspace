class Widget extends Module
    @object_table = {}
    @look_up = (id) ->
        @object_table[id]

    constructor: ->
        el = document.createElement('div')
        el.setAttribute('class',  @constructor.name)
        el.id = @id
        #document.body.appendChild(el)
        @element = el
        Widget.object_table[@id] = this

    destroy: ->
        @element.parentElement.removeChild(@element)
        delete Widget.object_table[@id]

    move: (x, y) ->
        style = @element.style
        style.position = "absolute"
        style.left = x
        style.top = y
