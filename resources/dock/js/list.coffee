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

class AppList extends Widget
    constructor: (@id) ->
        super
        $("#container").insertBefore(@element, $("#notifyarea"))

    append: (c) ->
        @element.appendChild(c.element)

    do_drop: (e)->
        file = e.dataTransfer.getData("text/uri-list").substring(7)
        echo "dock:#{file}"

    try_dock_app: (e) ->
        path = e.dataTransfer.getData("text/uri-list")
        t = path.substring(path.length-8, path.length)
        if t == ".desktop"
            #show_dock_indicator()
            echo "try dock:#{path}"

    do_dragover: (e) ->
        e.dataTransfer.dropEffect="link"
        @try_dock_app(e)


app_list = new AppList("app_list")

class ClientGroup extends Widget
    constructor: (@id)->
        super

        @clients = []
        app_list.append(@)

        @el_title = document.createElement("div")
        @el_title.setAttribute("class", "ClientNumber")
        @element.appendChild(@el_title)

    add_client: (c)->
        if @clients.length == 0
            @current_leader = c
            @element.appendChild(@current_leader.element)
            p = get_page_xy(@element, @element.clientWidth, 0)
            DCore.Dock.set_dock_width(p.x) #TODO: reduce the space when Destory.
            DCore.Dock.close_show_temp() #TODO: should consider the preview window

        @clients.push(c)

        @el_title.innerText = @clients.length

    remove_client: (c)->
        c1 = @clients.remove(c)

        if c1 == @current_leader
            @current_leader = @clients[0]
            if @current_leader
                @element.appendChild(@current_leader.element)
        c1?.destroy()
        
        n = @clients.length
        if n == 0
            @destroy()
        else
            @el_title.innerText = n

    do_mouseover: (e) ->
        Preview_container.show_group(@, 150)

    do_mouseout: (e) ->
        if e.relatedTarget == @element.parentNode
            Preview_container.remove_all(1000)

    active: ->
        #@element.style.background = "rgba(0, 100, 100, 1)"
    deactive: ->
        #@element.style.background = "rgba(0, 0, 0, 0)"


class Client extends Widget
    constructor: (@id, @icon, @title, @leader)->
        super

        @update_content @title, @icon
        @element.draggable=true
        @pw_id = "PW" + @id

        @leader.add_client(@)


    update_content: (title, icon) ->
        @element.innerHTML = "
        <img draggable=false src=#{icon} />
        "
    withdraw: ->
        @element.style.display = "None"
    normal: ->
        @element.style.display = "block"
    do_click: (e) ->
        DCore.Dock.set_active_window(@id)
    do_dblclick: (e) ->
        DCore.Dock.minimize_window(@id)

    do_dragstart: (e)->
        Preview_container.remove_all()
        e.dataTransfer.setData("item-id", @element.id)
        e.dataTransfer.effectAllowed = "move"
        e.stopPropagation()

    do_dragover: (e) ->
        e.preventDefault()
        sid = e.dataTransfer.getData("item-id")
        if not sid
            return
        did = @element.id
        if sid != did
            swap_element(Widget.look_up(sid).leader.element, Widget.look_up(did).leader.element)

        e.stopPropagation()

    destroy: ->
        pw = Widget.look_up(@pw_id)
        if pw?
            Preview_container.remove(pw)
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
