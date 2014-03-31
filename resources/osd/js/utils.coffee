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
FOCUS = false

setFocus = (focus)->
    FOCUS = focus
    DCore.Osd.set_focus(FOCUS)

#MediaKey DBus
MEDIAKEY =
    obj: "com.deepin.daemon.KeyBinding"
    path: "/com/deepin/daemon/MediaKey"
    interface: "com.deepin.daemon.MediaKey"

TIME_HIDE = 1500
TIME_PRESS = 5
timeout_osdHide = null
DBusMediaKey = null
try
    DBusMediaKey = DCore.DBus.session_object(
        MEDIAKEY.obj,
        MEDIAKEY.path,
        MEDIAKEY.interface
    )
catch e
    echo "Error:-----DBusMediaKey:#{e}"
echo DBusMediaKey

allElsHide = ->
    els = _b.children
    for el in els
        if el.tagName = "DIV"
            el.style.display = "none"

osdHide = ->
    return if FOCUS
    #echo "osdHide"
    allElsHide()
    DCore.Osd.hide()

osdShow = ->
    #echo "osdShow"
    allElsHide()
    DCore.Osd.show()

osdHide()

click_time = 0
_b.addEventListener("click",(e)=>
    e.stopPropagation()
    echo click_time
    click_time++
    if click_time % 1 == 0
        click_time = 0
        DCore.Osd.hide()
)

_b.addEventListener("contextmenu",(e)=>
    e.preventDefault()
    e.stopPropagation()
)
        
setBodySize = (width,height)->
    _b.style.width = width
    _b.style.height = height

set_bg = (el,imgName,preImgName)->
    if preImgName == imgName then return
    echo "set_bg: bgChanged from #{preImgName} to #{imgName}"
    if true
        apply_linear_hide_show(el,"0.1","ease-in-out")
    else
        el.style.opacity = "1"
        t = 50
        jQuery(el).animate(
            {opacity:'0';},
            t,
            "swing",=>
                el.style.backgroundImage = "url(img/#{imgName}.png)"
                jQuery(el).animate(
                    {opacity:'1';},t,"swing"
                )
        )
 
showValue = (value,min,max,cls,id)->
    if value > max then value = max
    else if value < min then value = min
    else if value is null then value = min

    if not cls.bar?
        cls.bar = new Bar(id)
        cls.bar.setPosition(cls.element,"31px","20px","absolute")
        cls.bar.setSize("98px","10px")
        cls.bar.setColor("#FFF")
        cls.bar.showProgressNum(false)
        cls.bar.progressCreate()
    echo "showValue: setProgress-----#{value / max}---"
    cls.bar.setProgress(value / max) if cls.bar
