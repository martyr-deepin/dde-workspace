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

VERSION = "2.0"  #Beta

PasswordMaxlength = 16 #default 16

CANVAS_WIDTH = 150
CANVAS_HEIGHT = 150
ANIMATION_TIME = 2
APP_NAME = ''
is_greeter = null
is_hide_users = null
hide_face_login = null

try
    DCore.Greeter.get_date()
    echo "check is_greeter succeed!"
    is_greeter = true
    APP_NAME = "Greeter"
catch error
    echo "check is_greeter error:#{error}"
    is_greeter = false
    APP_NAME = "Lock"

if is_greeter
    is_hide_users = DCore.Greeter.is_hide_users()
else
    is_hide_users = false
is_hide_users = false

de_menu = null


audioplay = new AudioPlay()
audio_play_status = audioplay.get_launched_status()
if audio_play_status
    if audioplay.getTitle() is undefined then audio_play_status = false
is_volume_control = false
echo "audio_play_status:#{audio_play_status}"

enable_detection = (enabled)->
    try
        DCore[APP_NAME].enable_detection(enabled)
    catch e
        echo "enable_detection #{e}"
    finally
        return null

hideFaceLogin = ->
    try
        face = DCore[APP_NAME].enable_detection()
        return face
    catch e
        echo "face_login #{e}"
        return false
    finally
        return false
hide_face_login = hideFaceLogin()

is_livecd = false
try
    LOCK = "com.deepin.dde.lock"
    dbus = DCore.DBus.sys(LOCK)
    is_livecd = dbus.IsLiveCD_sync(DCore.Lock.get_username())
catch error
    is_livecd = false
     
detect_is_from_lock = ->
    from_lock = false
    if is_greeter
        from_lock = localStorage.getItem("from_lock")
    localStorage.setItem("from_lock",false)
    return from_lock


is_support_guest = false
try
    is_support_guest = DCore.Greeter.is_support_guest() if is_greeter
catch e
    echo "#{e}"
#is_support_guest = false


PowerManager = null
ANIMATION = false
