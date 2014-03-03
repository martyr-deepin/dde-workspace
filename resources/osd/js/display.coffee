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
        catch e
            echo "getDBusMonitors ERROR: ---#{e}---"
    
    getDBusMonitor:(name)->
        return dbus = monitor for monitor in @DBusMonitors when monitor.FullName is name
    
    getBrightness:(name)->
        #@getDBusMonitor(name).BackgroundBright()
        @getDBusMonitor(name).Brightness
    
    setBrightness:(name,bright)->
        #@getDBusMonitor(name).BackgroundBright()
        @getDBusMonitor(name).Brightness = bright

    SwitchMode:(mode)->
        #-1 onlyCurrentScreen
        #0 copy
        #1 onlySecondScreen
        #2 expand
        if Math.abs(mode) > @DBusMonitors.length
            echo "the SwitchMode mode #{mode} input outof @DBusMonitors.length:#{@DBusMonitors.length}"
            if mode < 0 then mode = @DBusMonitors.length * -1
            if mode > 0 then mode = @DBusMonitors.length
        @DBusDisplay.SwitchMode(mode)
