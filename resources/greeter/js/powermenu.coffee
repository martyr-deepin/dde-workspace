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

class PowerMenu extends Widget
    upower_obj = null
    consolekit_obj = null
    power_dict = {}
    power_menu = null
    parent = null
    img_before = null
    
    constructor: (parent_el) ->
        super
        parent = parent_el
        img_before = "images/powermenu/"
        upower_obj = DCore.DBus.sys_object("org.freedesktop.UPower", "/org/freedesktop/UPower", "org.freedesktop.UPower")
        consolekit_obj = DCore.DBus.sys_object("org.freedesktop.ConsoleKit", "/org/freedesktop/ConsoleKit/Manager", "org.freedesktop.ConsoleKit.Manager")

    suspend_cb : ->
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

    hibernate_cb : ->
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

    restart_cb : ->
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

    shutdown_cb : ->
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

    signal_connect:->
        #DCore.signal_connect("power", (msg) ->
        #    status_div = create_element("div", " ", $("#Debug"))
        #    status_div.innerText = "status:" + msg.status
        #)

    get_power_dict : ->
        if upower_obj.SuspendAllowed_sync()
            power_dict["suspend"] = @suspend_cb
        if upower_obj.HibernateAllowed_sync()
            power_dict["hibernate"] = @hibernate_cb
        if consolekit_obj.CanRestart_sync()
            power_dict["restart"] = @restart_cb
        if consolekit_obj.CanStop_sync()
            power_dict["shutdown"] = @shutdown_cb

        return power_dict

    #get_power_dict : ->
    #    power_dict = {}
    #
    #    if DCore.Greeter.get_can_suspend()
    #        power_dict["suspend"] = @suspend_cb
    #    if DCore.Greeter.get_can_hibernate()
    #        power_dict["hibernate"] = @hibernate_cb
    #    if DCore.Greeter.get_can_restart()
    #        power_dict["restart"] = @restart_cb
    #    if DCore.Greeter.get_can_shutdown()
    #        power_dict["shutdown"] = @shutdown_cb
    #
    #    return power_dict

    new_power_menu:->

        power_dict = @get_power_dict()
        power_menu_cb = (id, title)->
            power_dict[id]()

        power_menu = new ComboBox("power", power_menu_cb)

        for key, value of power_dict
            # power_menu.insert(key, key, "images/control-power.png")
            title = null
            if key == "suspend"
                title = _("suspend")
                img = img_before + "#{key}.png"
                power_menu.insert(key, title, img)
            else if key == "restart"
                title = _("restart")
                img = img_before + "#{key}.png"
                power_menu.insert(key, title, img)
#            else if key == "shutdown"
                #title = _("shutdown")
            else
                echo "invalid power option"

        power_menu.current_img.src = img_before + "shutdown_normal.png"
        parent.appendChild(power_menu.element)
        power_menu.current_img.addEventListener("mouseover",=>
            power_menu.current_img.src = img_before + "shutdown.png"
        )
        power_menu.current_img.addEventListener("mouseout",=>
            power_menu.current_img.src = img_before + "shutdown_normal.png"
        )
        power_menu.current_img.addEventListener("click", (e) =>
            power_dict["shutdown"]()
        )
        power_menu.menu.element.addEventListener("mouseover",=>
            power_menu.current_img.src = img_before + "shutdown.png"
        )

