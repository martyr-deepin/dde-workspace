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
        
        @message = _("很好！请你再次触发右下角")
        @tips = _("tips：单击dock上的设置图标也可以实现")
        @show_message(@message)
        @show_tips(@tips)

        @dock = new Dock()
        @circle = new Pointer("dss_circle",@element)
        @circle.create_pointer(AREA_TYPE.circle_white,POS_TYPE.rightdown)
        @pos = @dock.get_dssicon_pos()
        @circle_x = @pos.x0 - @circle.pointer_width
        @circle_y = @pos.y0 - @circle.pointer_height - ICON_MARGIN_V_BOTTOM / 2
        @circle.set_area_pos(@circle_x,@circle_y,"fixed",POS_TYPE.leftup)



