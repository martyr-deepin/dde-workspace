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
        #Fixed the top must set by the displaymode of dock
        offsetY = 0
        if _dm != DisplayMode.Fashion
            offsetY = 92 * 2
        @pointer_hand.style.left = 18
        @pointer_hand.style.top = 13 + offsetY
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
        @switch_page_start = false
        @desktop?.richdir_signal(=>
            if @switch_page_start then return
            setTimeout(=>
                @desktop?.richdir_signal_disconnect()
                DCore.Guide.enable_guide_region()
                clearInterval(hand_interval)
                clearTimeout(timeout_check_if_done)
                @switch_page_start = true
                guide?.switch_page(@,"DesktopRichDirCreated")
            ,t_min_switch_page)
        )

class DesktopRichDirCreated extends Page
    constructor:(@id)->
        super
        @message = _("Well, you have learned how to create a \"application group\"")
        @tips = _("tips: Right-click on the application group will provide more functions")
        @show_message(@message)
        @show_tips(@tips)
        setTimeout(=>
            guide?.switch_page(@,"DesktopCornerInfo")
        ,t_switch_page)

class DesktopCornerInfo extends Page
    constructor:(@id)->
        super
        @message = _("Slide the mouse to the four top corners, which can trigger four different events")
        @show_message(@message)

        @pointer_create()

    pointer_create : ->
        @corner = []
        pos = ["leftup","leftdown","rightdown","rightup"]
        if @corner.length != 0 then return
        for p,i in pos
            @corner[i] = new Pointer(p,@element)
            @corner[i].create_pointer(AREA_TYPE.corner,POS_TYPE[p],null)
            @corner[i].pointer_img.style.opacity = 0
            @corner[i].set_area_pos(0,0,"fixed",POS_TYPE[p])
            @corner[i].show_animation()
        setTimeout(=>
            guide?.switch_page(@,"DesktopCornerLeftUp")
        ,t_mid_switch_page)

class DesktopCornerLeftUp extends Page
    constructor:(@id)->
        super
        @message = _("We already know that launcher can be shown/ hidden by sliding the mouse to the upper left corner")
        @show_message(@message)

        enableZoneDetect(true)
        @pointer_create()

    pointer_create : ->
        p = "leftup"
        @corner = new Pointer(p,@element)
        @corner.create_pointer(AREA_TYPE.corner,POS_TYPE[p],null)
        @corner.pointer_img.style.opacity = 0
        @corner.set_area_pos(0,0,"fixed",POS_TYPE[p])
        @corner.show_animation()
        setTimeout(=>
            launcher = new Launcher()
            launcher.hide()
            guide?.switch_page(@,"DesktopCornerLeftDown")
        ,t_mid_switch_page)

class DesktopCornerLeftDown extends Page
    constructor:(@id)->
        super
        @message =_("The workspace will be shown or hidden by sliding the mouse to the lower left corner")
        @show_message(@message)

        DCore.Guide.spawn_command_sync("/usr/bin/xdg-open computer:///",false)
        @pointer_create()

    pointer_create : ->
        p = "leftdown"
        @corner = new Pointer(p,@element)
        mouseovered = false
        @corner.create_pointer(AREA_TYPE.corner,POS_TYPE[p],=>
            DCore.Guide.spawn_command_sync("/usr/lib/deepin-daemon/desktop-toggle",false)
            if !mouseovered
                setTimeout(=>
                    DCore.Guide.spawn_command_sync("pkill nautilus",false)
                    guide?.switch_page(@,"DssLaunch")
                ,t_mid_switch_page)
            mouseovered = true
        ,"mouseover")
        @corner.set_area_pos(0,0,"fixed",POS_TYPE[p])
        @corner.show_animation()

class DesktopCornerRightUp extends Page
    constructor:(@id)->
        super
        @message = _("No functions are set in default on the upper right corner\nRight-click on desktop black area to call up the menu, select \"Corner navigation\" to set the corner used")
        @tips = _("tips: Click on the corner navigation blank area to return")
        @show_message(@message)
        @show_tips(@tips)

        dss = new Dss()
        dss.hide()
        @pointer_create()

    pointer_create : ->
        p = "rightup"
        @corner = new Pointer(p,@element)
        @corner.create_pointer(AREA_TYPE.corner,POS_TYPE[p],null)
        @corner.pointer_img.style.opacity = 0
        @corner.set_area_pos(0,0,"fixed",POS_TYPE[p])
        @corner.show_animation()
        setTimeout(=>
            guide?.switch_page(@,"DesktopZoneSetting")
        ,t_switch_page)

class DesktopZoneSetting extends Page
    restack_interval = null
    constructor:(@id)->
        super
        @pos = ["leftup","leftdown","rightdown","rightup"]
        @corner = []
        @show_message(" ")
        @show_tips(" ")
        DCore.Guide.enable_keyboard()
        DCore.Guide.spawn_command_sync("/usr/lib/deepin-daemon/dde-zone -d",false)
        @zone_check()

    zone_check: ->
        echo "zone_check"
        interval_is_zone = setInterval(=>
            if(DCore.Guide.is_zone_launched())
                DCore.Guide.enable_guide_region()
                t = @mouse_moveon_option()
                clearInterval(interval_is_zone)
                setTimeout(=>
                    @switch_page()
                ,t + 1000)
        ,200)

    mouse_moveon_option: ->
        OPT_WIDTH = 160
        OPT_HEIGHT = 30
        t_mousemove = 1000
        x0 = document.body.clientWidth - OPT_WIDTH / 2
        y0 = 40
        move_mouse(x0,y0,false)
        t = null
        #TODO:
        #here should make the zone setting menu always show
        for i in [1...6]
            t = t_mousemove * i
            setTimeout(->
                y0 += OPT_HEIGHT
                move_mouse(x0,y0,false)
            ,t)
        t

    switch_page: =>
        DCore.Guide.spawn_command_sync("killall dde-zone",true)
        clearInterval(restack_interval)
        guide?.switch_page(@,"End")
