#Copyright (c) 2011 ~ 2012 Deepin, Inc.
#              2011 ~ 2012 yilang
#
#Author:      LongWei <yilang2007lw@gmail.com>
#                     <snyh@snyh.org>
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


class SwitchUser extends Widget
    DisplayManager =
        name:"org.freedesktop.DisplayManager",
        path:"/org/freedesktop/DisplayManager/Seat0",
        interface:"org.freedesktop.DisplayManager.Seat",
    
    constructor: ()->
        super
        clearInterval(draw_camera_id)
        draw_camera_id = null
        document.body.style.fontSize = "62.5%"
        @accounts = new Accounts(APP_NAME)

    button_switch:->
        @users_id = @accounts.users_id
        if @users_id.length < 2 then return
        
        @switch = create_img("switch", "images/userswitch/acount_switch_hover.png", @element)
        @switch.style.cursor = "pointer"
        @switch.style.width = "5em"
        @switch.style.height = "5em"
        @switch.addEventListener("mouseover", =>
            @switch.src = "images/userswitch/acount_switch_hover.png"
        )
        @switch.addEventListener("mouseout", =>
            @switch.src = "images/userswitch/acount_switch_hover.png"
        )
        @switch.addEventListener("click", =>
            localStorage.setItem("from_lock",true)
            @SwitchToGreeter()
        )

    SwitchToGreeter:->
        echo "SwitchToGreeter"
        try
            enableZoneDetect(true)
            switch_dbus = get_dbus("system",DisplayManager,"CanSwitch")
            if switch_dbus.CanSwitch
                switch_dbus.SwitchToGreeter()
            else
                DCore.Lock.switch_user()
        catch error
            echo "can not find the switch dbus,perhaps you only have one userAccount!"
            DCore.Lock.switch_user()
            return false

    SwitchToUser:(username,session_name)->
        try
            switch_dbus = get_dbus("system",DisplayManager,"SwitchToUser")
            switch_dbus.SwitchToUser_sync(username,session_name)
            echo switch_dbus
        catch error
            echo "can not find the switch dbus,perhaps you only have one userAccount!"
            return false

