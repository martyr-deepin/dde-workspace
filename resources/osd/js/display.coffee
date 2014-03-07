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

class Display extends Widget
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
        @valueEach = []
        
        _b.appendChild(@element)
        @getDBus()
   
    hide:->
        @element.style.display = "none"
    
    set_bg:(imgName)->
        @element.style.backgroundImage = "url(img/#{imgName}.png)"
  
    
    getDBus:->
        try
            @DBusDisplay = DCore.DBus.session(DISPLAY)
            @Monitors = @DBusDisplay.Monitors
            @DisplayMode = @DBusDisplay.DisplayMode
            @HasChanged = @DBusDisplay.HasChanged
            @PrimarMonitorName = @DBusDisplay.Primary
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
                echo DBusMonitor
                @DBusMonitors.push(DBusMonitor)
                if DBusMonitor.Opened
                    @OpenedMonitorsName.push(DBusMonitor.FullName)
                    @DBusOpenedMonitors.push(DBusMonitor)
                if DBusMonitor.FullName is @PrimarMonitorName
                    @DBusPrimarMonitor = DBusMonitor
        catch e
            echo "getDBusMonitors ERROR: ---#{e}---"
    
    getDBusMonitor:(name)->
        return dbus = monitor for monitor in @DBusMonitors when monitor.FullName is name
    
    getBrightness:(name)->
        @getDBusMonitor(name).Brightness
    
    getPrimarBrightnessValue:->
        name = @PrimarMonitorName
        bright = @getBrightness(name) if name?
        value = null
        try
            echo "#{name}:#{bright[name]}"
            value = bright[name] * 10
        catch e
            echo "getPrimarBrightnessValue: ERROR: #{e}"
            value = null
        finally
            return value
    
    switchDisplayMode:->
        if @DBusMonitors.length == 1 then return
        @DisplayMode = @DBusDisplay.DisplayMode
        if not @DisplayMode? then @DisplayMode = 0
        @DisplayMode++
        if @DisplayMode > @DBusMonitors.length then @DisplayMode = -1
        echo "SwitchMode to (#{@DisplayMode})"
        @DBusDisplay.SwitchMode_sync(@DisplayMode)


    showValue:(white)->
        if white is null then return
        else if white > 10 then white = 10
        else if white < 0 then white = 0
        @valueDiv = create_element("div","valueDiv",@element) if not @valueDiv?
        @valueDiv.style.display = "-webkit-box"
        for i in [0...10]
            @valueEach[i] = create_img("valueEach","",@valueDiv) if @valueEach[i] is undefined
            if i < white then valueBg = "white"
            else valueBg = "black"
            @valueEach[i].src = "img/#{valueBg}.png"
            @valueEach[i].style.display = "block"

    showDisplayMode:->
        clearTimeout(@timeout) if @timeout
        @valueDiv.style.display = "none" if @valueDiv
        if @DBusMonitors.length == 1 then return

        # @DisplayMode = @DBusDisplay.DisplayMode
        ImgIndex = @DisplayMode
        if ImgIndex >= 2 then ImgIndex = 2
        @set_bg("#{@id}_#{ImgIndex}")

        @timeout = setTimeout(=>
            @hide()
        ,TIME_HIDE)
    
    showBrightness:->
        clearTimeout(@timepress) if @timepress
        @timepress = setTimeout(=>
            clearTimeout(@timeout) if @timeout

            echo "#{@id} Class  show"
            @element.style.display = "block"
            white = @getPrimarBrightnessValue()
            echo "showBrightValue:#{white}"
            @set_bg(@id)
            @showValue(white)
            @timeout = setTimeout(=>
                osdHide()
            ,TIME_HIDE)
        ,TIME_PRESS)


BrightCls = null

BrightnessUp = (keydown)->
    if keydown then return
    osdShow()
    echo "BrightnessUp"
    BrightCls  = new Display("Brightness") if not BrightCls?
    BrightCls.id = "BrightnessUp"
    BrightCls.showBrightness()

BrightnessDown = (keydown)->
    if keydown then return
    osdShow()
    echo "BrightnessDown"
    BrightCls  = new Display("Brightness") if not BrightCls?
    BrightCls.id = "BrightnessDown"
    BrightCls.showBrightness()

DisplaySwitch = (keydown)->
    if keydown then return
    osdShow()
    echo "DisplaySwitch"
    BrightCls  = new Display("DisplaySwitch") if not BrightCls?
    BrightCls.id = "DisplaySwitch"
    BrightCls.switchDisplayMode()
    BrightCls.showDisplayMode()

DBusMediaKey.connect("BrightnessDown",BrightnessDown) if DBusMediaKey?
DBusMediaKey.connect("BrightnessUp",BrightnessUp) if DBusMediaKey?
DBusMediaKey.connect("DisplaySwitch",DisplaySwitch) if DBusMediaKey?
