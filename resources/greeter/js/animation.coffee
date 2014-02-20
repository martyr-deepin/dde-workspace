animation_moveX = (el,moveX,time = 0,easing = "linear",delay = 0,cb)->
    #el.style.webkitTransition = "all #{time} linear"
    #el.style.marginLeft = moveX + "px"
    #el.style.webkitTransition = "display #{time} linear"
    
    el.style.webkitTransform = "translateX(#{moveX}px)"
    el.style.webkitTransition = "-webkit-transform #{time / 1000}s easing #{delay}ms"
    el.style.webkitAnimationFillMode = "both"
    el.addEventListener("webkitTransitionEnd",=>
        echo "------------end"
        cb?()
        #el.removeEventListener("webkitTransitionEnd",cb?(),false)
    ,false)

animation_scale = (el,scaleN,time = 0)->
    el.style.webkitTransform = "scale(#{scaleN})"
    el.style.webkitTransition = "-webkit-transform #{time}ms linear"

animation_rotate = (el,rotate,time = 0)->
    el.style.webkitTransform = "rotate(#{rotate}deg)"
    el.style.webkitTransition = "-webkit-transform #{time / 1000}s linear"

apply_animation = (el, name, duration, timefunc)->
    el.style.webkitAnimationName = name
    el.style.webkitAnimationDuration = "#{duration}ms"
    el.style.webkitAnimationTimingFunction = timefunc or "linear"
    el.style.webkitAnimationFillMode = "both"

