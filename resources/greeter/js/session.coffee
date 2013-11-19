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

$("#Version").innerHTML = "
            <span> #{_("Linux Deepin 2013")}<sup>#{_(VERSION)}</sup></span> 
            "

detext = create_element("div", "Detext", $("#div_desktop_power"))
detext.innerText = _("Session")

sessions = DCore.Greeter.get_sessions()
for session in sessions
    id = session
    name = DCore.Greeter.get_session_name(id)
    icon = DCore.Greeter.get_session_icon(session)
    icon_path ="images/#{icon}"
    de_menu.insert(id, name, icon_path)

default_session = DCore.Greeter.get_default_session()
    
$("#div_desktop_power").appendChild(de_menu.element)
de_menu.set_current(default_session)
#DCore.Greeter.set_selected_session(default_session)


upower_obj = DCore.DBus.sys_object("org.freedesktop.UPower", "/org/freedesktop/UPower", "org.freedesktop.UPower")
consolekit_obj = DCore.DBus.sys_object("org.freedesktop.ConsoleKit", "/org/freedesktop/ConsoleKit/Manager", "org.freedesktop.ConsoleKit.Manager")

get_power_info = ->
    power_info = {}

    if upower_obj.SuspendAllowed_sync()
        power_info["suspend"] = suspend_cb
    if upower_obj.HibernateAllowed_sync()
        power_info["hibernate"] = hibernate_cb
    if consolekit_obj.CanRestart_sync()
        power_info["restart"] = restart_cb
    if consolekit_obj.CanStop_sync()
        power_info["shutdown"] = shutdown_cb

    return power_info

#get_power_info = ->
#    power_info = {}
#
#    if DCore.Greeter.get_can_suspend()
#        power_info["suspend"] = suspend_cb
#    if DCore.Greeter.get_can_hibernate()
#        power_info["hibernate"] = hibernate_cb
#    if DCore.Greeter.get_can_restart()
#        power_info["restart"] = restart_cb
#    if DCore.Greeter.get_can_shutdown()
#        power_info["shutdown"] = shutdown_cb
#
#    return power_info

suspend_cb = ->
    echo "suspend cb"
    if not upower_obj.SuspendAllowed_sync()
        echo "suspend not allowed"
        return
    try
        upower_obj.Suspend_sync()
    catch error
        echo "suspend failed"
        try 
            DCore.Greeter.run_suspend()
        catch error
            echo error

hibernate_cb = ->
    echo "hibernate cb"
    if not upower_obj.HibernateAllowed_sync()
        echo "hibernate not allowed"
        return 
    try
        upower_obj.Hibernate_sync()
    catch error
        echo "hibernate failed"
        try
            DCore.Greeter.run_hibernate()
        catch error
            echo error

restart_cb = ->
    echo "restart cb"
    if not consolekit_obj.CanRestart_sync()
        echo "restart not allowed"
        return 
    try
        consolekit_obj.Restart_sync()
    catch error
        echo "restart failed"
        try
            DCore.Greeter.run_restart()
        catch error
            echo error

shutdown_cb = ->
    echo "shutdown cb"
    if not consolekit_obj.CanStop_sync()
        echo "shutdown not allowed"
        return 
    try
        consolekit_obj.Stop_sync()
    catch error
        echo "shutdown failed"
        try
            DCore.Greeter.run_shutdown()
        catch error
            echo error

power_dict = get_power_info()
for key, value of power_dict
    # power_menu.insert(key, key, "images/control-power.png")
    title = null
    if key == "suspend"
        title = _("suspend")
    else if key == "hibernate"
        title = _("hibernate")
    else if key == "shutdown"
        title = _("shutdown")
    else if key == "restart"
        title = _("restart")
    else
        echo "invalid power option"
    power_menu.insert_noimg(key, title)

power_menu.current_img.src = "images/control-power.png"
$("#div_desktop_power").appendChild(power_menu.element)

power_menu.show_item.addEventListener("click", (e) =>
    power_dict["shutdown"]()
)

#DCore.signal_connect("power", (msg) ->
#    status_div = create_element("div", " ", $("#Debug"))
#    status_div.innerText = "status:" + msg.status
#)
