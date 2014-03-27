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
    AUDIO_SINKS =
        obj: AUDIO
        path: "/com/deepin/daemon/Audio/Sink0"
        interface: "com.deepin.daemon.Audio.Sink"
    DEFAULT_SINK = 0

    constructor:(@id)->
        super
        @Cards = []
        @Sinks = []
        @Sources = []
        @DBusSinks = []
        @OpenedAudiosName = []
        @valueEach = []
        _b.appendChild(@element)
        @getDBus()
        
   
    hide:->
        @element.style.display = "none"
    
    getDBus:->
        try
            @DBusAudio = DCore.DBus.session(AUDIO)
            @Cards = @DBusAudio.Cards
            @Sinks = @DBusAudio.Sinks
            @Sources = @DBusAudio.Sources
            @DefaultSink = @DBusAudio.DefaultSink
            if not @DefaultSink? then @DefaultSink = 0
            @DefaultSource = @DBusAudio.DefaultSource
            if not @DefaultSource? then @DefaultSource = 0
        catch e
            echo " DBusAudio :#{AUDIO} ---#{e}---"
        
        try
            for path in @Sinks
                AUDIO_SINKS.path = path
                DBusSink = DCore.DBus.session_object(
                    AUDIO_SINKS.obj,
                    AUDIO_SINKS.path,
                    AUDIO_SINKS.interface
                )
                @DBusSinks.push(DBusSink)
                @DBusDefaultSink = @DBusSinks[@DefaultSink]
        catch e
            echo "getDBusSinks ERROR: ---#{e}---"
   
    getVolume:->
        volume = @DBusDefaultSink.Volume
        if volume > 150 then volume = 150
        else if volume < 0 then volume = 0
        else if volume is null then volume = 0
        return volume / 15
        
    setVolume:(volume)->
        if volume > 15 then volume = 15
        else if volume < 0 then volume = 0
        @DBusDefaultSink.SetSinkVolume_sync(volume * 15)

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

    getBgName:(white)->
        bg = "Audio_2"
        if white <= 0 then bg = "Audio_0"
        else if white <= 4 then bg = "Audio_1"
        else if white <= 7 then bg = "Audio_2"
        else bg = "Audio_3"
        return bg
    
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

    show:(white)->
        clearTimeout(@timepress) if @timepress
        @timepress = setTimeout(=>
            clearTimeout(timeout_osdHide) if timeout_osdHide
            
            osdShow()
            @element.style.display = "block"
            imgName = @getBgName(white)
            echo "show #{@id} Volume:#{white} BgName:#{imgName}.png"
            set_bg(@element,imgName,@preImgName)
            @preImgName = imgName
            @showValue(white)

            timeout_osdHide = setTimeout(=>
                osdHide()
            ,TIME_HIDE)
        ,TIME_PRESS)



AudioCls = null

AudioUp = (keydown) ->
    if keydown then return
    setFocus(false)
    echo "AudioUp"
    AudioCls = new Audio("Audio") if not AudioCls?
    AudioCls.id = "AudioUp"
    white = AudioCls.getVolume()
    AudioCls.show(white)

AudioDown = (keydown) ->
    if keydown then return
    setFocus(false)
    echo "AudioDown"
    AudioCls = new Audio("Audio") if not AudioCls?
    AudioCls.id = "AudioDown"
    white = AudioCls.getVolume()
    AudioCls.show(white)

AudioMute = (keydown) ->
    if keydown then return
    setFocus(false)
    echo "AudioMute"
    AudioCls = new Audio("Audio") if not AudioCls?
    AudioCls.id = "AudioMute"
    white = AudioCls.getVolume()
    if AudioCls.getMute() then white = 0
    AudioCls.show(white)

DBusMediaKey.connect("AudioUp",AudioUp) if DBusMediaKey?
DBusMediaKey.connect("AudioDown",AudioDown) if DBusMediaKey?
DBusMediaKey.connect("AudioMute",AudioMute) if DBusMediaKey?
