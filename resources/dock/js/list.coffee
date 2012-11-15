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

container = $('#icon_list')

app_group_leader = {}

class Client extends Widget
    constructor: (@id, @icon, @title, @clss)->
        super
        @update_content @title, @icon

        app_group_leader[@clss] = @

        container.appendChild(@element)

        @pw_id = "PW" + @id

    update_content: (title, icon) ->
        @element.innerHTML = "
        <img src=#{icon} />
        "

    active: ->
        @element.style.background = "rgba(0, 100, 100, 1)"
    deactive: ->
        @element.style.background = "rgba(0, 0, 0, 0)"
    withdraw: ->
        @element.style.display = "None"
    normal: ->
        @element.style.display = "block"
    do_click: (e) ->
        DCore.Dock.set_active_window(@id)
    do_dblclick: (e) ->
        DCore.Dock.minimize_window(@id)
    do_mouseover: (e) ->
        pw = Widget.look_up(@pw_id)
        if not pw
            pw = new PreviewWindow(@pw_id, @id, @title, 300, 200)
            preview_container.active(pw, @element.offsetLeft - 150)




active_win = null
change_active_window = (c) ->
    if active_win?
        active_win.deactive()
    active_win = c
    active_win.active()


DCore.signal_connect("active_window_changed", (info)->
    client = Widget.look_up(info.id)
    change_active_window(client)
)

DCore.signal_connect("task_added", (info) ->
    w = Widget.look_up(info.id)
    if w
        w.update_content(info.title, info.icon)
    else
        new Client(info.id, info.icon, info.title, info.clss)
)

DCore.signal_connect("task_removed", (info) ->
    Widget.look_up("PW"+info.id)?.destroy()
    Widget.look_up(info.id)?.destroy()
)

DCore.signal_connect("task_withdraw", (info) ->
    Widget.look_up(info.id).withdraw()
)

DCore.signal_connect("task_normal", (info) ->
    Widget.look_up(info.id).normal()
)

DCore.Dock.emit_update_task_list()
