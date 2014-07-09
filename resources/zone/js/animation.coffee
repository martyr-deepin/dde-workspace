#Copyright (c) 2011 ~ 2014 Deepin, Inc.
#              2011 ~ 2014 bluth
#
#encoding: utf-8
#Author:      bluth <yuanchenglu@linuxdeepin.com>
#Maintainer:  bluth <yuanchenglu@linuxdeepin.com>
#
#This program is free software; you can redistribute it and/or modify
#it under the terms of the GNU General Public License as published by
#the Free Software Foundation; either version 3 of the License, or
#(at your option) any later version.
#
#This program is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.
#
#You should have received a copy of the GNU General Public License
#along with this program; if not, see <http://www.gnu.org/licenses/>.

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

animation_moveX = (el,moveX,time = 0,easing = "linear",delay = 0)->
    el.style.webkitTransform = "translateX(#{moveX}px)"
    el.style.webkitTransition = "-webkit-transform #{time / 1000}s easing #{delay}ms"
    el.style.webkitAnimationFillMode = "both"

animation_moveY = (el,moveY,time = 0,easing = "linear",delay = 0)->
    el.style.webkitTransform = "translateY(#{moveY}px)"
    el.style.webkitTransition = "-webkit-transform #{time / 1000}s easing #{delay}ms"
    el.style.webkitAnimationFillMode = "both"


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

