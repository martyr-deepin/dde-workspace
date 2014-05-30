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

class Audio extends Widget
    #Audio DBus
    AUDIO = "com.deepin.daemon.Audio"
    DEFAULT_SINK = "/com/deepin/daemon/Audio/Sink0"
    AUDIO_SINKS =
        name: AUDIO
        path: DEFAULT_SINK
        interface: "com.deepin.daemon.Audio.Sink"

    constructor:(@id)->
        super
        @valueEach = []
        _b.appendChild(@element)
        @getDBusAudio()
        @getDBusDefaultSink(@DefaultSink)


    hide:->
        @element.style.display = "none"

    getDBusAudio:->
        try
            @DBusAudio = DCore.DBus.session(AUDIO)
            @DefaultSink = @DBusAudio.GetDefaultSink_sync()
            if not @DefaultSink? then @DefaultSink = DEFAULT_SINK
        catch e
            echo " DBusAudio :#{AUDIO} ---#{e}---"

    getDBusDefaultSink:(DefaultSink)->
        echo "GetDefaultSink:#{DefaultSink}"
        try
            AUDIO_SINKS.path = DefaultSink
            @DBusDefaultSink = DCore.DBus.session_object(
                AUDIO_SINKS.name,
                AUDIO_SINKS.path,
                AUDIO_SINKS.interface
            )
        catch e
            echo "getDBusSinks ERROR: ---#{e}---"

    updateDBusDefaultSink:->
        DefaultSink = @DBusAudio.GetDefaultSink_sync()
        if @DefaultSink is DefaultSink then return
        echo "DefaultSink Changed!!!From #{@DefaultSink} to #{DefaultSink}"
        @DefaultSink = DefaultSink
        @getDBusDefaultSink(@DefaultSink)

    getVolume:->
        volume = @DBusDefaultSink.Volume * 100

    setVolume:(volume)->
        @DBusDefaultSink.SetSinkVolume_sync(volume)

    getMute:->
        @DBusDefaultSink.Mute

    setMute:(mute)->
        @DBusDefaultSink.SetSinkMute_sync(mute)

    changeMute:->
        muteset = 0
        if @getMute() then muteset = 0
        else muteset = 1
        echo "changeMute to muteset : #{muteset}"
        @setMute(muteset)

    getBgName:(volume)->
        bg = "Audio_2"
        if volume <= 0 then bg = "Audio_0"
        else if volume <= 40 then bg = "Audio_1"
        else if volume <= 70 then bg = "Audio_2"
        else bg = "Audio_3"
        return bg

    show:(value)->
        clearTimeout(@timepress)
        clearTimeout(timeout_osdHide)
        @timepress = setTimeout(=>
            osdShow()
            @element.style.display = "block"
            bgImg = @getBgName(value)
            echo "show #{@id} Volume:#{value} BgName:#{bgImg}.png"
            set_bg(@,bgImg,@prebgImg)
            @prebgImg = bgImg
            showValue(value,0,100,@,"Audio_bar")

            timeout_osdHide = setTimeout(osdHide,TIME_HIDE)
        ,TIME_PRESS)



AudioCls = null

osd.AudioUp = (keydown) ->
    if keydown then return if mode is "dbus"
    setFocus(false)
    AudioCls = new Audio("Audio") if not AudioCls?
    AudioCls.id = "AudioUp"
    AudioCls.updateDBusDefaultSink()
    volume = AudioCls.getVolume()
    AudioCls.show(volume)

osd.AudioDown = (keydown) ->
    if keydown then return if mode is "dbus"
    setFocus(false)
    AudioCls = new Audio("Audio") if not AudioCls?
    AudioCls.id = "AudioDown"
    AudioCls.updateDBusDefaultSink()
    volume = AudioCls.getVolume()
    AudioCls.show(volume)

osd.AudioMute = (keydown) ->
    if keydown then return if mode is "dbus"
    setFocus(false)
    AudioCls = new Audio("Audio") if not AudioCls?
    AudioCls.id = "AudioMute"
    AudioCls.updateDBusDefaultSink()
    volume = AudioCls.getVolume()
    if AudioCls.getMute() then volume = 0
    AudioCls.show(volume)

