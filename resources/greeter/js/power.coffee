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
    DCore.Greeter.run_suspend()

hibernate_cb = ->
    DCore.Greeter.run_hibernate()

restart_cb = ->
    DCore.Greeter.run_restart()

shutdown_cb = ->
    DCore.Greeter.run_shutdown()

power_dict = get_power_info()
for key, value of power_dict
    # power_menu.insert(key, key, "images/control-power.png")
    power_menu.insert_noimg(key, key)

power_menu.current_img.src = "images/control-power.png"
$("#bottom_buttons").appendChild(power_menu.element)

DCore.signal_connect("power", (msg) ->
    status_div = create_element("div", " ", $("#Debug"))
    status_div.innerText = "status:" + msg.status
)
