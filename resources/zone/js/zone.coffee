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
        document.body.appendChild(@element)
        
    option_build:->
        @opt = []
        #set default zone
        @ids = ["LEFTUP","LEFTDOWN","RIGHTUP","RIGHTDOWN"]
        @currents = ["Launcher","Workspace","Desktop","System Setup","None"]
        
        #provide zone setting option
        @option = ["Launcher","System Setup","Workspace","Desktop","None"]
        
        for id,i in @ids
            @opt[i] = new Option(@ids[i],@currents[i])
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
