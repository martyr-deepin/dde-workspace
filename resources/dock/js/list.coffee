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

class ClientGroup extends Widget
    constructor: (@id)->
        super

        @clients = []
        container.appendChild(@element)

        @el_title = document.createElement("div")
        @el_title.setAttribute("class", "ClientNumber")
        @element.appendChild(@el_title)

    add_client: (c)->
        if @clients.length == 0
            @current_leader = c
            @element.appendChild(@current_leader.element)

        @clients.push(c)

        @el_title.innerText = @clients.length

    remove_client: (c)->
        c1 = @clients.remove(c)
        if c1 == @current_leader
            @current_leader= @clients[0]
            if @current_leader_
                @element.appendChild(@current_leader.element)
        c1?.destroy()
        
        n = @clients.length
        if n == 0
            @destroy()
        else
            @el_title.innerText = n

    do_mouseover: (e) ->
        preview_container.show_group(@, 150)

    do_mouseout: (e) ->
        if e.relatedTarget == @element.parentNode
            preview_container.close_all()
            echo "OK>..."
        else
            "ignore mouse out"

    active: ->
        @element.style.background = "rgba(0, 100, 100, 1)"
    deactive: ->
        @element.style.background = "rgba(0, 0, 0, 0)"



class Client extends Widget
    constructor: (@id, @icon, @title, @leader)->
        super

        @update_content @title, @icon
        @pw_id = "PW" + @id

        @leader.add_client(@)

    update_content: (title, icon) ->
        @element.innerHTML = "
        <img src=#{icon} />
        "
    withdraw: ->
        @element.style.display = "None"
    normal: ->
        @element.style.display = "block"
    do_click: (e) ->
        DCore.Dock.set_active_window(@id)
    do_dblclick: (e) ->
        DCore.Dock.minimize_window(@id)
    destroy: ->
        Widget.look_up(@pw_id)?.destroy()
        super




active_group = null
DCore.signal_connect("active_window_changed", (info)->
    client = Widget.look_up(info.id)
    if active_group?
        active_group.deactive()
    active_group = client.leader
    active_group.active()
)

DCore.signal_connect("task_added", (info) ->
    c = Widget.look_up(info.id)

    if c
        c.update_content(info.title, info.icon)
    else
        leader = Widget.look_up("le_"+info.clss)
        if not leader
            leader = new ClientGroup("le_"+info.clss)
        new Client(info.id, info.icon, info.title, leader)
)

DCore.signal_connect("task_removed", (info) ->
    Widget.look_up("le_"+info.clss)?.remove_client(Widget.look_up(info.id))
)

DCore.signal_connect("task_withdraw", (info) ->
    Widget.look_up(info.id).withdraw()
)

DCore.signal_connect("task_normal", (info) ->
    Widget.look_up(info.id).normal()
)

DCore.Dock.emit_update_task_list()
