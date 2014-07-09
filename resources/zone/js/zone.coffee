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
class Zone extends Widget

    constructor:->
        super
        echo "Zone"
        document.body.style.height = window.innerHeight
        document.body.style.width = window.innerWidth
        document.body.appendChild(@element)
        @setZoneConfigAll()
        @setZoneLauncher()
        enableZoneDetect(false)

    setZoneConfigAll: ->
        getZoneConfig()
        #for value,key in cfgKeyVal
        #    setZoneConfig(key,value)

    setZoneLauncher: ->
        getZoneDBus()
        setZoneDBusSettings("left-up","/usr/bin/launcher")

    option_build:->
        echo "option_build"
        @opt = []
        for key,i in cfgKey
            @opt[i] = new Option(key,zoneKeyText[key])
            @element.appendChild(@opt[i].element)
            for tmp in option_text
                @opt[i].insert(tmp)
            @opt[i].option_build()

zone = new Zone()
zone.option_build()

document.body.addEventListener("click",(e)=>
    e.stopPropagation()
    return if DEBUG
    enableZoneDetect(true)
    DCore.Zone.quit()
)

document.body.addEventListener("contextmenu",(e)=>
    e.preventDefault()
    e.stopPropagation()
)

