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
        @element.style.display = "none"
        @opt = []

    option_build:->
        for option,i in key_NameValue
            @opt[i] = new Option(option.Name)
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
        ,TIME_HIDE)
    
    hide:->
        @element.style.display = "none"
        for opt in @opt
            opt.hide()
    
    dbus_signal:->
        try
            DBusMediaKey = DCore.DBus.session(MEDIAKEY)
            # for option in key_NameValue
            #     keyValue = option.Value
            #     DBusMediaKey.UnregisterAccelKey_sync(keyValue)
            #     DBusMediaKey.RegisterAccelKey_sync(keyValue)
            MediaKeyList = []
            MediaKeyList = DBusMediaKey.MediaKeyList
            echo MediaKeyList
            DBusMediaKey.connect("AccelKeyChanged",@keyChanged)
            echo "DBusMediaKey #{MEDIAKEY}"
        catch e
            echo "Error:-----DBusMediaKey:#{e}"
    
    keyChanged:(type,keyValue)=>
        echo "KeyChanged:#{keyValue}"
        clearTimeout(@timeout) if @timeout
        option = null
        for tmp in key_NameValue
            if tmp.Value is keyValue then option = tmp.Name
        if not option?
            echo "#{key} not in key_NameValue.Value,return"
            @hide()
            return
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

