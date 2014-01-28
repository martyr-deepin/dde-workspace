animation_moveX = (el,moveX,time)->
    #el.style.webkitTransition = "all #{time} linear"
    #el.style.marginLeft = moveX + "px"
    #el.style.webkitTransition = "display #{time} linear"
    
    el.style.webkitTransform = "translateX(#{moveX}px)"
    el.style.webkitTransition = "-webkit-transform #{time} linear"

animation_scale = (el,scale,time)->
    el.style.webkitTransform = "scale(#{scale})"
    el.style.webkitTransition = "-webkit-transform #{time} linear"

apply_animation = (el, name, duration, timefunc)->
    el.style.webkitAnimationName = name
    el.style.webkitAnimationDuration = duration
    el.style.webkitAnimationTimingFunction = timefunc or "linear"
    el.style.webkitAnimationFillMode = "both"

