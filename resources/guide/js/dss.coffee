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
    constructor:(@id)->
        super
        enableZoneDetect(true)
        get_dssicon_pos_interval = null
        switch_timeout = null
        dss = new Dss()

        @message = _("The Control Center will be shown or hidden by sliding the mouse to the lower right corner")
        @tips = _("tips: Click the setting icon on dock to implement")
        @show_message(@message)
        @show_tips(@tips)

        @dock = new Dock()
        @circle = new Pointer("dss_circle",@element)
        @circle.create_pointer(AREA_TYPE.circle,POS_TYPE.rightdown,=>
            clearInterval(get_dssicon_pos_interval)
            dss.show()
            guide?.switch_page(@,"DssShutdown")
        )
        @circle.enable_area_icon("#{@img_src}/preferences-system.png",ICON_SIZE[_dm].w,ICON_SIZE[_dm].h)
        @corner = new Pointer("corner_rightdown",@element)
        @corner.create_pointer(AREA_TYPE.corner,POS_TYPE.rightdown,=>
            clearInterval(get_dssicon_pos_interval)
            clearTimeout(switch_timeout)
            switch_timeout = setTimeout(=>
                guide?.switch_page(@,"DssShutdown")
            ,t_min_switch_page)
        ,"mouseover")
        @corner.set_area_pos(0,0,"fixed",POS_TYPE.rightdown)
        @corner.show_animation()
        get_dssicon_pos_interval = setInterval(=>
            @pos = @dock.get_dssicon_pos()
            @circle_x = @pos.x0 - @circle.pointer_width
            @circle_y = @pos.y0 - @circle.pointer_height
            @circle.set_area_pos(@circle_x,@circle_y,"fixed",POS_TYPE.leftup)
        ,100)
        @circle.show_animation()


class DssShutdown extends Page
    constructor:(@id)->
        super
        @message = _("Click the power button to shut down, reboot or do other operations")
        @tips = _("tips: Hover the setting icon on dock to quickly implement some setting functions")
        @show_message(@message)
        @show_tips(@tips)
        restack_tid = setInterval(->
            DCore.Guide.restack()
        ,200)

        dss = new Dss()
        dss.show()
        @rect = new Rect("dss_shutdown",@element)
        @rect.create_rect(50,50)
        @rect.set_pos(155,35,"fixed",POS_TYPE.rightdown)
        @rect.show_animation(=>
            setTimeout(=>
                clearInterval(restack_tid)
                guide?.switch_page(@,"DesktopCornerRightUp")
            ,500 * 5)
        )
