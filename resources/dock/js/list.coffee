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

class Indicator extends Widget
    constructor: (@id)->
        super
        document.body.appendChild(@element)
        @element.style.top = "840px"
        @hide()
    show: (x)->
        @last_x = x
        @element.style.display = "block"
        @element.style.left = "#{x}px"

    hide: ->
        @element.style.display = "none"

indicator = new Indicator("indicator")

class AppList extends Widget
    constructor: (@id) ->
        super
        $("#container").insertBefore(@element, $("#notifyarea"))

    append: (c) ->
        @element.appendChild(c.element)

    do_drop: (e)->
        indicator.hide()
        file = e.dataTransfer.getData("text/uri-list").substring(7)
        if file.length > 9  # strlen("x.desktop") == 9
            DCore.Dock.request_dock(file.trim())

    show_try_dock_app: (e) ->
        path = e.dataTransfer.getData("text/uri-list")
        t = path.substring(path.length-8, path.length)
        if t == ".desktop"
            lcg = $(".ClientGroup:last-of-type")
            fcg = $(".ClientGroup:first-of-type")
            lp = get_page_xy(lcg, lcg.clientWidth, 0)
            fp = get_page_xy(fcg, 0, 0)
            if e.pageX > lp.x
                x = lp.x
            else if e.pageX < fp.x
                x = fp.x
            else
                x = e.pageX
            indicator.show(x)

    do_dragover: (e) ->
        e.dataTransfer.dropEffect="link"
        @show_try_dock_app(e)

    do_dragleave: (e)->
        if e.target == @element
            indicator.hide()


app_list = new AppList("app_list")

class AppItem extends Widget
    constructor: (@id, @icon)->
        super
        @element.draggable=true
        app_list.append(@)

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
            swap_element(Widget.look_up(sid).element, Widget.look_up(did).element)

        e.stopPropagation()





class Launcher extends AppItem
    constructor: (@id, @icon, @exec, @app_id)->
        super
        @element.innerHTML = "
        <img src=#{@icon}>
        "
    do_click: (e)->
        DCore.run_command(@exec)
        @destroy()

    do_itemselected: (e)->
        alert e.title
    do_contextmenu: (e)->
        [
            [1, _("Run")],
            [2, _("RemoveMe")],
        ]

class ClientGroup extends AppItem
    constructor: (@id, @app_id)->
        super
        @clients = []

        @remove_launcher()

        @client_infos = {}
        @leader = null
        @count = document.createElement("div")
        @count.setAttribute("class", "ClientGroupNumber")

    remove_launcher: ->
        Widget.look_up(@app_id)?.destroy()

    add_client: (id, icon, title)->
        if @clients.indexOf(id) == -1
            @clients.push id
            @count.innerText = "#{@clients.length}"

        @client_infos[id] =
            "id": id
            "icon": icon
            "title": title

        if @leader != id
            @set_leader(id, icon)


    remove_client: (id) ->
        delete @client_infos[id]
        @clients.remove(id)
        @count.innerText = "#{@clients.length}"

        if @clients.length == 0
            @destroy()
        else if @leader == id
            le = @clients[0]
            set_leader(le, @client_infos[le].icon)

    set_leader: (id, icon)->
        @leader = id
        @element.innerHTML = "
        <img draggable=false src=#{icon} />
        "
        @element.appendChild(@count)

    destroy: ->
        DCore.Dock.try_post_launcher_info(@app_id)
        super

    do_contextmenu: (e)->
        [
            [1, _("OpenNew")],
            [2, _("DockMe")],
        ]
    do_itemselected: (e)->
        alert(@app_id)



active_group = null
DCore.signal_connect("active_window_changed", (info)->
    client = Widget.look_up(info.id)
    if active_group?
        active_group.deactive()
    active_group = client.leader
    active_group.active()
)

DCore.signal_connect("launcher_added", (info) ->
    c = Widget.look_up(info.Id)
    if c
        echo "have.."
    else
        new Launcher(info.Id, info.Icon, info.Exec)
)


DCore.signal_connect("task_added", (info) ->
    leader = Widget.look_up("le_" + info.clss)

    if not leader
        leader = new ClientGroup("le_"+info.clss, info.app_id)

    if info.icon == "null"
        alert("aaa")
    leader.add_client(info.id, info.icon, info.title)

    #if c
        #c.update_content(info.title, info.icon)
    #else
        #leader = Widget.look_up("le_"+info.clss)
        #if not leader
            #leader = new ClientGroup("le_"+info.clss)
        #new Client(info.id, info.icon, info.title, info.app_id, leader)
)

DCore.signal_connect("task_removed", (info) ->
    Widget.look_up("le_"+info.clss)?.remove_client(info.id)
)

DCore.signal_connect("task_withdraw", (info) ->
    Widget.look_up(info.id).withdraw()
)

DCore.signal_connect("task_normal", (info) ->
    Widget.look_up(info.id).normal()
)

DCore.Dock.emit_webview_ok()
