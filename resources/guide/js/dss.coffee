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


class DssLaunch extends Page
    switch_timeout = null
    dock_hide_tid = null
    constructor:(@id)->
        super
        enableZoneDetect(true)
        @dockReal = new Dock()
        dock_hide_tid = setInterval(->
            @dockReal.hide()
        ,100)
        @dockMode = new DockMode("dockMode_#{_dm}",_dm,@element)
        dss = new Dss()

        @message = _("The Control Center will be shown or hidden by sliding the mouse to the lower right corner")
        @tips = _("tips: Click the setting icon on dock to implement")
        @show_message(@message)
        @show_tips(@tips)

        @circle = new Pointer("dss_circle",@element)
        @circle.create_pointer(AREA_TYPE.circle,POS_TYPE.rightdown,=>
            dss.show()
            @switch_page()
        )

        @corner = new Pointer("corner_rightdown",@element)
        @corner.create_pointer(AREA_TYPE.corner,POS_TYPE.rightdown,@switch_page,"mouseover")
        @corner.set_area_pos(0,0,"fixed",POS_TYPE.rightdown)
        @corner.show_animation()

        setTimeout(=>
            @pos = @dockMode.get_icon_pos(@dockMode.get_dss_index())
            @circle_x = @pos.x - @circle.pointer_width
            @circle_y = @pos.y - @circle.pointer_height
            @circle.set_area_pos(@circle_x,@circle_y,"fixed",POS_TYPE.leftup)
            @circle.show_animation()
        ,200)

    switch_page: =>
        clearTimeout(switch_timeout)
        clearInterval(dock_hide_tid)
        switch_timeout = setTimeout(=>
            @dockMode.destroy()
            @dockReal.show()
            guide?.switch_page(@,"DssShutdown")
        ,t_min_switch_page)


class DssShutdown extends Page
    constructor:(@id)->
        super
        @message = _("Click the power button to shut down, reboot or do other operations")
        @tips = _("tips: Hover the setting icon on dock to quickly implement some setting functions")
        @show_message(@message)
        @show_tips(@tips)

        dss = new Dss()
        dss.show()
        @rect = new Rect("dss_shutdown",@element)
        @rect.create_rect(50,50)
        @rect.set_pos(155,35,"fixed",POS_TYPE.rightdown)
        @rect.show_animation(=>
            setTimeout(=>
                guide?.switch_page(@,"DesktopCornerRightUp")
            ,500 * 5)
        )
