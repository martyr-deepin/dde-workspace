#Copyright (c) 2011 ~ 2012 Deepin, Inc.
#              2011 ~ 2012 yilang
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

#for time area
format_two_bit = (s) ->
    if s < 10
        return "0#{s}"
    else
        return s

get_time_str = ->
    hours = format_two_bit new Date().getHours()
    min = format_two_bit new Date().getMinutes()
    return "#{hours}:#{min}"

get_date_str = ->
    month_list = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]
    day_list = ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"]

    day = day_list[new Date().getDay()]
    mon = month_list[new Date().getMonth()]
    date = new Date().getDate()
    year = new Date().getFullYear()

    return "#{day}, #{mon} #{date}, #{year}"

time = $("#time")
date = $("#date")
time.innerText = get_time_str()
date.innerText = get_date_str()
setInterval( ->
        time.innerText = get_time_str()
        return true
    , 1000)

setInterval( ->
        time.innerText = get_time_str()
        return true
    , 1000)

#for desktop environment area
get_de_info = ->
    echo "get desktop environment info"
    de_info = DCore.Greeter.get_sessions()
    return de_info

de_menu_cb = (id, title)->
    alert("clicked #{id} #{title}")
    
de_menu = new ComboBox("desktop", de_menu_cb)
for session in get_de_info()
    de_menu.insert(session, session, "images/deepin.png")
    
$("#bottom_buttons").appendChild(de_menu.element)

#for power area
get_power_info = ->
    power_info = {}

    if DCore.Greeter.get_can_suspend()
        power_info["suspend"] = suspend_cb
    if DCore.Greeter.get_can_hibernate()
        power_info["hibernate"] = hibernate_cb
    if DCore.Greeter.get_can_restart()
        power_info["restart"] = restart_cb
    if DCore.Greeter.get_can_shutdown()
        power_info["shutdown"] = shutdown_cb

    return power_info

suspend_cb = ->
    alert "suspend"
    # return DCore.Greeter.suspend()

hibernate_cb = ->
    alert "hibernate"
    # return DCore.Greeter.hibernate()

restart_cb = ->
    alert "restart"
    # return DCore.Greeter.restart()

shutdown_cb = ->
    alert "shutdown"
    # return DCore.Greeter.shutdown()

power_dict = get_power_info()    
power_menu_cb = (id, title)->
    power_dict[title]()

power_menu = new ComboBox("power", power_menu_cb)
for key, value of power_dict
    power_menu.insert(key, key, "images/control-power.png")

$("#bottom_buttons").appendChild(power_menu.element)

