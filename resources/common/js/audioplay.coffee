#Copyright (c) 2011 ~ 2014 Deepin, Inc.
#              2011 ~ 2014 bluth
#
#Author:      bluth <yuanchenglu001@gmail.com>
#Maintainer:  bluth <yuanchenglu001@gmail.com>
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

class AudioPlay

    MPRIS_DBUS_MIN = "org.mpris.MediaPlayer2."

    DBUS =
        name:"org.freedesktop.DBus"
        path:"/"
        interface:"org.freedesktop.DBus"

    MPRIS_DBUS =
        name:"org.mpris.MediaPlayer2.dmusic"
        path:"/org/mpris/MediaPlayer2"
        interface:"org.mpris.MediaPlayer2.Player"

    constructor: ->
        @STATUS =
            off:false
            on:true
            stop:"Stopped"
            play:"Playing"
            pause:"Paused"

        @mpris_all = []
        @mpris_dbus = null
        @launched_status = @STATUS.off

        @now_mpris = @get_mpris_now()
        if @now_mpris is null
            @launched_status = @STATUS.off
            echo "there is not media player working!"
            return
        @now_mpris_dbus_name = @now_mpris?.mpris
        @now_mpris_name = @now_mpris?.name
        echo "@now_mpris:#{@now_mpris_name}:#{@now_mpris_dbus_name}"
        @get_mpris_dbus(@now_mpris_dbus_name)

    get_mpris_now:->
        #1.get all dbus_name_all and then search for MPRIS_DBUS_MIN
        freedesktop_dbus = DCore.DBus.session_object(
            DBUS.name,
            DBUS.path,
            DBUS.interface
        )
        dbus_name_all = []
        dbus_name_all = freedesktop_dbus.ListNames_sync()
        for dbus in dbus_name_all
            index = dbus.indexOf(MPRIS_DBUS_MIN)
            if index != -1
                name = dbus.substring(index + MPRIS_DBUS_MIN.length)
                mpris = {"name":name,"mpris":dbus}
                @mpris_all.push(mpris)

        #2.check which mpris is now playing
        switch(@mpris_all.length)
            when 0 then return null
            when 1 then return @mpris_all[0]
            else
                #1.if is dmusic then directly return
                for dbus in @mpris_all
                    if dbus?.name is "dmusic" then return dbus
                #2.if isnt Stopped then return
                for dbus in @mpris_all
                    mpris = dbus?.mpris
                    MPRIS_DBUS.name = mpris
                    try
                        mpris_dbus = DCore.DBus.session_object(
                            MPRIS_DBUS.name,
                            MPRIS_DBUS.path,
                            MPRIS_DBUS.interface
                        )
                        #if dbus.name is @get_default_audio_player_name return dbus
                        if mpris_dbus.PlaybackStatus isnt @STATUS.stop then return dbus
                    catch e
                        echo "get_mpris_dbus_name #{e}"
                        return null
                #3. else return null
                return null


    get_mpris_dbus:(dbus_name) ->
        try
            @mpris_dbus = null
            if not dbus_name? then return
            MPRIS_DBUS.name = dbus_name
            @mpris_dbus = DCore.DBus.session_object(
                MPRIS_DBUS.name,
                MPRIS_DBUS.path,
                MPRIS_DBUS.interface
            )
            @launched_status = @STATUS.on
        catch e
            @launched_status = @STATUS.off
            echo "#{MPRIS_DBUS.interface} connect dbus error::#{e}"

    check_launched:->
        return @launched_status

    get_default_audio_player_name:->
        DCore.DEntry.get_default_audio_player_name().toLowerCase

    get_default_audio_player_icon:->
        DCore.DEntry.get_default_audio_player_icon()

    getPlaybackStatus:->
        @mpris_dbus?.PlaybackStatus

    Next:->
        @mpris_dbus?.Next()

    Pause:->
        @mpris_dbus?.Pause()

    Play:->
        @mpris_dbus?.Play()

    PlayPause:->
        @mpris_dbus?.PlayPause()

    Previous:->
        @mpris_dbus?.Previous()

    Seek:->
        @mpris_dbus?.Seek()

    SetPosition:->
        @mpris_dbus?.SetPosition()

    getPosition:->
        @mpris_dbus?.Position

    Stop:->
        @mpris_dbus?.Stop()

    getVolume:->
        @mpris_dbus?.Volume

    setVolume:(val)->
        if val > 1 then val = 1
        else if val < 0 then val = 0
        @mpris_dbus?.Volume = val

    getMetadata:->
        @mpris_dbus?.Metadata

    getTitle:->
        @mpris_dbus?.Metadata['xesam:title']

    getUrl:->
        #www url
        @mpris_dbus?.Metadata['xesam:url']

    getalbum:->
        #zhuanji name
        @mpris_dbus?.Metadata['xesam:album']

    getArtist:->
        #artist name
        @mpris_dbus?.Metadata['xesam:artist']

    getArtUrl:->
        #artist img
        @mpris_dbus?.Metadata['mpris:artUrl']
