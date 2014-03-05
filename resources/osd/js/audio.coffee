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
        echo "New Audio :#{@id}"
        @Cards = []
        @Sinks = []
        @Sources = []
        @DBusSinks = []
        @OpenedAudiosName = []
        @getDBus()
        _b.appendChild(@element)
        
   
    hide:->
        @element.style.display = "none"
    
    set_bg:(imgName)->
        _b.style.backgroundImage = "url(img/#{imgName}.png)"
  

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
        Math.round(@DBusDefaultSink.Volume / 10)
        
    setVolume:(volume)->
        @DBusDefaultSink.setSinkVolume(volume * 10)

    getMute:->
        mute = @DBusDefaultSink.Mute
        if not mute? then mute = 0
        return mute
    
    setMute:(mute)->
        @DBusDefaultSink.setSinkMute(mute)

    changeMute:->
        muteSet = null
        if @getMute == 0 then muteSet = 1
        else muteSetf = 0
        @setMute(muteSet)

    show:(white)->
        @element.style.display = "block"
        clearTimeout(@timeout) if @timeout
        echo "show Audio Volume:#{white}."
        if white == 0 then @set_bg("Audio_Mute")
        else if white <=4 then @set_bg("Audio_2")
        else if white <=7 then @set_bg("Audio_7")
        else if white <=10 then @set_bg("Audio_10")
        for i in [0...10]
            @valueDiv = create_elment("div","valueDiv",@element) if not @valueAll?
            @valueEachDiv[i] = create_elment("div","valueEachDiv",@valueDiv) if not @valueEachDiv[i]?
            if i <= white then @valueEachDiv[i].style.backgroundImage = "../img/black.png"
            else @valueEachDiv[i].style.backgroundImage = "../img/white.png"

        @timeout = setTimeout(=>
            @hide()
        ,TIME_HIDE)



AudioUpCls = null
AudioDownCls = null
AudioMuteCls = null

AudioUp = ->
    AudioUpCls  = new Audio("AudioUp") if not AudioUpCls?
    white = AudioUpCls.getVolume()
    white++
    AudioUpCls.setVolume(white)
    AudioUpCls.show(white)

AudioDown = ->
    AudioDownCls  = new Audio("AudioDown") if not AudioDownCls?
    white = AudioDownCls.getVolume()
    white--
    AudioDownCls.setVolume(white)
    AudioDownCls.show(white)

AudioMute = ->
    AudioMuteCls  = new Audio("AudioMute") if not AudioMuteCls?
    AudioMuteCls.changeMute()
    if AudioMuteCls.getMute() then white = 0
    else white = AudioMuteCls.getVolume()
    AudioMuteCls.show(white)

DBusMediaKey.connect("AudioUp",AudioUp) if not DBusMediaKey?
DBusMediaKey.connect("AudioDown",AudioDown) if not DBusMediaKey?
DBusMediaKey.connect("AudioMute",AudioMute) if not DBusMediaKey?
