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


class Dock
    DOCK_REGION =
        name:"com.deepin.daemon.Dock"
        path:"/dde/dock/DockRegion"
        interface:"dde.dock.DockRegion"
    
    constructor: ->
        try
            @dock_region_dbus = DCore.DBus.session_object(
                DOCK_REGION.name,
                DOCK_REGION.path,
                DOCK_REGION.interface
            )
            @dock_region = @dock_region_dbus.GetDockRegion_sync()
            echo @dock_region
        catch e
            echo "#{DOCK_REGION}: dbus error:#{e}"

    get_icon_pos: (icon_index) ->
        @x0 = @dock_region[0]
        @y0 = @dock_region[1]
        @x1 = @dock_region[2]
        @y1 = @dock_region[3]
        
        pos =
            x0:0
            y0:0
            x1:0
            y1:0
        pos.x0 = @x0 + DOCK_PADDING + ICON_MARGIN_H * icon_index
        pos.y0 = @y0
        pos.x1 = pos.x0 + ICON_SIZE
        pos.y1 = pos.y0 + ICON_SIZE
        
        return pos
    
    get_launchericon_pos: ->
        pos = @get_icon_pos(1)
        return pos

    get_dssicon_pos: ->
        pos = @get_icon_pos(8)
        return pos


class LauncherLaunch extends Page
    constructor:(@id)->
        super
        
        @dock = new Dock()
        
        @message = _("Move the mouse to Left up corner , or you can click the launcher icon to launch \" Application Launcher\"")
        @show_message(@message)
        
        @corner_leftup = new Pointer("corner_leftup",@element)
        @corner_leftup.create_pointer(AREA_TYPE.corner,POS_TYPE.leftup)
        @corner_leftup.set_area_pos(0,0,"fixed",POS_TYPE.leftup)
        
        @launcher_circle = new Pointer("launcher_circle",@element)
        @launcher_circle.create_pointer(AREA_TYPE.circle,POS_TYPE.rightdown)
        @launcher_pos = @dock.get_launchericon_pos()
        @launcher_circle_x = @launcher_pos.x0 - @launcher_circle.pointer_width
        @launcher_circle_y = @launcher_pos.y0 - @launcher_circle.pointer_height - ICON_MARGIN_V_BOTTOM / 2
        @launcher_circle.set_area_pos(@launcher_circle_x,@launcher_circle_y,"fixed",POS_TYPE.leftup)


class LauncherCollect extends Page
    constructor:(@id)->
        super
        
        @rect = new Rect("collectApp",@element)
        @rect.create_rect(1096,316)#1096*316
        @rect.set_pos(135,80)
        
        @message = _("There are some collect applications in the first page of \"launcher\"")
        @show_message(@message)
        @message_div.style.marginTop = "150px"

class LauncherAllApps extends Page
    constructor:(@id)->
        super
        
        @pointer = new Pointer("ClickToAllApps",@element)
        @pointer.create_pointer(AREA_TYPE.circle,POS_TYPE.leftup)
        @pointer.set_area_pos(25,25)
        
        @message = _("There are some collect applications in the first page of \"launcher\"")
        @show_message(@message)

class LauncherScroll extends Page
    constructor:(@id)->
        super
        
        @rect = new Rect("collectApp",@element)
        @rect.create_rect(64,435)#1096*316
        @rect.set_pos(25,125)
        
        @pointer = new Pointer("classify",@element)
        @pointer.create_pointer(AREA_TYPE.circle,POS_TYPE.leftup)
        @pointer.set_area_pos(25,192)
        
        @message = _("Scroll the mouse to check all applications\n And you can click the left classification to locate")
        @show_message(@message)

        @scroll = create_element("div","srcoll",@element)
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


