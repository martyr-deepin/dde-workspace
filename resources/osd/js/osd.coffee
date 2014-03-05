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


class OSD extends Widget
    
    constructor:->
        super
        echo "osd"
        document.body.appendChild(@element)
        @element.style.display = "none"
        @opt = []
        @MediaKey_SignalFunc = []
        @setMediaKeyDict()
    
 
    setMediaKeyDict : ->
        @MediaKey_SignalFunc = [
            {Signal:"AudioDown",Func:@createAudioDown},
            {Signal:"AudioMute",Func:@createAudioMute},
            {Signal:"AudioUp",Func:@createAudioUp},
            {Signal:"BrightnessUp",Func:@createBrightnessUp},
            {Signal:"BrightnessDown",Func:@createBrightnessDown},
            {Signal:"CapsLockOn",Func:@createCapsLockOn},
            {Signal:"CapsLockOff",Func:@createLockOff},
            {Signal:"DisplaySwitch",Func:@createDisplaySwitch},
            {Signal:"NumLockOn",Func:@createNumLockOn},
            {Signal:"NumLockOff",Func:@createNumLockOff}
        ]
    
    createAudioDown:(type)->
        @AudioDown = new Audio("AudioDown") if not @AudioDown?
        @AudioDown.show()
    
    createAudioDown:(type)->
        @AudioMute = new Audio("AudioMute") if not @AudioMute?
        @AudioMute.show()
    
    createAudioDown:(type)->
        @AudioUp = new Audio("AudioUp") if not @AudioUp?
        @AudioUp.show()
    
    createBrightnessUp:(type)->
        @BrightnessUp = new Display("BrightnessUp") if not @BrightnessUp?
        @BrightnessUp.show()
    
    createBrightnessDown:(type)->
        @BrightnessDown = new Display("BrightnessDown") if not @BrightnessDown?
        @BrightnessDown.show()
    
    createDisplaySwitch:(type)->
        @DisplaySwitch = new Display("DisplaySwitch") if not @DisplaySwitch?
        @DisplaySwitch.show()        
    
    createBrightnessDown:(type)->
        @BrightnessDown = new Display("BrightnessDown") if not @BrightnessDown?
        @BrightnessDown.show()    
    
    createBrightnessDown:(type)->
        @BrightnessDown = new Display("BrightnessDown") if not @BrightnessDown?
        @BrightnessDown.show()    
    
    createDisplaySwitch:(type)->
        @DisplaySwitch = new Display("DisplaySwitch") if not @DisplaySwitch?
        @DisplaySwitch.show()        
    
    newClass:(id)->
        cls = null
        switch id
            when "BrightnessUp", "BrightnessDown", "DisplaySwitch"
                cls = new Display(id)
            when "AudioUp", "AudioDown", "AudioMute"
                cls = new Audio(id)
            else cls = new Option(id)
        return cls
    
    optionBuild:->
        for option,i in @MediaKey_SignalFunc
            name = option.Signal
            @opt[i] = @newClass(name)
            @opt[i].append(@element)
            @opt[i].hide()
        @element.style.display = "none"
    
    getArgv:->
        return DCore.Osd.get_argv()
    
    show:(option)->
        echo "osd show"
        @element.style.display = "-webkit-box"
        for opt in @opt
            if opt.id is option then opt.show()
            else opt.hide()
        @timeout = setTimeout(=>
            @hide()
        ,TIME_HIDE)
    
    hide:->
        @element.style.display = "none"
        for opt in @opt
            opt.hide()
    
    dbuSignalsConnect:->
        try
            DBusMediaKey = DCore.DBus.session_object(
                MEDIAKEY.obj,
                MEDIAKEY.path,
                MEDIAKEY.interface
            )
            for MediaKey in @MediaKey_SignalFunc
                DBusMediaKey.connect(MediaKey.Signal,MediaKey.Func)
        catch e
            echo "Error:-----DBusMediaKey:#{e}"
    
    keyChanged:(type)=>
        echo "KeyChanged:#{keyValue}"
        clearTimeout(@timeout) if @timeout
        @show(signal)

#osd = new OSD()
#osd.optionBuild()
#osd.dbuSignalsConnect()
