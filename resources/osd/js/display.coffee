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

class Display extends Option
    #Display DBus
    DISPLAY = "com.deepin.daemon.Display"
    DISPLAY_MONITORS =
        obj: DISPLAY
        path: "/com/deepin/daemon/Display/MonitorLVDS1"
        interface: "com.deepin.daemon.Display.Monitor"
    #-1 copy 
    #0 expand
    #1 onlyCurrentScreen
    #2 onlySecondScreen
    DEFAULT_DISPLAY_MODE = 0

    constructor:(@id)->
        super
        echo "New Display :#{@id}"
        @Monitors = []
        @DBusMonitors = []
        @DBusOpenedMonitors = []
        @OpenedMonitorsName = []
        @getDBus()
        _b.appendChild(@element)
        
   
    hide:->
        @element.style.display = "none"
    
    set_bg:(imgName)->
        _b.style.backgroundImage = "url(img/#{imgName}.png)"
  
    
    getDBus:->
        try
            @DBusDisplay = DCore.DBus.session(DISPLAY)
            @Monitors = @DBusDisplay.Monitors
            @DisplayMode = @DBusDisplay.DisplayMode
            @HasChanged = @DBusDisplay.HasChanged
        catch e
            echo "Display DBus :#{DISPLAY} ---#{e}---"

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
        @getDBusMonitor(name).Brightness
    
    getPrimarBrightness:->
        white = @getBrightness(@PrimarMonitorName) * 10


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
        
        @valueDiv = create_element("div","valueDiv",@element) if not @valueDiv?
        for i in [0...10]
            @valueEachDiv[i] = create_element("div","valueEachDiv",@valueDiv) if not @valueEachDiv[i]?
            if i <= white then bg = "white"
            else bg = "black"
            echo i + ":" + bg
            @valueEachDiv[i].style.backgroundImage = "../img/#{bg}.png"

    show:->
        clearTimeout(@timeout) if @timeout
        echo "Display Class  show :#{@id}"
        @element.style.display = "block"
        if @id is "DisplayMode" then @switchMode()
        else @showBrightValue()

        @timeout = setTimeout(=>
            @hide()
        ,TIME_HIDE)



BrightnessUpCls = null
BrightnessDownCls = null
DisplaySwitchCls = null

BrightnessUp = ->
    BrightnessUpCls  = new Display("BrightnessUp") if not BrightnessUpCls?
    white = BrightnessUpCls.getVolume()
    white++
    BrightnessUpCls.setVolume(white)
    BrightnessUpCls.show(white)

BrightnessDown = ->
    BrightnessDownCls  = new Display("BrightnessDown") if not BrightnessDownCls?
    white = BrightnessDownCls.getVolume()
    white--
    BrightnessDownCls.setVolume(white)
    BrightnessDownCls.show(white)

DisplaySwitch = ->
    DisplaySwitchCls  = new Display("DisplaySwitch") if not DisplaySwitchCls?
    DisplaySwitchCls.changeMute()
    if DisplaySwitchCls.getMute() then white = 0
    else white = DisplaySwitchCls.getVolume()
    DisplaySwitchCls.show(white)

DBusMediaKey.connect("BrightnessDown",BrightnessDown) if not DBusMediaKey?
DBusMediaKey.connect("BrightnessUp",BrightnessUp) if not DBusMediaKey?
DBusMediaKey.connect("DisplaySwitch",DisplaySwitch) if not DBusMediaKey?
