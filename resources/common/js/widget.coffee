_events = [
    'blur',
    'change',
    'click',
    'contextmenu',
    'copy',
    'cut',
    'dblclick',
    'error',
    'focus',
    'keydown',
    'keypress',
    'keyup',
    'mousedown',
    'mousemove',
    'mouseout',
    'mouseover',
    'mouseup',
    'mousewheel',
    'paste',
    'reset',
    'resize',
    'scroll',
    'select',
    'submit',
    'DOMActivate',
    'DOMAttrModified',
    'DOMCharacterDataModified',
    'DOMFocusIn',
    'DOMFocusOut',
    'DOMMouseScroll',
    'DOMNodeInserted',
    'DOMNodeRemoved',
    'DOMSubtreeModified',
    'textInput'
]


class Widget extends Module
    @object_table = {}
    @look_up = (id) ->
        @object_table[id]

    constructor: ->
        el = document.createElement('div')
        el.setAttribute('class',  @constructor.name)
        el.id = @id
        @element = el
        Widget.object_table[@id] = this

        #there has an strange bug when use indexof instead search,
        # the key value will always be "construcotr" without any other thing
        for k,v of this.constructor.prototype when k.search("do_") == 0
            key = k.substr(3)
            if key in _events
                @element.addEventListener(key, v.bind(this))
            else
                echo "found the do_ prefix but the name #{key} is not an dom events"

    destroy: ->
        @element.parentElement?.removeChild(@element)
        delete Widget.object_table[@id]
