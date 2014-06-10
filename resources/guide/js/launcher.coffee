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
        
        @dock = new Dock()
        @launcher = new Launcher()
        
        @message = _("Sliding the mouse to the upper left corner or clicking on the launcher icon both can start \"Application Launcher\"")
        @show_message(@message)
        
        @corner_leftup = new Pointer("corner_leftup",@element)
        @corner_leftup.create_pointer(AREA_TYPE.corner,POS_TYPE.leftup)
        @corner_leftup.set_area_pos(0,0,"fixed",POS_TYPE.leftup)
        @corner_leftup.show_animation()
        
        @circle = new Pointer("launcher_circle",@element)
        @circle.create_pointer(AREA_TYPE.circle,POS_TYPE.rightdown,=>
            @launcher?.show()
        )
        @pos = @dock.get_launchericon_pos()
        @circle_x = @pos.x0 - @circle.pointer_width + ICON_MARGIN_H
        @circle_y = @pos.y0 - @circle.pointer_height - ICON_MARGIN_V_BOTTOM / 2
        @circle.set_area_pos(@circle_x,@circle_y,"fixed",POS_TYPE.leftup)
        @circle.show_animation()

        @launcher.show_signal(@show_signal_cb)
    
    show_signal_cb:=>
        @element.style.display = "none"
        setTimeout(=>
            guide?.switch_page(@,"LauncherCollect")
            @launcher.show_signal_disconnect()
        ,t_min_switch_page)

        
class LauncherCollect extends Page
    constructor:(@id)->
        super
        
        @rect = new Rect("collectApp",@element)
        @rect.create_rect(1096,316)#1096*316
        @rect.set_pos(135,80)
        @rect.show_animation(=>
            setTimeout(=>
                guide?.switch_page(@,"LauncherAllApps")
            ,t_min_switch_page)
        )
        
        @message = _("What shown in the first screen of \" launcher\" are the applications of collection")
        @show_message(@message)
        @msg_tips.style.marginTop = "150px"

class LauncherAllApps extends Page
    constructor:(@id)->
        super

        @pointer = new Pointer("ClickToAllApps",@element)
        @pointer.create_pointer(AREA_TYPE.circle,POS_TYPE.leftup, (e)=>
            simulate_click(CLICK_TYPE.leftclick,@,"LauncherScroll")
        )
        @pointer.set_area_pos(25,25)
        @pointer.show_animation()
        
        @message = _("Please click on the \"All Applications\" icon , you will see all applications")
        @show_message(@message)

class LauncherScroll extends Page
    constructor:(@id)->
        super
        @scrollup = false
        @scrolldown = false
        
        @rect = new Rect("collectApp",@element)
        @rect.create_rect(64,435)#1096*316
        @rect.set_pos(25,125)
        
        @pointer = new Pointer("classify",@element)
        @pointer.create_pointer(AREA_TYPE.circle,POS_TYPE.leftup,=>
            simulate_click(CLICK_TYPE.leftclick,@,"LauncherSearch")
        )
        @pointer.set_area_pos(25,192)
        
        @message = _("All programs can be seen by scrolling the mouse up and down\nYou can also click on the left classification navigation to locate")
        @show_message(@message)

        @scroll = create_element("div","scroll",@element)
        @scroll.style.position = "absolute"
        @scroll.style.top = "37%"
        @scroll.style.right = "200px"
        
        @scroll_down = create_img("scroll_down","#{@img_src}/pointer_down.png",@scroll)
        @scroll_up = create_img("scroll_up","#{@img_src}/pointer_up.png",@scroll)
        
        width = height = 64
        @scroll.style.width = width
        @scroll.style.height = height * 2 + 50
        @scroll_down.style.width = @scroll_up.style.width = width
        @scroll_down.style.height = @scroll_up.style.height = height
        @scroll_up.style.position = "absolute"
        @scroll_up.style.left = 0
        @scroll_up.style.bottom = 0

        @element.addEventListener("mousewheel", (e)=>
            if @scrollup and @scrolldown and @pointer.element.style.display is "none"
                @pointer.show_animation()
            
            if e.wheelDelta >= 120
                @scrollup = true
                simulate_click(CLICK_TYPE.scrollup)
            else if e.wheelDelta <= -120
                @scrolldown = true
                simulate_click(CLICK_TYPE.scrolldown)
        )

class LauncherSearch extends Page
    constructor:(@id)->
        super
        
        @message = _("Use the keyboard searching to find applications you want\nWe try\"deepin\" keyword to see which applications shown")
        @tips = _("tips：Please directly enter the word \"deepin\"")
        @show_message(@message)
        @show_tips(@tips)

        deepin_keysym = [68,69,69,80,73,78]
        setTimeout(=>
            simulate_input(deepin_keysym,@,"LauncherRightclick")
        ,20)

class LauncherRightclick extends Page
    constructor:(@id)->
        super
        
        @message = _("Click the right mouse button on the application icon to call up the context menu\nClicking on the menu item will achieve its function")
        @tips = _("tips:You can also directly use the left mouse button to drag the icon to the dock, favicon or trash")
        @show_message(@message)
        @show_tips(@tips)
        setTimeout(=>
            guide?.switch_page(@,"LauncherMenu")
        ,t_switch_page)

class LauncherMenu extends Page
    constructor:(@id)->
        super
        
        @launcher = new Launcher()
        @desktop = new Desktop()
        
        @message = _("Use the right mouse button to send three icons to the desktop")
        @show_message(@message)
        
        DCore.Guide.disable_guide_region()
        @element.addEventListener("contextmenu",=>
            simulate_rightclick()
        )
        @launcher?.hide_signal(=>
            @launcher?.show()
        )
        @desktop?.desktop_file_signal(=>
            setTimeout(=>
                @launcher.hide_signal_disconnect()
                guide?.switch_page(@,"DesktopRichDir")
                @launcher?.hide()
                DCore.Guide.show_desktop()
            ,t_min_switch_page)
        )

