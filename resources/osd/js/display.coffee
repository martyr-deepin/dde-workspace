#Copyright (c) 2011 ~ 2013 Deepin, Inc.
#              2011 ~ 2013 yilang
#
#Author:      YuanChenglu <yuanchenglu001@gmail.com>
#Maintainer:  YuanChenglu <yuanchenglu001@gmail.com>
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

class Display extends Option
    constructor:(@id)->
        super
        echo "New Display :#{@id}"
        @Monitors = []
        @DBusMonitors = []
        @DBusOpenedMonitors = []
        @OpenedMonitorsName = []
        try
            @DBusDisplay = DCore.DBus.session(DISPLAY)
            @Monitors = @DBusDisplay.Monitors
            @DisplayMode = @DBusDisplay.DisplayMode
            @HasChanged = @DBusDisplay.HasChanged
            @getDBusMonitors()
        catch e
            echo "Display DBus :#{DISPLAY} ---#{e}---"

    getDBusMonitors:->
        try
            for path in @Monitors
                DISPLAY_MONITORS.path = path
                DBusMonitor = DCore.DBus.session_object(
                    DISPLAY_MONITORS.obj,
                    DISPLAY_MONITORS.path,
                    DISPLAY_MONITORS.interface
                )
                @DBusMonitors.push(DBusMonitor)
                if DBusMonitor.Opened
                    @OpenedMonitorsName.push(DBusMonitor.FullName)
                    @DBusOpenedMonitors.push(DBusMonitor)
                if DBusMonitor.isPrimary
                    @DBusPrimarMonitor = DBusMonitor
                    @PrimarMonitorName = DBusMonitor.FullName
        catch e
            echo "getDBusMonitors ERROR: ---#{e}---"
    
    getDBusMonitor:(name)->
        return dbus = monitor for monitor in @DBusMonitors when monitor.FullName is name
    
    getBrightness:(name)->
        @getDBusMonitor(name).WorkaroundBacklight()
        @getDBusMonitor(name).Brightness
    
    switchMode:->
        @DisplayMode = @DBusDisplay.DisplayMode
        if not @DisplayMode? then @DisplayMode = 0
        @DisplayMode++
        if @DisplayMode > @DBusMonitors.length then @DisplayMode = -1
        echo "SwitchMode(#{@DisplayMode})"
        ImgIndex = @DisplayMode
        if ImgIndex >= 2 then ImgIndex = 2
        @DBusDisplay.SwitchMode_sync(@DisplayMode)
        @set_bg("#{@id}_#{ImgIndex}")

    showBrightValue:->
        white = @getBrightness(@PrimarMonitorName) * 10
        echo "showBrightValue:#{white}."
        @set_bg(@id)
        for i in [0...10]
            @valueDiv = create_elment("div","valueDiv",@element) if not @valueAll?
            @valueEachDiv[i] = create_elment("div","valueEachDiv",@valueDiv) if not @valueEachDiv[i]?
            if i <= white then @valueEachDiv[i].style.backgroundImage = "../img/black.png"
            else @valueEachDiv[i].style.backgroundImage = "../img/white.png"

    show:->
        echo "Display Class  show :#{@id}"
        @element.style.display = "block"
        if @id is "DisplayMode" then @switchMode()
        #else if @id is "Light_Up" or @id is "Light_Down"
        else @showBrightValue()
