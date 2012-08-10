class Widget extends Module
    @object_table = {}
    @look_up = (id) ->
        @object_table[id]

    constructor: ->
        #old_el = Widget.look_up(@id)
        #if old_el?
            #@element = old_el
            #return

        el = document.createElement('div')
        el.setAttribute('class',  @constructor.name)
        el.id = @id
        document.body.appendChild(el)
        @element = el
        Widget.object_table[@id] = this

    destroy: ->
        document.body.removeChild(@element)
        delete Widget.object_table[@id]

    move: (x, y) ->
        style = @element.style
        style.position = "fixed"
        style.left = x
        style.top = y
