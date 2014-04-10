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
    power_title = {}
    power_menu = null
    parent = null
    img_before = null
    
    constructor: (parent_el) ->
        super
        @parent = parent_el
        img_before = "images/powermenu/"
        if not @parent? then @parent = document.body
        @parent.appendChild(@element)

    suspend_cb : ->
        power_force("suspend")

    restart_cb : ->
        power_force("restart")

    shutdown_cb : ->
        power_force("shutdown")

    get_power_dict : ->
        power_dict["shutdown"] = @shutdown_cb
        power_dict["restart"] = @restart_cb
        power_dict["suspend"] = @suspend_cb
        power_title["shutdown"] = _("Shut down")
        power_title["restart"] = _("Restart")
        power_title["suspend"] = _("Suspend")
        
        return power_dict

    menuChoose_click_cb : (id, title)=>
        id = power_menu.set_current(id)
        #enableZoneDetect(true)
        power_dict[id]()

    new_power_menu:->
        echo "new_power_menu"
        power_dict = @get_power_dict()

        power_menu = new ComboBox("power", @menuChoose_click_cb)

        for key, title of power_title
            img_normal = img_before + "#{key}_normal.png"
            img_hover = img_before + "#{key}_hover.png"
            img_click = img_before + "#{key}_press.png"
            power_menu.insert(key, title, img_normal,img_hover,img_click)
        
        power_menu.frame_build()
        @element.appendChild(power_menu.element)
        
        power_menu.current_img.src = img_before + "powermenu.png"
    
    keydown_listener:(e)->
        power_menu.menu.keydown(e)
