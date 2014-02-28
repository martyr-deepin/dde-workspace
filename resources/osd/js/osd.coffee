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
        @option_key = [
            {opt:"CapsLock",key:"mod4-c"},
            {opt:"NumLock",key:"mod4-n"},
            {opt:"LightAjust",key:"mod4-g"},
            {opt:"VoiceAjust",key:"mod4-v"},
            {opt:"WifiOn",key:"mod4-f"},
            {opt:"InputSwitch",key:"mod4-i"},
            {opt:"KeyLayout",key:"mod4-k"},
            {opt:"ShowMode",key:"mod4-o"}
        ]
        echo @option_key
        @opt = []
        
    option_build:->
        for option,i in @option_key
            @opt[i] = new Option(option.opt)
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
        ,4000)
    
    hide:->
        @element.style.display = "none"
        for opt in @opt
            opt.hide()
    
    dbus_signal:->
        try
            DBusMediaKey = DCore.DBus.session(MEDIAKEY)
            for option in @option_key
                key = option.key
                DBusMediaKey.UnregisterAccelKey_sync(key)
                DBusMediaKey.RegisterAccelKey_sync(key)
            DBusMediaKey.connect("AccelKeyChanged",@keyChanged)
        catch e
            echo "Error:-----DBusMediaKey:#{e}"
    
    keyChanged:(type,key)=>
        clearTimeout(@timeout) if @timeout
        option = null
        for tmp in @option_key
            if tmp.key is key then option = tmp.opt
        if not option?
            echo "#{key} not in @option_key.key,return"
            @hide()
            return
        echo "KeyChanged:#{key}:----#{option}----will show"
        @show(option)

click_time = 0
document.body.addEventListener("click",(e)=>
    e.stopPropagation()
    click_time++
    DCore.Osd.quit() if click_time % 3 == 0
)
 

osd = new OSD()
osd.option_build()
osd.dbus_signal()

