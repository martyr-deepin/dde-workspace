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
    get_dssicon_pos_interval = null
    
    constructor:(@id)->
        super
        enableZoneDetect(true)
        @dss = new Dss()

        @message = _("Well, please trigger the lower right corner again")
        @tips = _("tips：Click the setting icon on dock to implement")
        @show_message(@message)
        @show_tips(@tips)

        @dock = new Dock()
        @circle = new Pointer("dss_circle",@element)
        @circle.create_pointer(AREA_TYPE.circle,POS_TYPE.rightdown,=>
            clearInterval(get_dssicon_pos_interval)
            @dss?.show()
            guide?.switch_page(@,"DssArea")
        )
        @circle.enable_area_icon("#{@img_src}/preferences-system.png",48,48)
        
        @corner = new Pointer("corner_rightdown",@element)
        @corner.create_pointer(AREA_TYPE.corner,POS_TYPE.rightdown,=>
            echo "mouseover"
            clearInterval(get_dssicon_pos_interval)
            
            clearTimeout(switch_timeout)
            switch_timeout = setTimeout(=>
                @dss = new Dss()
                @dss?.show()
                guide?.switch_page(@,"DssArea")
            ,t_min_switch_page)
        ,"mouseover")
        @corner.set_area_pos(0,0,"fixed",POS_TYPE.rightdown)
        @corner.show_animation()
        
        get_dssicon_pos_interval = setInterval(=>
            @pos = @dock.get_dssicon_pos()
            @circle_x = @pos.x0 - @circle.pointer_width
            @circle_y = @pos.y0 - @circle.pointer_height - ICON_MARGIN_V_BOTTOM / 2
            @circle.set_area_pos(@circle_x,@circle_y,"fixed",POS_TYPE.leftup)
        ,100)
        
        @circle.show_animation()


class DssArea extends Page
    constructor:(@id)->
        super
        DCore.Guide.disable_guide_region()
        
        restack_time_out = setTimeout(->
            DCore.Guide.restack()
        ,200)
        @message = _("Here is the system setting area")
        @tips = _("tips：Hover the setting icon on dock to quickly implement some setting functions")
        @show_message(@message)
        @show_tips(@tips)

        @dock = new Dock()
        @dss = new Dss()
        #@circle = new Pointer("dss_circle",@element)
        #@circle.create_pointer(AREA_TYPE.circle_white,POS_TYPE.rightdown)
        #@pos = @dock.get_dssicon_pos()
        #@circle_x = @pos.x0 - @circle.pointer_width
        #@circle_y = @pos.y0 - @circle.pointer_height - ICON_MARGIN_V_BOTTOM / 2
        #@circle.set_area_pos(@circle_x,@circle_y,"fixed",POS_TYPE.leftup)
        #@circle.show_animation()

        @rect = new Rect("dss_area",@element)
        @rect.create_rect(360,520)
        @rect.set_pos(0,150,"fixed",POS_TYPE.rightup)
        @rect.show_animation(=>
            setTimeout(=>
                @dss?.hide()
                clearTimeout(restack_time_out)
                guide?.switch_page(@,"End")
            ,t_switch_page)
        )
        

