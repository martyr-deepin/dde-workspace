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

#-1 copy
#0 expand
#1 onlyCurrentScreen
#2 onlySecondScreen
MODE =
    duplicate:-1
    extend:0
    only_init:1
    min:-1
    max:2
DEFAULT_DISPLAY_MODE = MODE.extend

class Monitor extends Display

    constructor:(@id)->
        super
        @MonitorListChoose = [
            {name:_("Duplicate"),value:MODE.duplicate,img:"duplicate"},
            {name:_("Extend"),value:MODE.extend,img:"extend"}
        ]
        @setMode = {}

    createDisplayMonitorsList: ->
        MODE.max = @MonitorsName.length
        only_init = MODE.only_init
        for name in @MonitorsName
            mode = {name:@getFullName(name),value:only_init++,img:"onlyone"}
            @MonitorListChoose.push(mode)
        echo "@MonitorListChoose.length:#{@MonitorListChoose.length}"

    getCurrentMode:->
        @DisplayMode = @DBusDisplay.DisplayMode
        if @DisplayMode is null then @DisplayMode = MODE.extend
        @currentMode = mode for mode in @MonitorListChoose when mode.value == @DisplayMode
        return @currentMode

    switchDisplayMode:(mode)->
        value = mode.value
        value = DEFAULT_DISPLAY_MODE if value > @MonitorsName.length or value < MODE.min
        echo "SwitchMode(#{value})"
        cmd = "dbus-send --dest=com.deepin.daemon.Display --type=method_call /com/deepin/daemon/Display com.deepin.daemon.Display.SwitchMode int16:#{value}"
        DCore.Osd.spawn_command(cmd)

MonitorListChoose = null
cls = null

HARDWARE_KEYCODE =
    SUPER:133
    KEY_P:33

osd.SwitchMonitors = (keydown)->
    if !keydown then return if mode is "dbus"

    cls = new Monitor("SwitchMonitors") if not cls?
    if cls.MonitorsName.length < 2
        osdHide()
        return

    if not MonitorListChoose?
        cls.createDisplayMonitorsList()
        MonitorListChoose = new ImgListChoose("MonitorListChoose")
        MonitorListChoose.setParent(_b)
        MonitorListChoose.ListAllBuild(cls.MonitorListChoose,cls.getCurrentMode())
        clearTimeout(timeout_osdHide)
        timeout_osdHide = setTimeout(osdHide,5000)
    DCore.signal_connect("key-release-super",->
        clearTimeout(timeout_osdHide)
        if cls
            cls.switchDisplayMode(cls.setMode)
        osdHide()
    )
    DCore.signal_connect("key-release-p",->
        clearTimeout(timeout_osdHide)
        if cls and MonitorListChoose
            cls.setMode = MonitorListChoose.chooseOption()
    )

