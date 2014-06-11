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
        DCore.Guide.disable_guide_region()
        @desktop = new Desktop()
        
        @message = _("Let's overlap the other two icons on the first icon \ngenerate \"application group\"")
        @show_message(@message)
        
        @corner_leftup = new Pointer("circle_richdir",@element)
        @corner_leftup.create_pointer(AREA_TYPE.circle,POS_TYPE.leftup)
        @corner_leftup.set_area_pos(18,13,"fixed",POS_TYPE.leftup)
        @corner_leftup.show_animation()
        
        signal_times = 0
        signal_times_switch = 1 * (desktop_file_numbers - 1)
        @desktop?.item_signal(=>
            signal_times++
            echo "richdir_signal times:#{signal_times}"
            if signal_times == signal_times_switch then signal_times = 0
            else return
            
            setTimeout(=>
                @desktop?.item_signal_disconnect()
                DCore.Guide.enable_guide_region()
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
        enableZoneDetect(true)
        
        @message = _("Slide the mouse to the four top corners, which can trigger four different events")
        @tips = _("tips：Please trigger successively by hints, click on the blank area to return")
        @show_message(@message)
        @show_tips(@tips)

        @message_righup = _("No default functions setted")
        @message_leftdown = _("Show Desktop")
        @pos = ["leftup","leftdown","rightdown","rightup"]
        @corner = []

        @dss = new Dss()
        @launcher = new Launcher()
        @pointer_create()
    
    pointer_create : ->
        if @corner.length != 0 then return
        length = @pos.length
        for p,i in @pos
            @corner[i] = new Pointer(p,@element)
            that = @
            @corner[i].create_pointer(AREA_TYPE.corner,POS_TYPE[p],->
                index = i for p,i in that.pos when this.id is p
                echo "#{index}/#{length - 1} #{this.id} mouseenter"
                clearTimeout(switch_page_timeout)
                if this.id is "rightup"
                    that.show_message(that.message_righup)
                    that.show_tips(" ")
                else if this.id is "leftdown"
                    that.show_message(that.message_leftdown)
                    that.show_tips(" ")

                switch_page_timeout = setTimeout(=>
                    if this.id is "leftup" then that.launcher.hide()
                    else if this.id is "rightdown" then that.dss?.hide()
                    if index < length - 1
                        that.corner[index + 1].show_animation()
                    else
                        guide?.switch_page(that,"DesktopZone")
                ,t_mid_switch_page)
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
        
        @pos = ["leftup","leftdown","rightdown","rightup"]
        @corner = []
        
        simulate_rightclick(@,=>
            @zone_check()
        )
    
    
    zone_check: ->
        #TODO:check zone launched signal to use pointer_create function
        echo "zone_check"
        interval_is_zone = setInterval(=>
            if(DCore.Guide.is_zone_launched())
                clearInterval(interval_is_zone)
                @pointer_create()
        ,500)

    pointer_create: ->
        if @corner.length != 0 then return
        length = @pos.length
        for p,i in @pos
            @corner[i] = new Pointer(p,@element)
            that = @
            @corner[i].create_pointer(AREA_TYPE.corner,POS_TYPE[p],->
                this.display("none")
                DCore.Guide.disable_guide_region()
                
                index = i for p,i in that.pos when this.id is p
                echo "#{index}/#{length - 1} #{this.id} mouseenter"
                clearTimeout(switch_page_timeout)
                switch_page_timeout = setTimeout(=>
                    if index < length - 1
                        DCore.Guide.enable_guide_region()
                        that.corner[index + 1].show_animation()
                    else
                        DCore.Guide.spawn_command_sync("killall dde-zone")
                        guide?.switch_page(that,"DssLaunch")
                ,t_mid_switch_page)
            ,"mouseover")
            @corner[i].set_area_pos(0,0,"fixed",POS_TYPE[p])
        DCore.Guide.enable_guide_region()
        @corner[0].show_animation()

