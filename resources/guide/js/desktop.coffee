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

class DesktopRichDir extends Page
    constructor:(@id)->
        super
        
        @message = _("Let's overlap the other two icons on the first icon \n generate \"application group\"")
        @show_message(@message)
        
        @corner_leftup = new Pointer("circle_richdir",@element)
        @corner_leftup.create_pointer(AREA_TYPE.circle,POS_TYPE.leftup)
        @corner_leftup.set_area_pos(18,13,"fixed",POS_TYPE.leftup)
        @corner_leftup.show_animation()
        
class DesktopRichDirCreated extends Page
    constructor:(@id)->
        super
        
        @message = _("Well, you have learned how to create a \"application group\"")
        @tips = _("tips：Right-click on the application group will provide more functions")
        @show_message(@message)
        @show_tips(@tips)
        setTimeout(=>
            guide?.switch_page(@,"DesktopCorner")
        ,t_switch_page)
        
class DesktopCorner extends Page
    constructor:(@id)->
        super
        
        #DCore.Guide.launch_zone()
        
        @message = _("Slide the mouse to the four top corners, which can trigger four different events")
        @tips = _("tips：Please trigger successively by hints, click on the blank area to return")
        @show_message(@message)
        @show_tips(@tips)
        
        @pos = ["leftup","rightup","leftdown","rightdown"]
        @corner = []
        for p,i in @pos
            @corner[i] = new Pointer("corner_#{p}",@element)
            @corner[i].create_pointer(AREA_TYPE.corner,POS_TYPE[p])
            @corner[i].set_area_pos(0,0,"fixed",POS_TYPE[p])
            @corner[i].show_animation()

class DesktopZone extends Page
    constructor:(@id)->
        super
        
        @message = _("Right-click on desktop to call up the menu, click on \"Desktop hot zone setting\" to set the hot zone just used")
        @tips = _("tips：Click on the blank area to return")
        @show_message(@message)
        @show_tips(@tips)


