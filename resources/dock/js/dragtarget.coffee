class DragTarget
    constructor: (@target)->
        @el = @target.element
        @indicator = @el.nextSibling

    back:->
        console.log("back")
        @el.style.position = ''
        @el.style.webkitTransform = ''
        parent = @indicator.parentNode
        if @indicator
            parent.insertBefore(@el, @indicator)
            updatePanel()
            return
        parent.appendChild(@el)
        updatePanel()
