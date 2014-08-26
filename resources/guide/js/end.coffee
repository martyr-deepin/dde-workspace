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

class End extends Page
    constructor:(@id)->
        super
        DCore.Guide.enable_guide_region()
        @message = _("Thank you for your patience to learn! More surprises are waiting for you to explore")
        @show_message(@message)
        #@msg_tips.style.top = "-10%"
        @element.style.webkitBoxOrient = "vertical"
        @choose_div = create_element("div","choose_div",@element)
        @end = new ButtonNext("end",_("Start my trip with Deepin"),@choose_div)
        @end.create_button(=>
            enableZoneDetect(true)
            DCore.Guide.quit()
        )

        @choose_div.style.marginTop = "5em"
        @end.element.style.marginTop = "2em"

