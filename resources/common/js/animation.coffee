#Copyright (c) 2011 ~ 2014 Deepin, Inc.
#              2011 ~ 2014 bluth
#
#Author:      bluth <yuanchenglu001@gmail.com>
#Maintainer:  bluth <yuanchenglu001@gmail.com>
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

apply_animation = (el, name, duration, timefunc)->
    el.style.webkitAnimationName = name
    el.style.webkitAnimationDuration = duration
    el.style.webkitAnimationTimingFunction = timefunc or "linear"

apply_rotate = (el, time)->
    apply_animation(el, "rotate", "#{time}s", "cubic-bezier(0, 0, 0.35, -1)")
    id = setTimeout(->
        el.style.webkitAnimation = ""
        clearTimeout(id)
    , time * 1000)

apply_flash = (el, time)->
    apply_animation(el, "flash", "#{time}s", "cubic-bezier(0, 0, 0.35, -1)")
    id = setTimeout(->
        el.style.webkitAnimation = ""
        clearTimeout(id)
    , time * 1000)

apply_refuse_rotate = (el, time)->
    apply_animation(el, "refuse", "#{time}s", "linear")
    setTimeout(->
        el.style.webkitAnimation = ""
    , time * 1000)

apply_linear_hide_show = (el, time,timefun)->
    echo "apply_linear_hide_show"
    apply_animation(el, "linear-hide-show", "#{time}s", timefunc)
    id = setTimeout(->
        el.style.webkitAnimation = ""
        clearTimeout(id)
    , time * 1000)

apply_linear_show = (el, time, timefunc)->
    apply_animation(el, "linear-show", "#{time}s", timefunc)
    id = setTimeout(->
        el.style.webkitAnimation = ""
        clearTimeout(id)
    , time * 1000)

apply_linear_hide = (el, time, timefunc)->
    apply_animation(el, "linear-hide", "#{time}s", timefunc)
    id = setTimeout(->
        el.style.webkitAnimation = ""
        clearTimeout(id)
    , time * 1000)


