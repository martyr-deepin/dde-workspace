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
        
        DOCK_PADDING = 24
        ICON_MARGIN_H = 6
        ICON_MARGIN_V_TOP = 3
        ICON_MARGIN_V_BOTTOM = 30
        ICON_SIZE = 48
        
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
        
        echo "LauncherLaunch : #{@id}"
        
        inject_css(@element,"css/launcher.css")
        @img_src = "img/"
        @dock = new Dock()
        
        @message = _("Move the mouse to Left up corner , or you can click the launcher icon to launch \" Application Launcher\"")
        @show_message(@message)
        
        @leftup = create_element("div","leftup",@element)
        @corner_leftup = create_img("corner_leftup","#{@img_src}/corner_leftup.png",@leftup)
        @pointer_leftup = create_img("pointer_leftup","#{@img_src}/pointer_leftup.png",@leftup)


        @launcher_icon = create_element("div","launcher_icon",@element)
        @pointer_rightdown = create_img("pointer_rightdown","#{@img_src}/pointer_rightdown.png",@launcher_icon)
        @circle = create_img("circle","#{@img_src}/circle.png",@launcher_icon)
        @launcher_pos = @dock.get_launchericon_pos()
        set_pos(@circle,@launcher_pos.x0,@launcher_pos.y0)

