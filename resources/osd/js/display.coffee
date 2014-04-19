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
        name: DISPLAY
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
        @ModeChoose = DEFAULT_DISPLAY_MODE

        _b.appendChild(@element)
        @getDBus()
        
        @DisplayModeList = [
            _("Copy"),
            _("Expand"),
            _("Only the first Screen"),
            _("Only the second Screen")
        ]
        @DisplayModeValue = [-1,0,1,2]
        
        _b.addEventListener("keyup",(e)=>
            if e.which == KEYCODE.WIN and @FromSwitchMonitors
                @switchDisplayMode(@ModeChoose)
        )

    hide:->
        @element.style.display = "none"

    getDBus:->
        try
            @DBusDisplay = get_dbus("session", DISPLAY, "Monitors")
            @Monitors = @DBusDisplay.Monitors
            @DisplayMode = @DBusDisplay.DisplayMode
            @HasChanged = @DBusDisplay.HasChanged
            @PrimarMonitorName = @DBusDisplay.Primary
        catch e
            echo "Display DBus :#{DISPLAY} ---#{e}---"

        try
            for path in @Monitors
                DISPLAY_MONITORS.path = path
                DBusMonitor = get_dbus("session", DISPLAY_MONITORS, "FullName")
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
            value = bright[name]
        catch e
            echo "getPrimarBrightnessValue: ERROR: #{e}"
        finally
            return value
    
    getCurrentMode:->
        @DisplayMode = @DBusDisplay.DisplayMode
        if @DisplayMode is null then @DisplayMode = 0
        @currentMode = @DisplayModeList[i] for each,i in @DisplayModeValue when vale == @DisplayMode
        return @currentMode

    setCurrentMode:(current)->
        @FromSwitchMonitors = true
        Modei = i for each,i in @DisplayModeList when each is current
        ModeChoose = @DisplayModeValue[Modei]
        @switchDisplayMode2(ModeChoose)
    
    switchDisplayMode2:(ModeChoose)->
        setFocus(true)
        osdHide()

        if @DBusMonitors.length < 2 then return
        if ModeChoose > @DBusMonitors.length then ModeChoose = -1

        echo "SwitchMode to (#{ModeChoose})"
        @DBusDisplay.SwitchMode_sync(ModeChoose)
        @FromSwitchMonitors = false


    switchDisplayMode:(ModeChoose)->
        setFocus(false)
        osdHide()

        if @DBusMonitors.length == 1 then return
        @DisplayMode = @DBusDisplay.DisplayMode
        if not @DisplayMode? then @DisplayMode = 0
        @DisplayMode++
        if @DisplayMode > @DBusMonitors.length then @DisplayMode = -1

        ModeChoose = @DisplayMode
        echo "SwitchMode to (#{ModeChoose})"
        @DBusDisplay.SwitchMode_sync(ModeChoose)
        @FromSwitchMonitors = false


    showDisplayMode:->
        clearTimeout(@timepress)
        clearTimeout(timeout_osdHide)

        @timepress = setTimeout(=>
            @FromSwitchMonitors = true
            @valueDiv.style.display = "none" if @valueDiv
            if @DBusMonitors.length == 1 then return

            osdShow()
            @element.style.display = "block"
            # @DisplayMode = @DBusDisplay.DisplayMode
            #@SwitchMode++
            #if @SwitchMode > @DBusMonitors.length then @DisplayMode = -1
            @DisplayMode = @DBusDisplay.DisplayMode
            ImgIndex = @DisplayMode
            if ImgIndex >= 2 then ImgIndex = 2
            imgName = "#{@id}_#{ImgIndex}"
            set_bg(@,imgName,@preDisplayImg)
            @preDisplayImg = imgName

            timeout_osdHide = setTimeout(osdHide,TIME_HIDE)
        ,TIME_PRESS)


    showBrightness:->
        clearTimeout(@timepress) if @timepress
        @timepress = setTimeout(=>
            clearTimeout(timeout_osdHide) if timeout_osdHide?

            echo "#{@id} Class  show"
            osdShow()
            @element.style.display = "block"

            value = @getPrimarBrightnessValue()
            echo "showBrightValue:#{value}"
            set_bg(@,@id,@prebgImg)
            @prebgImg = @id

            showValue(value,0,1,@,"Brightness_bar")
            timeout_osdHide = setTimeout(=>
                osdHide()
            ,TIME_HIDE)
        ,TIME_PRESS)


BrightCls = null
displayModeList = null

BrightnessUp = (keydown)->
    if keydown then return
    setFocus(false)
    echo "BrightnessUp"
    BrightCls  = new Display("Brightness") if not BrightCls?
    BrightCls.id = "BrightnessUp"
    BrightCls.showBrightness()

BrightnessDown = (keydown)->
    if keydown then return
    setFocus(false)
    echo "BrightnessDown"
    BrightCls  = new Display("Brightness") if not BrightCls?
    BrightCls.id = "BrightnessUp"#the backgroundImage is same ,so the @id can equal to BrightnessUp
    BrightCls.showBrightness()

DisplaySwitch = (keydown)->
    if keydown then return
    setFocus(true)
    echo "SwitchMonitors"
    BrightCls  = new Display("DisplaySwitch") if not BrightCls?
    BrightCls.id = "DisplaySwitch"
    if BrightCls.DBusMonitors.length < 2 then return
    
    if not DEBUG
        BrightCls.showDisplayMode()
        return
    
    if not displayModeList?
        displayModeList = new ListChoose("displayModeList")
        displayModeList.setParent(_b)
        displayModeList.setSize("100%","100%")
        displayModeList.ListAllBuild(BrightCls.DisplayModeList,BrightCls.getCurrentMode())

    current = displayModeList.chooseIndex()
    echo "6"
    BrightCls.setCurrentMode(current)
    echo "7"


    

DBusMediaKey.connect("BrightnessDown",BrightnessDown) if DBusMediaKey?
DBusMediaKey.connect("BrightnessUp",BrightnessUp) if DBusMediaKey?
DBusMediaKey.connect("SwitchMonitors",DisplaySwitch) if DBusMediaKey?
