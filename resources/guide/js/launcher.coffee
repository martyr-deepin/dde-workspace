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

class LauncherLaunch extends Page
    constructor:(@id)->
        super
        
        echo "LauncherLaunch : #{@id}"
        
        inject_css(@element,"css/launcher.css")
        @img_src = "img/"
        
        @message = _("Move the mouse to Left up corner , or you can click the launcher icon to launch \" Application Launcher\"")
        @show_message(@message)
        
        @leftup = create_element("div","leftup",@element)
        @area_leftup = create_img("area_leftup","#{@img_src}/area_leftup.png",@leftup)
        @pointer_leftup = create_img("pointer_leftup","#{@img_src}/pointer_to_leftup.png",@leftup)


        @launcher_icon = create_element("div","launcher_icon",@element)
        @pointer_rightdown = create_img("pointer_rightdown","#{@img_src}/pointer_to_rightdown.png",@launcher_icon)
        @circle = create_img("circle","#{@img_src}/circle.png",@launcher_icon)




