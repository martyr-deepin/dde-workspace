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
    result = Keyboard?.CapslockToggle
    if result isnt true then result = false
    echo "isCapsLockToggle:#{result}"
    return result

OptionCls = null

osd.CapsLockOn = (keydown)->
    if !keydown then return if mode is "dbus"
    if isCapsLockToggle() isnt true then return
    setFocus(false)
    echo "CapsLockOn"
    OptionCls = new Option("CapsLockOn") if not OptionCls?
    OptionCls.id = "CapsLockOn"
    OptionCls.show()

osd.CapsLockOff = (keydown)->
    if !keydown then return if mode is "dbus"
    if isCapsLockToggle() isnt true then return
    setFocus(false)
    echo "CapsLockOff"
    OptionCls = new Option("CapsLockOff") if not OptionCls?
    OptionCls.id = "CapsLockOff"
    OptionCls.show()

osd.NumLockOn = (keydown)->
    if !keydown then return if mode is "dbus"
    setFocus(false)
    echo "NumLockOn"
    OptionCls = new Option("NumLockOn") if not OptionCls?
    OptionCls.id = "NumLockOn"
    OptionCls.show()

osd.NumLockOff = (keydown)->
    if !keydown then return if mode is "dbus"
    setFocus(false)
    echo "NumLockOff"
    OptionCls = new Option("NumLockOff") if not OptionCls?
    OptionCls.id = "NumLockOff"
    OptionCls.show()

osd.TouchPadOn = (keydown)->
    if !keydown then return if mode is "dbus"
    setFocus(false)
    echo "TouchPadOn"
    OptionCls  = new Option("TouchPadOn") if not OptionCls?
    OptionCls.id = "TouchPadOn"
    OptionCls.show()

osd.TouchPadOff = (keydown)->
    if !keydown then return if mode is "dbus"
    setFocus(false)
    echo "TouchPadOff"
    OptionCls  = new Option("TouchPadOff") if not OptionCls?
    OptionCls.id = "TouchPadOff"
    OptionCls.show()

