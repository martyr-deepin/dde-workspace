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

class Option extends Widget
    constructor:(@id)->
        super
        echo "new Option:#{@id}"
        _b.appendChild(@element)

    hide:->
        @element.style.Option = "none"
    
    show:->
        clearTimeout(@timepress)
        clearTimeout(timeout_osdHide)
        @timepress = setTimeout(=>
            echo "Option #{@id} show"
            osdShow()
            @element.style.display = "block"
            set_bg(@,@id,@preImgName)
            @preImgName = @id

            timeout_osdHide = setTimeout(osdHide,TIME_HIDE)
        ,TIME_PRESS)

isCapsLockToggle = ->
    KEYBOARD =
        name:"com.deepin.daemon.InputDevices"
        path:"/com/deepin/daemon/InputDevice/Keyboard"
        interface:"com.deepin.daemon.InputDevice.Keyboard"
    Keyboard = DCore.DBus.session_object(
        KEYBOARD.name,
        KEYBOARD.path,
        KEYBOARD.interface
    )
    if not Keyboard? then return true
    result = Keyboard?.CapsLockToggle
    if result is undefined or result is null then result = false
    return result

OptionCls = null

CapsLockOn = (keydown)->
    if !keydown then return
    if not isCapsLockToggle then return
    setFocus(false)
    echo "CapsLockOn"
    OptionCls = new Option("CapsLockOn") if not OptionCls?
    OptionCls.id = "CapsLockOn"
    OptionCls.show()

CapsLockOff = (keydown)->
    if !keydown then return
    if not isCapsLockToggle then return
    setFocus(false)
    echo "CapsLockOff"
    OptionCls = new Option("CapsLockOff") if not OptionCls?
    OptionCls.id = "CapsLockOff"
    OptionCls.show()

NumLockOn = (keydown)->
    if !keydown then return
    setFocus(false)
    echo "NumLockOn"
    OptionCls = new Option("NumLockOn") if not OptionCls?
    OptionCls.id = "NumLockOn"
    OptionCls.show()

NumLockOff = (keydown)->
    if !keydown then return
    setFocus(false)
    echo "NumLockOff"
    OptionCls = new Option("NumLockOff") if not OptionCls?
    OptionCls.id = "NumLockOff"
    OptionCls.show()

TouchPadOn = (keydown)->
    if !keydown then return
    setFocus(false)
    echo "TouchPadOn"
    OptionCls  = new Option("TouchPadOn") if not OptionCls?
    OptionCls.id = "TouchPadOn"
    OptionCls.show()

TouchPadOff = (keydown)->
    if !keydown then return
    setFocus(false)
    echo "TouchPadOff"
    OptionCls  = new Option("TouchPadOff") if not OptionCls?
    OptionCls.id = "TouchPadOff"
    OptionCls.show()


DBusMediaKey.connect("CapsLockOn",CapsLockOn) if DBusMediaKey?
DBusMediaKey.connect("CapsLockOff",CapsLockOff) if DBusMediaKey?
DBusMediaKey.connect("NumLockOn",NumLockOn) if DBusMediaKey?
DBusMediaKey.connect("NumLockOff",NumLockOff) if DBusMediaKey?
DBusMediaKey.connect("TouchPadOff",TouchPadOff) if DBusMediaKey?
DBusMediaKey.connect("TouchPadOn",TouchPadOn) if DBusMediaKey?
