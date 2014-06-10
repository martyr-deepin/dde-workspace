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
        
        @message = _("Let's overlap the other two icons on the first icon \ngenerate \"application group\"")
        @show_message(@message)
        
        @corner_leftup = new Pointer("circle_richdir",@element)
        @corner_leftup.create_pointer(AREA_TYPE.circle,POS_TYPE.leftup)
        @corner_leftup.set_area_pos(18,13,"fixed",POS_TYPE.leftup)
        @corner_leftup.show_animation()
        
        @desktop?.richdir_signal(=>
            setTimeout(=>
                guide?.switch_page(@,"DesktopRichDirCreated")
            ,t_min_switch_page)
        )
        
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
    switch_page_timeout = null
    
    constructor:(@id)->
        super
        
        #DCore.Guide.launch_zone()
        
        @message = _("Slide the mouse to the four top corners, which can trigger four different events")
        @tips = _("tips：Please trigger successively by hints, click on the blank area to return")
        @show_message(@message)
        @show_tips(@tips)


        @dss = new Dss()
        @launcher = new Launcher()
        @pointer_create()
    
    pointer_create : ->
        @message_righup = _("No default functions setted")

        @pos = ["leftup","leftdown","rightdown","rightup"]
        length = @pos.length
        @corner = []
        for p,i in @pos
            @corner[i] = new Pointer(p,@element)
            that = @
            @corner[i].create_pointer(AREA_TYPE.corner,POS_TYPE[p],->
                index = i for p,i in that.pos when this.id is p
                echo "#{index}/#{length - 1} #{this.id} mouseenter"
                clearTimeout(switch_page_timeout)
                if index == length - 1
                    that.show_message(that.message_righup)
                    that.show_tips(" ")

                switch_page_timeout = setTimeout(=>
                    if this.id is "leftup" then that.launcher.hide()
                    else if this.id is "rightdown" then that.dss?.hide()
                    if index < length - 1
                        that.corner[index + 1].show_animation()
                    else
                        guide?.switch_page(that,"DesktopZone")
                ,t_switch_page)
            ,"mouseover")
            @corner[i].set_area_pos(0,0,"fixed",POS_TYPE[p])
        @corner[0].show_animation()
        

class DesktopZone extends Page
    constructor:(@id)->
        super
        
        @message = _("Right-click on desktop black area to call up the menu, select \"Corner navigation\" to set the corner used")
        @tips = _("tips：Click on the interface of corner navigation blank area to return")
        @show_message(@message)
        @show_tips(@tips)
        @rightclick_check()
    
    rightclick_check: ->
        DCore.Guide.enable_right_click()
        DCore.Guide.disable_guide_region()
        #@element.addEventListener("contextmenu",=>
        #    simulate_rightclick()
        #)
    
    pointer_create: ->
        DCore.Guide.disable_right_click()
        @pos = ["leftup","leftdown","rightdown","rightup"]
        length = @pos.length
        @corner = []
        for p,i in @pos
            @corner[i] = new Pointer(p,@element)
            that = @
            @corner[i].create_pointer(AREA_TYPE.corner,POS_TYPE[p],->
                that.corner[index].display("none")
                
                index = i for p,i in that.pos when this.id is p
                echo "#{index}/#{length - 1} #{this.id} mouseenter"
                clearTimeout(switch_page_timeout)
                switch_page_timeout = setTimeout(=>
                    if index < length - 1
                        that.corner[index + 1].show_animation()
                    else
                        guide?.switch_page(that,"DesktopZone")
                ,t_switch_page)
            ,"mouseover")
            @corner[i].set_area_pos(0,0,"fixed",POS_TYPE[p])
        @corner[0].show_animation()

