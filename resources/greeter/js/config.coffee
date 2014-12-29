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

CANVAS_WIDTH = 150
CANVAS_HEIGHT = 150
ANIMATION_TIME = 2
APP_NAME = ''


is_greeter = null
try
    DCore.Greeter.get_date()
    is_greeter = true
    APP_NAME = "Greeter"
catch error
    is_greeter = false
    APP_NAME = "Lock"

DEBUG = DCore[APP_NAME].is_debug()

enable_detection = (enabled)->
    try
        DCore[APP_NAME].enable_detection(enabled)
    catch e
        echo "enable_detection #{e}"
    finally
        return null

is_livecd = false
try
    is_livecd = DCore[APP_NAME].is_livecd()
catch
    is_livecd = false

detect_is_from_lock = ->
    from_lock = false
    if is_greeter
        from_lock = localStorage.getItem("from_lock")
        echo from_lock
    localStorage.setItem("from_lock",false)
    echo "detect_is_from_lock:#{from_lock}"
    return from_lock

is_support_guest = false
try
    is_support_guest = DCore.Greeter.is_support_guest() if is_greeter
catch e
    echo "#{e}"

PowerManager = null
ANIMATION = false

zoneDBus = null
is_guest = false

accounts = new Accounts(APP_NAME)
guest = accounts.guest

_b = document.body

inject_css(_b,"../common/css/global.css")
inject_css(_b,"../common/css/animation.css")

menuchoose = []
body_keydown_listener =(all_menu_hide_cb)->
    w_menu = []
    document.body.addEventListener("keydown",(e)->
        try
            echo "body keydown:#{e.which}"
            all_menu_hide = true
            for w in menuchoose
                if not w.is_hide() then all_menu_hide = false
            if all_menu_hide
                all_menu_hide_cb?(e)
            else
                for w in menuchoose
                    w.keydown(e)
        catch e
            echo "body keydown error:#{e}"
    )
