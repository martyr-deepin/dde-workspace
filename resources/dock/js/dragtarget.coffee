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
        setTimeout(=>
            _b.removeChild(@img)
            delete @img
        , 10)

    setOrigin:(x, y)->
        console.log("#{x}, #{y}")
        @origin = {x: x, y: y}

    reset:->
        @el.style.position = ''
        @el.style.webkitTransform = ''

    back:(x, y)->
        console.log("back, #{x}, #{y}")
        @dragToBack = false
        @el.style.display = 'block'
        @reset()
        @img.style.display = ''
        @img.style.webkitTransform = "translate(#{x - ITEM_WIDTH/2}px, #{y-ITEM_WIDTH/2}px)"
        @img.style.webkitTransition = 'all 300ms'
        setTimeout(=>
            @img?.style.webkitTransform = "translate(#{@origin.x}px, #{@origin.y}px)"
        , 10)
        if @indicator
            @parentNode.insertBefore(@el, @indicator)
            updatePanel()
            return
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
