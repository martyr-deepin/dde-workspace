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

_b = document.body

#MediaKey DBus
MEDIAKEY =
    obj: "com.deepin.daemon.KeyBinding"
    path: "/com/deepin/daemon/MediaKey"
    interface: "com.deepin.daemon.MediaKey"
TIME_HIDE = 4000
TIME_PRESS = 10
DBusMediaKey = null
try
    DBusMediaKey = DCore.DBus.session_object(
        MEDIAKEY.obj,
        MEDIAKEY.path,
        MEDIAKEY.interface
    )
catch e
    echo "Error:-----DBusMediaKey:#{e}"
echo DBusMediaKey

#dconf-tools  
#org/gonome/settings-daemon/plugins/media-keys/active false
#com/deepin/dde/key-binding/mediakey
#dbus-monitor "sender='com.deepin.daemon.MediaKey', type='signal'"   
allElsHide=->
    els = _b.children
    for el in els
        if el.tagName = "DIV" then el.style.display = "none"

osdHide=->
    echo "osdHide"
    allElsHide()
    DCore.Osd.hide()

osdShow=->
    echo "osdShow"
    allElsHide()
    DCore.Osd.show()

osdHide()

click_time = 0
_b.addEventListener("click",(e)=>
    e.stopPropagation()
    click_time++
    DCore.Osd.quit() if click_time % 3 == 0
)


