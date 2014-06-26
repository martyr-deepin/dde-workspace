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

 #-------------------------------------------
is_greeter = null
try
    DCore.Greeter.get_date()
    echo "check is_greeter succeed!"
    is_greeter = true
    APP_NAME = "Greeter"
catch error
    echo "check is_greeter false"
    is_greeter = false
    APP_NAME = "Lock"

#is_hide_users = null
#if is_greeter
#    is_hide_users = DCore.Greeter.is_hide_users()
#else
#    is_hide_users = false
#is_hide_users = false

 #-------------------------------------------

enable_detection = (enabled)->
    try
        DCore[APP_NAME].enable_detection(enabled)
    catch e
        echo "enable_detection #{e}"
    finally
        return null

hideFaceLogin = ->
    return false
    try
        face = DCore[APP_NAME].enable_detection()
        return face
    catch e
        echo "face_login #{e}"
        return false
    finally
        return false
hide_face_login = hideFaceLogin()
 #-------------------------------------------

is_livecd = false
try
    is_livecd = DCore[APP_NAME].is_livecd()
catch
    is_livecd = false
 #-------------------------------------------

detect_is_from_lock = ->
    from_lock = false
    if is_greeter
        from_lock = localStorage.getItem("from_lock")
        echo from_lock
    localStorage.setItem("from_lock",false)
    echo "detect_is_from_lock:#{from_lock}"
    return from_lock

 #-------------------------------------------

is_support_guest = false
try
    is_support_guest = DCore.Greeter.is_support_guest() if is_greeter
catch e
    echo "#{e}"
#is_support_guest = false

 #-------------------------------------------

PowerManager = null
ANIMATION = false

 #-------------------------------------------

zoneDBus = null
enableZoneDetect = (enable) ->
    echo "enableZoneDetect :#{enable}"
    ZONE = "com.deepin.daemon.Zone"
    try
        zoneDBus = DCore.DBus.session(ZONE) if not zoneDBus?
        zoneDBus?.EnableZoneDetected_sync(enable)
    catch e
        echo "zoneDBus #{ZONE} error : #{e}"
 #-------------------------------------------

is_guest = false

accounts = new Accounts(APP_NAME)
_b = document.body

inject_css(_b,"../common/css/global.css")
inject_css(_b,"../common/css/animation.css")
