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
        try
            @DBusDisplay = DCore.DBus.session(DISPLAY)
            @Monitors = []
            @Monitors = @DBusDisplay.Monitors
            @DisplayMode = @DBusDisplay.DisplayMode
            @HasChanged = @DBusDisplay.HasChanged
            @getDBusMonitors()
        catch e
            echo "Display DBus :#{DISPLAY} ---#{e}---"


    getDBusMonitors:->
        @DBusMonitors = []
        try
            for path in @Monitors
                DISPLAY_MONITORS.path = path
                DBusMonitor = DCore.DBus.session_object(
                    DISPLAY_MONITORS.obj,
                    DISPLAY_MONITORS.path,
                    DISPLAY_MONITORS.interface
                )
                FullName = DBusMonitor.FullName
                Name = DBusMonitor.Name
                Opened = DBusMonitor.Opened
                IsComposited = DBusMonitor.IsComposited
                IsPrimary = DBusMonitor.IsPrimary
                Brightness = DBusMonitor.Brightness
                BestMode = DBusMonitor.BestMode
                CurrentMode = DBusMonitor.CurrentMode
                Rotation = DBusMonitor.Rotation
                monitor =
                    DBusMonitor: DBusMonitor,
                    FullName: FullName,
                    Name: Name,
                    Opened: Opened,
                    IsComposited: IsComposited,
                    IsPrimary: IsPrimary,
                    Brightness: Brightness,
                    BestMode: BestMode,
                    CurrentMode: CurrentMode,
                    Rotation: Rotation
                @DBusMonitors.push(monitor)
        catch e
            echo "getDBusMonitors ERROR: ---#{e}---"
        finally
            echo @DBusMonitors
            return @DBusMonitors



