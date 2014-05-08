class DragTarget
    constructor: (@target)->
        @el = @target.element
        @indicator = @el.nextSibling
        @parentNode = @el.parentNode
        @img = @target.img.cloneNode(true)
        _b.appendChild(@img)
        @img.style.position = 'absolute'
        @img.style.opacity = '0.3'
        @img.addEventListener('webkitTransitionEnd', (e)=>
            _b.removeChild(@img)
            delete @img
        )

    setOrigin:(x, y)->
        console.log("#{x}, #{y}")
        @origin = {x: x, y: y}

    reset:->
        @el.style.position = ''
        @el.style.webkitTransform = ''

    back:(x, y)->
        console.log("back, #{x}, #{y}")
        _dragToBack = false
        @reset()
        @img.style.display = ''
        @img.style.webkitTransform = "translate(#{x - ITEM_WIDTH/2}px, #{y-ITEM_WIDTH/2}px)"
        @img.style.webkitTransition = 'all 300ms'
        setTimeout(=>
            @img.style.webkitTransform = "translate(#{@origin.x}px, #{@origin.y}px)"
        , 10)
        if @indicator
            @parentNode.insertBefore(@el, @indicator)
            updatePanel()
            return
        @parentNode.appendChild(@el)
        updatePanel()
