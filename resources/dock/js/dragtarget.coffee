class DragTarget
    constructor: (@target)->
        @dragToBack = true
        @el = @target.element
        @indicator = @el.nextSibling
        @parentNode = @el.parentNode
        @img = @target.img.cloneNode(true)
        _b.appendChild(@img)
        @img.style.position = 'absolute'
        @img.style.display = 'none'
        @img.style.opacity = '0.3'
        @img.addEventListener('webkitTransitionEnd', (e)=>
            @removeImg()
        )

    removeImg: =>
        try
            @img.parentNode.removeChild(@img)
        @img = null

    setOrigin:(x, y)->
        console.log("#{x}, #{y}")
        @origin = {x: x, y: y}

    reset:->
        @el.style.position = ''
        @el.style.webkitTransform = ''
        @el.style.display = 'block'

    back:(x, y)->
        console.log("back from #{x}, #{y}")
        # FIXME: this statement will leads to GUI block
        # @img.style.webkitTransform = "translate(#{x - ITEM_WIDTH/2}px, #{Math.abs(y-ITEM_WIDTH/2)}px)"
        @dragToBack = false
        @reset()
        # setTimeout(=>
        #     @img.style.display = ''
        #     @img.style.webkitTransition = 'all 300ms'
        #     setTimeout(=>
        #         @img.style.webkitTransform = "translate(#{@origin.x}px, #{Math.abs(@origin.y)}px)"
        #     , 10)
        # , 10)

        if @indicator
            @parentNode.insertBefore(@el, @indicator)
        else
            @parentNode.appendChild(@el)

        updatePanel()


class DragTargetManager
    constructor: ->
        @targets = {}

    add:(id, obj)->
        console.log("add #{id}")
        @targets[id] = obj

    remove:(id)->
        console.log("remove #{id} #{delete @targets[id]}")
        delete @targets[id]

    getHandle:(id)->
        console.log("get handle of #{id}: ")
        console.log(@targets[id])
        @targets[id]

_dragTargetManager = new DragTargetManager()
