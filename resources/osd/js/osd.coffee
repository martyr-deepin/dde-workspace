#Copyright (c) 2011 ~ 2013 Deepin, Inc.
#              2011 ~ 2013 yilang
#
#Author:      LongWei <yilang2007lw@gmail.com>
#Maintainer:  LongWei <yilang2007lw@gmail.com>
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

class OSD extends Widget

    constructor:->
        super
        echo "osd"
        document.body.appendChild(@element)
        
    option_build:->
        @opt = []
        #provide osd setting option
        @option = ["CapsLock","NumLock","LightAjust","VoiceAjust","WifiOn","InputSwitch","KeyLayout","ShowMode"]
        
        for id,i in @option
            @opt[i] = new Option(@option[i])
            @opt[i].option_build()
            @element.appendChild(@opt[i].element)


document.body.style.height = window.innerHeight
document.body.style.width = window.innerWidth

osd = new OSD()
#osd.option_build()

document.body.addEventListener("click",(e)=>
    e.stopPropagation()
    #DCore.Osd.quit()
)
 
