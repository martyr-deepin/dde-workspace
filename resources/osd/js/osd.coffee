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

set_el_bg =(el,src)->
    el.style.backgroundImage = "url(#{src})"

class OSD extends Widget
    
    MEDIAKEY = "com.deepin.daemon.MediaKey"
    
    constructor:->
        super
        echo "osd"
        document.body.appendChild(@element)
        @element.style.display = "none"
        #provide osd setting option
        @option = ["CapsLock","NumLock","LightAjust","VoiceAjust","WifiOn","InputSwitch","KeyLayout","ShowMode"]
        @MediaKey = ["mode4-c","mode4-n","mode4-l","mode4-v","mode4-w","mode4-i","mode4-k","mode4-m"]
    
    option_build:->
        @opt = []
        for id,i in @option
            @opt[i] = new Option(id)
            @opt[i].append(@element)
            @opt[i].hide()
        @element.style.display = "none"

    get_argv:->
        return DCore.Osd.get_argv()

    
    show:(option)->
        @element.style.display = "-webkit-box"
        for opt in @opt
            if opt.id is option then opt.show()
            else opt.hide()
        @timeout = setTimeout(=>
            @hide()
        ,2000)
    hide:->
        @element.style.display = "none"
        for opt in @opt
            opt.hide()
    
    dbus_signal:->
        try
            DBusMediaKey = DCore.DBus.session(MEDIAKEY)
            for key in @MediaKey
                DBusMediaKey.UnregisterAccelKey(key)
                DBusMediaKey.RegisterAccelKey(key)
            DBusMediaKey.connect("AccelKeyChanged",@KeyChanged)
        catch e
            echo "Error:-----DBusMediaKey:#{e}"
    
    KeyChanged:(key)=>
        clearTimeout(@timeout) if @timeout
        
        #here should resolve the key StringArray
        echo key
        if not (key in @MediaKey)
            echo "#{key} not in @MediaKey,return"
            @hide()
            return
        option = null
        for tmp,j in @MediaKey
            if tmp is key then option = @option[j]
        echo "KeyChanged:#{key}:----#{option}----will show"
        @show(option)

document.body.style.height = window.innerHeight
document.body.style.width = window.innerWidth

click_time = 0
document.body.addEventListener("click",(e)=>
    e.stopPropagation()
    click_time++
    DCore.Osd.quit() if click_time % 2 == 0
)
 

osd = new OSD()
osd.option_build()
osd.dbus_signal()

