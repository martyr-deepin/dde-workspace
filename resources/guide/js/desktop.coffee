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
    
    hand_interval = null
    timeout_check_if_done = null
    constructor:(@id)->
        super
        @desktop = new Desktop()
        
        @message = _("Let's drag the other icon on the first icon \n to generate \"application group\"")
        @show_message(@message)

        #@pointer_create()
        @pointer_hand_create()
        @signal()
    
    pointer_hand_create: ->
        @pointer_hand = create_element("div","pointer_hand",@element)
        @pointer_hand.style.display = "-webkit-box"
        @pointer_hand.style.position = "absolute"
        
        _ITEM_HEIGHT_ = 84 + 4 * 2
        @pointer_hand.style.left = 18
        @pointer_hand.style.top = 13
        
        @pointer_up = create_img("pointer_up","#{@img_src}/pointer_up.png",@pointer_hand)
        @hand_img = create_img("hand_img","#{@img_src}/fleur.png",@pointer_hand)
        
        width = height = 64
        @pointer_hand.style.width = width
        @pointer_hand.style.height = height * 2 + 50
        @pointer_up.style.width = @pointer_up.style.height = height
        @pointer_up.style.position = "absolute"
        @pointer_up.style.top = (height * 2 + 50 - height) / 2
        
        @hand_img.style.width = @hand_img.style.height = 24
        @hand_img.style.position = "absolute"
        @hand_img.style.bottom = height / 2
        @hand_img.style.right = 0
        
        @pointer_hand_animation()
        
        jQuery(@pointer_hand).hover(=>
            @stop_pointer_hand_animation()
        ,=>
            @pointer_hand_animation()
        )
        @interval_done()
        #@pointer_hand.addEventListener("mouseover",=>
        #    @stop_pointer_hand_animation()
        #)
        #@pointer_hand.addEventListener("mouseout",=>
        #    @pointer_hand_animation()
        #)

    stop_pointer_hand_animation: ->
        echo "stop_pointer_hand_animation"
        DCore.Guide.disable_guide_region()
        @pointer_up.style.display = "none"
        @hand_img.style.display = "none"
        clearInterval(hand_interval)

    pointer_hand_animation: ->
        echo "pointer_hand_animation"
        DCore.Guide.enable_guide_region()
        width = height = 64
        @pointer_up.style.display = "block"
        @hand_img.style.display = "block"
        move_animation(@hand_img, height / 2,height * 2,"bottom","absolute")
        hand_interval = setInterval(=>
            move_animation(@hand_img, height / 2,height * 2,"bottom","absolute")
        ,2100)


    interval_done: ->
        timeout_check_if_done = setInterval(=>
            if @hand_img.style.display isnt "none" then return
            @pointer_hand_animation()
        ,t_check_if_done)


    pointer_create: ->
        @corner_leftup = new Pointer("circle_richdir",@element)
        @corner_leftup.create_pointer(AREA_TYPE.circle,POS_TYPE.leftup)
        @corner_leftup.set_area_pos(18,13,"fixed",POS_TYPE.leftup)
        @corner_leftup.show_animation()
    
    signal: ->
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
                clearInterval(hand_interval)
                clearTimeout(timeout_check_if_done)
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
        
        @message = _("Slide the mouse to the four top corners, which can trigger four different events\nPlease move to the left up corner first to show or hide Launcher")
        @tips = _("tips：Please trigger successively by hints, click on the blank area to return")
        @show_message(@message)
        @show_tips(@tips)
        
        @message_corner =
            leftup:_("Show/Hide Launcher")
            leftdown:_("Show/Hide Desktop")
            rightdown:_("Show/Hide Control Center")
            rightup:_("No default functions setted in right up corner")
        
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
                enableZoneDetect(true)
                index = i for p,i in that.pos when this.id is p
                echo "#{index}/#{length - 1} #{this.id} mouseenter"
                clearTimeout(switch_page_timeout)
               
                switch_page_timeout = setTimeout(=>
                    if this.id is "leftup" then that.launcher.hide()
                    else if this.id is "rightdown" then that.dss?.hide()
                    if index < length - 1
                        this.display("none")
                        that.show_message(that.message_corner[that.corner[index + 1].id])
                        that.show_tips(" ")
                        that.corner[index + 1].show_animation()
                    else
                        guide?.switch_page(that,"DesktopZone")
                ,t_mid_switch_page)
            ,"mouseover")
            @corner[i].element.addEventListener("mouseout",=>
                enableZoneDetect(false)
            )
            @corner[i].set_area_pos(0,0,"fixed",POS_TYPE[p])
        @corner[0].show_animation()
        

class DesktopZone extends Page
    restack_interval = null
    
    constructor:(@id)->
        super
        
        @message = _("Right-click on desktop black area to call up the menu, select \"Corner navigation\" to set the corner used")
        @tips = _("tips：Click on the interface of corner navigation blank area to return")
        @show_message(@message)
        @show_tips(@tips)
        
        @pos = ["leftup","leftdown","rightdown","rightup"]
        @corner = []
        
        #simulate_rightclick(@,=>
        #    DCore.Guide.enable_keyboard()
        #    @zone_check()
        #)
    
        @menu_create(screen.width * 0.5, screen.height * 0.2,=>
            DCore.Guide.enable_keyboard()
            DCore.Guide.spawn_command_sync("/usr/lib/deepin-daemon/dde-zone",false)
            @zone_check()
        )

    menu_create: (x,y,cb) ->
        @menu =[
            {type:MENU.option,text:_("_Sort by")},
            {type:MENU.option,text:_("_New")},
            {type:MENU.option,text:_("Open in _terminal")},
            {type:MENU.option,text:_("_Paste")},
            {type:MENU.cutline,text:""},
            {type:MENU.option,text:_("_Display settings")},
            {type:MENU.selected,text:_("_Corner navigation")},
            {type:MENU.option,text:_("Pe_rsonalize")}
        ]
        @contextmenu = new ContextMenu("desktop_contextmenu",@element)
        @contextmenu.menu_create(@menu)
        @contextmenu.set_pos(x,y)
        @contextmenu.selected_click(=>
            @element.removeChild(@contextmenu.element)
            cb?()
        )
    
    zone_check: ->
        echo "zone_check"
        interval_is_zone = setInterval(=>
            if(DCore.Guide.is_zone_launched())
                clearInterval(interval_is_zone)
                DCore.Guide.disable_keyboard()
                DCore.Guide.enable_guide_region()
                @pointer_create()
        ,200)

    pointer_create: ->
        if @corner.length != 0 then return
        
        clearInterval(restack_interval)
        interval = 0
        restack_interval = setInterval(=>
            interval++
            DCore.Guide.restack()
            clearInterval(restack_interval) if interval > 20
        ,200)
        
        length = @pos.length
        for p,i in @pos
            @corner[i] = new Pointer(p,@element)
            that = @
            @corner[i].create_pointer(AREA_TYPE.corner,POS_TYPE[p],->
                echo "mouseover"
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
                        DCore.Guide.spawn_command_sync("killall dde-zone",true)
                        clearInterval(restack_interval)
                        guide?.switch_page(that,"DssLaunch")
                ,t_mid_switch_page)
            ,"mouseover")
            @corner[i].set_area_pos(0,0,"fixed",POS_TYPE[p])
        DCore.Guide.enable_guide_region()
        @corner[0].show_animation()

