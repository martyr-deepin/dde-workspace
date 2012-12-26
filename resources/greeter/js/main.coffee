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

get_power_info = ->
    echo "get power info"
    power_info = {}

    if DCore.Greeter.get_can_suspend()
        power_info["suspend"] = suspend
    if DCore.Greeter.get_can_hibernate()
        power_info["hibernate"] = hibernate
    if DCore.Greeter.get_can_restart()
        power_info["restart"] = restart
    if DCore.Greeter.get_can_shutdown()
        power_info["shutdown"] = shutdown

    return power_info

suspend = ->
    echo "suspend"
    # return DCore.Greeter.suspend()

hibernate = ->
    echo "hibernate"
    # return DCore.Greeter.hibernate()

restart = ->
    echo "restart"
    # return DCore.Greeter.restart()

shutdown = ->
    echo "shutdown"
    # return DCore.Greeter.shutdown()

get_de_info = ->
    echo "get desktop environment info"
    de_info = {"gnome":"gnome", "deepin":"deepin"}

    return de_info

de_menu_cb = (id, title)->
    alert("clicked #{id} #{title}")

power_menu_cb = de_menu_cb

de_menu = new ComboBox("desktop", de_menu_cb)
de_menu.insert(1, "deepin", "images/deepin.png")
de_menu.insert(2, "gnome", "images/gnome.png")

power_menu = new ComboBox("power", power_menu_cb)
power_menu.insert(1, "power", "images/control-power.png")


$("#bottom_buttons").appendChild(de_menu.element)
$("#bottom_buttons").appendChild(power_menu.element)
