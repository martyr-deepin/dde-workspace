class DragTarget
    constructor: (@target)->
        @el = @target.element
        @indicator = @el.nextSibling
        @parentNode = @el.parentNode

    reset:->
        @el.style.position = ''
        @el.style.webkitTransform = ''

    back:->
        console.log("back")
        @reset()
        if @indicator
            @parentNode.insertBefore(@el, @indicator)
            updatePanel()
            return
        @parentNode.appendChild(@el)
        updatePanel()
