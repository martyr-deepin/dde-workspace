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

cfgKeyVal = []
zoneKeyText = []
cfgKey = ["left-up","left-down","right-up","right-down"]
cfgValue = [
    "/usr/bin/launcher",
    "/usr/bin/dss",
    "workspace",
    "/usr/bin/desktop-show",
    "none"
]
option_text = [_("Launcher"),_("System Settings"),_("Workspace"),_("Desktop"),_("None")]

class Zone extends Widget

    constructor:->
        super
        echo "Zone"
        document.body.appendChild(@element)
        @getZoneConfig()

    getZoneConfig:->
        for key,i in cfgKey
            value = DCore.Zone.get_config(key)
            cfgKeyVal[key] = value
            zoneKeyText[key] = option_text[j] for val ,j in cfgValue when val is value
        echo cfgKeyVal
        echo zoneKeyText
    
    option_build:->
        echo "option_build"
        @opt = []
        for key,i in cfgKey
            @opt[i] = new Option(key,zoneKeyText[key])
            @element.appendChild(@opt[i].element)
            for tmp in option_text
                @opt[i].insert(tmp)
            @opt[i].option_build()


document.body.style.height = window.innerHeight
document.body.style.width = window.innerWidth

zone = new Zone()
zone.option_build()

document.body.addEventListener("click",(e)=>
    e.stopPropagation()
    DCore.Zone.quit()
)
 
document.body.addEventListener("contextmenu",(e)=>
    e.preventDefault()
    e.stopPropagation()
)

bgRadial = ->
    wWidth = window.innerWidth
    wHeight = window.innerHeight
    canvas = create_element("canvas","canvas",document.body)
    context = canvas.getContext("2d")
    x = wWidth / 2
    y = wHeight / 2
    r = wWidth / 2
    echo wWidth + "------" + wHeight + ";" + x + "-----" + y + "r:#{r}"
    
    rg = context.createRadialGradient(x,y,0,x,y,r)
    rg.addColorStop(0,'#FFFFFF')
    rg.addColorStop(1,'#000000')
    
    context.fillStyle = rg
    context.beginPath()
    context.arc(x,y,r,0,2 * Math.PI)
    context.fill()

#bgRadial()
