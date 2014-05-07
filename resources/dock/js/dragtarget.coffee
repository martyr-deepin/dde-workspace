class DragTarget
    constructor: (@target)->
        @el = @target.element
        @indicator = @el.nextSibling

    reset:->
        @el.style.position = ''
        @el.style.webkitTransform = ''

    back:->
        console.log("back")
        @reset()
        parent = @indicator.parentNode
        if @indicator
            parent.insertBefore(@el, @indicator)
            updatePanel()
            return
        parent.appendChild(@el)
        updatePanel()
