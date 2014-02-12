animation_moveX = (el,moveX,time,easing = "linear",delay = 0)->
    #el.style.webkitTransition = "all #{time} linear"
    #el.style.marginLeft = moveX + "px"
    #el.style.webkitTransition = "display #{time} linear"
    
    el.style.webkitTransform = "translateX(#{moveX}px)"
    el.style.webkitTransition = "-webkit-transform #{time} easing #{delay}ms"
    el.style.webkitAnimationFillMode = "both"

animation_scale = (el,scale,time)->
    el.style.webkitTransform = "scale(#{scale})"
    el.style.webkitTransition = "-webkit-transform #{time} linear"

apply_animation = (el, name, duration, timefunc)->
    el.style.webkitAnimationName = name
    el.style.webkitAnimationDuration = duration
    el.style.webkitAnimationTimingFunction = timefunc or "linear"
    el.style.webkitAnimationFillMode = "both"

