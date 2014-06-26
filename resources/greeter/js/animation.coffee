inject_css(_b,"css/animation.css")

animation_moveX = (el,moveX,time = 0,easing = "linear",delay = 0,cb)->
    #el.style.webkitTransition = "all #{time} linear"
    #el.style.marginLeft = moveX + "px"
    #el.style.webkitTransition = "display #{time} linear"
    
    el.style.webkitTransform = "translateX(#{moveX}px)"
    el.style.webkitTransition = "-webkit-transform #{time / 1000}s easing #{delay}ms"
    el.style.webkitAnimationFillMode = "both"
    id = setTimeout(->
        el.style.webkitAnimation = ""
        cb?()
        clearTimeout(id)
    , time * 1000)
    
animation_scale = (el,scaleN,time = 0)->
    el.style.webkitTransform = "scale(#{scaleN})"
    el.style.webkitTransition = "-webkit-transform #{time}ms linear"

animation_rotate = (el,rotate,time = 0)->
    el.style.webkitTransform = "rotate(#{rotate}deg)"
    el.style.webkitTransition = "-webkit-transform #{time / 1000}s linear"

apply_animation = (el, name, duration, timefunc,cb)->
    el.style.webkitAnimationName = name
    el.style.webkitAnimationDuration = "#{duration}ms"
    el.style.webkitAnimationTimingFunction = timefunc or "linear"
    el.style.webkitAnimationFillMode = "both"
    id = setTimeout(->
        el.style.webkitAnimation = ""
        cb?()
        clearTimeout(id)
    , duration)
