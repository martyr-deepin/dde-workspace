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

    constructor:(@id)->
        super
        echo "New Display :#{@id}"
        @MonitorsName = []
        @MonitorsFullName = []
        @FeatureMonitorsName = []

        _b.appendChild(@element)
        @getDBus()

    hide:->
        @element.style.display = "none"

    getDBus:->
        try
            @DBusDisplay = DCore.DBus.session(DISPLAY)
            keys = Object.keys(@DBusDisplay.Brightness)
            for key in keys
                @MonitorsName.push(key)
                @MonitorsFullName.push(key)
            @PrimarMonitorName = @DBusDisplay.Primary
            @getFeatureMonitorsName()
        catch e
            echo "Display DBus :#{DISPLAY} ---#{e}---"

    getFullName:(name)->
        return @MonitorsFullName[i] for _name,i in @MonitorsName when _name is name

    getFeatureMonitorsName: ->
        @FeatureMonitorsName = []
        for name in @MonitorsName
            if @DBusDisplay.QueryOutputFeature_sync(name) == 1
                echo "FeatureMonitorsName.push(#{name})"
                @FeatureMonitorsName.push(name)
        return @FeatureMonitorsName[0]

    getBrightness:(name)->
        @Brightness = @DBusDisplay.Brightness
        value = null
        try
            value = @Brightness[name]
        catch e
            echo "getBrightness:#{e}"
        echo "getBrightness :#{name}:#{value};"
        return value

    getFeatureBrightnessValue:->
        @getBrightness(@FeatureMonitorsName[0])

    showBrightness:->
        clearTimeout(@timepress)
        clearTimeout(timeout_osdHide)
        @timepress = setTimeout(=>

            echo "#{@id} Class  show"
            osdShow()
            @element.style.display = "block"

            value = @getFeatureBrightnessValue()
            echo "showBrightValue:#{value}"
            set_bg(@,@id,@prebgImg)
            @prebgImg = @id

            showValue(value,0,1,@,"Brightness_bar")
            timeout_osdHide = setTimeout(osdHide,TIME_HIDE)
        ,TIME_PRESS)


BrightCls = null

osd.BrightnessUp = (keydown)->
    if !keydown then return if mode is "dbus"
    BrightCls  = new Display("Brightness") if not BrightCls?
    BrightCls.id = "BrightnessUp"
    BrightCls.showBrightness()

osd.BrightnessDown = (keydown)->
    if !keydown then return if mode is "dbus"
    BrightCls  = new Display("Brightness") if not BrightCls?
    BrightCls.id = "BrightnessUp"#the backgroundImage is same ,so the @id can equal to BrightnessUp
    BrightCls.showBrightness()

