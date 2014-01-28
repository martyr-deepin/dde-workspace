animation_moveX = (el,moveX,time)->
    echo el
    el.style.webkitTransition = "all #{time} linear"
    el.style.marginLeft = moveX + "px"
    echo el
    #el.style.webkitTransition = "display #{time} linear"
    
    #el.style.webkitTransform = "translateX(#{moveX}px)"
    #el.style.webkitTransition = "-webkit-transform #{time} linear"

animation_moveX_scale = (el,moveX,scale,time)->
    el.style.webkitTransform = "translateX(#{moveX}px)|scaleX(#{scale})|scaleY(#{scale})"
    el.style.webkitTransition = "-webkit-transform #{time} linear"

apply_animation = (el, name, duration, timefunc)->
    el.style.webkitAnimationName = name
    el.style.webkitAnimationDuration = duration
    el.style.webkitAnimationTimingFunction = timefunc or "linear"
    el.style.webkitAnimationFillMode = "both"
    #el.style.webkitAnimationIterationCount = "2"
    #el.style.webkitAnimationDirection = "alternate"

