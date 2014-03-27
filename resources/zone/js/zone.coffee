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

# wrapper func to get configs

cfgKey = ["left-up","left-down","right-up","right-down"]
cfgValue = [
    "/usr/bin/launcher",
    "/usr/bin/dss",
    "/usr/bin/desktop-show",
    "workspace",
    "none"
]


class Zone extends Widget

    constructor:->
        super
        echo "Zone"
        document.body.appendChild(@element)
        @getZoneConfig()

    getZoneConfig:->
        for id,i in cfgKey
            @zoneValue[id] = DCore.Zone.get_config(id)

    option_build:->
        echo "option_build"
        echo @zoneValue
        
        @opt = []
        #provide zone setting option
        @option = [_("Launcher"),_("System Settings"),_("Workspace"),_("Desktop"),_("None")]
        
        for id,i in cfgKey
            @opt[i] = new Option(cfgKey[i],@zoneValue[cfgKey[i]])
            @element.appendChild(@opt[i].element)
            for tmp in @option
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
