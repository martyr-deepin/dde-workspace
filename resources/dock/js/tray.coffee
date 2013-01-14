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

na = $("#notifyarea")
tray_icons = {}
update_icons = ->
    for k, v of tray_icons
        v.update()

class TrayIconWrap extends Widget
    constructor: (@id, @clss, @name) ->
        super
        na.appendChild(@element)

    update: ->
        p = get_page_xy(@element)
        DCore.Dock.set_tray_icon_position(@id, p.x, p.y)


for info in DCore.Dock.get_tray_icon_list()
    icon = new TrayIconWrap(info.id, info.clss, info.name)
    tray_icons[info.id] = icon
    #We can't update icon position at this momenet because the div element's layout hasn't done.

setTimeout(update_icons, 500)
    
do_tray_icon_added = (info) ->
    icon = new TrayIconWrap(info.id, info.clss, info.name)
    tray_icons[info.id] = icon
    setTimeout(update_icons, 30)

do_tray_icon_removed = (info) ->
    icon = Widget.look_up(info.id)
    icon.destroy()
    delete tray_icons[info.id]
    setTimeout(update_icons, 30)

DCore.signal_connect('tray_icon_added', do_tray_icon_added)
DCore.signal_connect('tray_icon_removed', do_tray_icon_removed)


try
    s_manager = DCore.DBus.session("org.gnome.SessionManager")

class CustomTrayIcon extends Widget
    constructor: (@id, @title, @icon, @cb) ->
        super
        @element.innerHTML = "
            <img src=#{@icon} width=24px height=24px />
        "
        na.appendChild(@element)

    do_click: (e)->
        @cb()

shutdown_icon = new CustomTrayIcon("shutdown", "ShutDown",
    "file:///usr/share/icons//Faenza-Darker/actions/48/gnome-logout.png", -> s_manager?.Shutdown_sync())
logout_icon = new CustomTrayIcon("logout", "Logout",
    "img/log_out_48.png", -> s_manager?.Logout_sync(1))
