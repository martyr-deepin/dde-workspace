apply_rotate = (el)->
    el.style.webkitAnimation = "rotate 0.5s cubic-bezier(0, 0, 0.35, -1)"
    el.addEventListener('webkitAnimationEnd', ->
        this.style.webkitAnimationEnd = ""
    , false)
