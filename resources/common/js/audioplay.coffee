#Copyright (c) 2011 ~ 2012 Deepin, Inc.
#              2011 ~ 2012 snyh
#
#Author:      snyh <snyh@snyh.org>
#Maintainer:  snyh <snyh@snyh.org>
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
    default_audio_player = null
    Metedata = null
    mpris_dbus = null
    launched_status = false

    constructor: ->
        # default_audio_player = @get_default_audio_player_name()
        if not default_audio_player? then default_audio_player = "dmusic"
        default_audio_player = default_audio_player.toLowerCase()
        try
            mpris_dbus = DCore.DBus.session_object("org.mpris.MediaPlayer2.#{default_audio_player}", "/org/mpris/MediaPlayer2", "org.mpris.MediaPlayer2.Player")
            echo mpris_dbus
            launched_status = true
        catch error
            launched_status = false
            echo "mpris_dbus is null ,the player isnt launched!"

    get_launched_status:->
        return launched_status

    get_default_audio_player_name:->
        default_audio_player_name = DCore.DEntry.get_default_audio_player_name()

    get_default_audio_player_icon:->
        default_audio_player_icon = DCore.DEntry.get_default_audio_player_icon()

    getPlaybackStatus:->
        mpris_dbus.PlaybackStatus

    Next:->
        mpris_dbus.Next()

    Pause:->
        mpris_dbus.Pause()

    Play:->
        mpris_dbus.Play()

    PlayPause:->
        mpris_dbus.PlayPause()

    Previous:->
        mpris_dbus.Previous()

    Seek:->
        mpris_dbus.Seek()

    SetPosition:->
        mpris_dbus.SetPosition()

    getPosition:->
        mpris_dbus.Position

    Stop:->
        mpris_dbus.Stop()

    getVolume:->
        mpris_dbus.Volume

    setVolume:(val)->
        if val > 1 then val = 1
        else if val < 0 then val = 0
        mpris_dbus.Volume = val

    getMetedata:->
        Metedata = mpris_dbus.Metedata

    getTitle:->
        # mpris_dbus.Metedata.xesam:title
        echo mpris_dbus.Metedata
        return "God is a girl"

    getUrl:->
        # mpris_dbus.Metedata.xesam:url

    getArtist:->
        # mpris_dbus.Metedata.xesam:artist

    getArtUrl:->
        # mpris_dbus.Metedata.mpris:artUrl
