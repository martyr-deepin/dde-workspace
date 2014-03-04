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

class Audio extends Option
    constructor:(@id)->
        super
        echo "New Audio :#{@id}"
        @Cards = []
        @Sinks = []
        @Sources = []
        @DBusSinks = []
        @OpenedAudiosName = []
        
        try
            @DBusAudio = DCore.DBus.session(AUDIO)
            @Cards = @DBusAudio.Cards
            @Sinks = @DBusAudio.Sinks
            @Sources = @DBusAudio.Sources
            @DefaultSink = @DBusAudio.DefaultSink
            if not @DefaultSink? then @DefaultSink = 0
            @DefaultSource = @DBusAudio.DefaultSource
            if not @DefaultSource? then @DefaultSource = 0
            @getDBusSinks()
        catch e
            echo " DBusAudio :#{AUDIO} ---#{e}---"

    getDBusSinks:->
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

    getWhite:->
        white = @getVolume()
        switch @id
            when "Audio_Up" then white++
            when "Audio_Up" then white--
            when "Audio_Mute"
                white = 0
                @setMute()
        @setVolume(white)
        return white
    
    show:->
        white = @getWhite()
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

