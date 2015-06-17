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

_b = document.body

osd = {}
signal_old = null
signal_changed = true
osd_is_hide = false

DEBUG = false

TIME_HIDE = 1500
TIME_PRESS = 5
timeout_osdHide = null

ICON_SIZE_NORMAL = 96

allElsHide = ->
    echo "allElsHide"
    els = _b.children
    for el in els
        el.style.display = "none"

osdHide = ->
    echo "osdHide"
    clearTimeout(timeout_osdHide)
    osd_is_hide = true
    DCore.Osd.quit()

osdShow = ->
    echo "osdShow"
    #if !osd_is_hide and !signal_changed then return
    if !osd_is_hide or signal_changed then allElsHide()

    DCore.Osd.show()
    osd_is_hide = false
    document.body.opacity = "0"
    jQuery(document.body).animate({opacity:'1';},500)

setWinSize =(ele)->
    w = jQuery(ele).outerWidth()
    h = jQuery(ele).outerHeight()
    DCore.Osd.set_size(w,h)
    document.body.style.width = w
    document.body.style.height = h

click_time = 0
_b.addEventListener("click",(e)=>
    e.stopPropagation()
    echo click_time
    click_time++
    times = 1
    times = 3 if DEBUG
    if click_time % times == 0
        click_time = 0
        osdHide()
)

_b.addEventListener("contextmenu",(e)=>
    e.preventDefault()
    e.stopPropagation()
)

setBodySize = (width,height)->
    _b.style.width = width
    _b.style.height = height

getThemeIcon = (iconName,size) ->
    icon = DCore.get_theme_icon(iconName,size)
    console.debug "[getThemeIcon]:#{iconName},#{size} ===#{icon}==="
    icon

set_bg = (cls,imgName,prevImgName,width = ICON_SIZE_NORMAL,height = ICON_SIZE_NORMAL)->
    if prevImgName == imgName then return
    if prevImgName == undefined or prevImgName == null then prevImgName = imgName
    echo "set_bg: bgChanged from #{prevImgName} to #{imgName}"

    if not cls.bgContainer?
        cls.bgContainer = create_element("div","#{cls.id}_bg1",cls.element)
        cls.bgContainer.style.position = "absolute"
    cls.bgContainer.style.width = width
    cls.bgContainer.style.height = height
    cls.bgContainer.style.left = (cls.element.clientWidth - cls.bgContainer.clientWidth) / 2
    top = (cls.element.clientHeight - cls.bgContainer.clientHeight) / 2
    top -= 12 if cls.bar isnt undefined
    cls.bgContainer.style.top = top
    cls.bgContainer.style.display = "block"

    if not cls.bg1?
        cls.bg1 = create_img("#{cls.id}_bg1","",cls.bgContainer)
        cls.bg2 = create_img("#{cls.id}_bg2","",cls.bgContainer)
        cls.bg1.style.position = cls.bg2.style.position = "absolute"
        cls.bg1.style.width = cls.bg2.style.width = width
        cls.bg1.style.height = cls.bg2.style.height = height
    try
        cls.bg1.src = getThemeIcon(prevImgName,ICON_SIZE_NORMAL)
        cls.bg2.src = getThemeIcon(imgName,ICON_SIZE_NORMAL)
        console.debug "#{cls.bgContainer.clientWidth},#{cls.bgContainer.clientHeight}"
    catch e
        console.debug "[set_bg]:error:#{e}"

    t = 500
    cls.bg1.style.opacity = "1.0"
    jQuery(cls.bg1).animate({opacity:'0';},t,"swing")
    cls.bg2.style.opacity = "0.0"
    jQuery(cls.bg2).animate({opacity:'1';},t,"swing")

showValue = (value,min,max,cls,id)->
    if value > max then value = max
    else if value < min then value = min
    else if value is null then value = min

    if not cls.bar?
        cls.bar = new Bar(id)
        cls.bar.setPosition(cls.element,"31px","20px","absolute")
        cls.bar.setSize("98px","6px")
        cls.bar.setColor("#FFF")
        cls.bar.showProgressNum(false)
        cls.bar.progressCreate()
    echo "showValue: setProgress-----#{value / max}---"
    cls.bar.setProgress(value / max) if cls.bar


move_animation = (el,y0,y1,type = "top",pos = "absolute",cb) ->
    el.style.display = "block"
    el.style.position = pos
    t_show = 1000
    pos0 = null
    pos1 = null
    animate_init = ->
        switch type
            when "top"
                el.style.top = y0
                pos0 = {top:y0}
                pos1 = {top:y1}
            when "bottom"
                el.style.bottom = y0
                pos0 = {bottom:y0}
                pos1 = {bottom:y1}
    animate_init()
    jQuery(el).animate(
        pos1,t_show,"linear",=>
            animate_init()
            jQuery(el).animate(pos1,t_show,"linear",cb?())
    )

