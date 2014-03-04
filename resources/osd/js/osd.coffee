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


class OSD extends Widget
    
    constructor:->
        super
        echo "osd"
        document.body.appendChild(@element)
        @element.style.display = "none"
        @opt = []

    newClass:(id)->
        cls = null
        switch id
            when "Light_Up", "Light_Down", "DisplayMode"
                cls = new Display(id)
            when "Audio_Up", "Audio_Down", "Audio_Mute"
                cls = new Audio(id)
            else cls = new Option(id)
        return cls
    
    option_build:->
        for option,i in MediaKey_NameValue
            name = option.Name
            @opt[i] = @newClass(name)
            @opt[i].append(@element)
            @opt[i].hide()
        @element.style.display = "none"
    
    get_argv:->
        return DCore.Osd.get_argv()
    
    show:(option)->
        echo "osd show"
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
            DBusMediaKey.connect("AccelKeyChanged",@keyChanged)
            echo "DBusMediaKey #{MEDIAKEY}"
        catch e
            echo "Error:-----DBusMediaKey:#{e}"
    
    keyChanged:(type,keyValue)=>
        echo "KeyChanged:#{keyValue}"
        clearTimeout(@timeout) if @timeout
        option = null
        for tmp in MediaKey_NameValue
            if tmp.Value is keyValue then option = tmp.Name
        if not option?
            echo "#{key} not in MediaKey_NameValue.Value,return"
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

