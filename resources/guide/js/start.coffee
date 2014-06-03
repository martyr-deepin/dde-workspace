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


class Start extends Page
    constructor:(@id)->
        super
        echo "Start #{@id}"
        
        inject_css(@element,"css/start.css")
        @option = ["launcher","desktop","dss"]
        @option_text = [_("New Launcher"),_("New Desktop"),_("New System Settings")]
        @message_text = _("We will guide you to learn how to use some new functions")

        @guide_choose_build()

    guide_choose_build : ->
        @guide_choose = create_element("div","guide_choose",@element)
        @menu = new MenuChoose("guide_menu")
        for option,i in @option
            icon_path_normal = "#{@img_src}/#{option}_normal.png"
            icon_path_hover = "#{@img_src}/#{option}_normal.png"
            icon_path_press = "#{@img_src}/#{option}_normal.png"
            @menu.insert(option, @option_text[i], icon_path_normal,icon_path_hover,icon_path_press,true,@message_text)
        @menu.frame_build()
        @menu.show()
        @guide_choose.appendChild(@menu.element)
   
        @start = new ButtonNext("start",_("Start"),@guide_choose)
        @start.create_button(=>
            #TODO:switch_to_page(launcher_page)
            guide?.switch_page(@,"LauncherLaunch")
        )
        @start.element.style.position = "relative"
        @start.element.style.marginTop = "22em"

        
        
        @older = create_element("div","older",@element)
        @older.innerText = _("I am older,exit directly")
        @older.addEventListener("click",(e) =>
            e.stopPropagation()
            #TODO:gtk_main_quit()
            enableZoneDetect(true)
            DCore.Guide.quit()
        )
