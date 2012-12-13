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

class ShowDesktop extends Widget
    constructor: (@id)->
        super
        @add_css_class("AppItem")
        @show = false
        @element.innerHTML="
        <img class=AppItemImg src=img/desktop.png draggable=false title='show/hide desktop'/>
        "

    do_click: (e)->
        @show = !@show
        DCore.Dock.show_desktop(@show)

class LauncherItem extends Widget
    constructor: (@id)->
        super
        @add_css_class("AppItem")
        @element.innerHTML="
        <img class=AppItemImg src=img/launcher.png draggable=false title='launcher'/>
        "

    do_click: (e)->
        @show = !@show
        DCore.run_command("launcher")



class AppList extends Widget
    constructor: (@id) ->
        super
        $("#container").insertBefore(@element, $("#notifyarea"))
        @show_desktop = new ShowDesktop("show_desktop")
        @show_launcher = new LauncherItem("show_launcher")
        @element.appendChild(@show_desktop.element)
        @element.appendChild(@show_launcher.element)

    append: (c) ->
        @element.appendChild(c.element)

    do_drop: (e)->
        indicator.hide()
        file = e.dataTransfer.getData("text/uri-list").substring(7)
        if file.length > 9  # strlen("x.desktop") == 9
            DCore.Dock.request_dock(file.trim())

    show_try_dock_app: (e) ->
        path = e.dataTransfer.getData("text/uri-list").trim()
        t = path.substring(path.length-8)
        if t == ".desktop"
            lcg = $(".AppItem:last-of-type", @element)
            fcg = $(".AppItem:nth-of-type(3)", @element)
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

    do_mouseover: (e)->
        if e.target == @element
            Preview_container.remove_all(1000)


app_list = new AppList("app_list")

class AppItem extends Widget
    constructor: (@id, @icon)->
        super
        @add_css_class("AppItem")
        app_list.append(@)

    do_dragstart: (e)->
        Preview_container.remove_all()
        e.dataTransfer.setData("item-id", @element.id)
        e.dataTransfer.effectAllowed = "move"
        e.stopPropagation()
        @element.style.opacity = "0.5"

    do_dragend: (e)->
        @element.style.opacity = "1"

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
    constructor: (@id, @icon, @core)->
        super
        @element.innerHTML = "
        <img class=AppItemImg src=#{@icon}>
        "
    do_click: (e)->
        DCore.Launchable.launch(@core)

    do_itemselected: (e)->
        switch e.id
            when 1 then DCore.Launchable.launch(@core)
            when 2 then DCore.Dock.request_undock(@id)
    do_buildmenu: (e)->
        [
            [1, _("Run")],
            [],
            [2, _("RemoveMe")],
        ]

class ClientGroup extends AppItem
    constructor: (@id, @app_id)->
        super
        @try_swap_launcher()

        @clients = []
        @client_infos = {}

        @count = document.createElement("div")
        @count.setAttribute("class", "ClientGroupNumber")
        #@element.appendChild(@count)

        @img = document.createElement("img")
        @img.setAttribute("class", "AppItemImg")
        @element.appendChild(@img)

        @indicate = document.createElement("img")
        @indicate.setAttribute("class", "OpenIndicate")
        @indicate.draggable = false
        @element.appendChild(@indicate)

        @leader = null

        @board_img_path = "img/1_r2_c14.png"
        @b1 = document.createElement("img")
        @b1.draggable = false
        @b1.src = @board_img_path
        @b1.setAttribute("class", "AppItemBoard")
        @b1.style.zIndex = -8

        @b2 = document.createElement("img")
        @b2.draggable = false
        @b2.src = @board_img_path
        @b2.setAttribute("class", "AppItemBoard")
        @b2.style.zIndex = -9

        @b3 = document.createElement("img")
        @b3.draggable = false
        @b2.src = @board_img_path
        @b3.src = "img/1_r2_c14.png"
        @b3.setAttribute("class", "AppItemBoard")
        @b3.style.zIndex = -10

        @element.appendChild(@b1)
        @element.appendChild(@b2)
        @element.appendChild(@b3)

        @to_normal_status()

    set_left_top: (el, left, top)->
        el.style.display = "block"
        el.style.left = left + "px"
        el.style.top = top + "px"

    handle_clients_change: ->
        switch @clients.length
            when 1
                @set_left_top(@b1, 0, 0)
                @b2.style.display = "none"
                @b3.style.display = "none"
            when 2
                @set_left_top(@b1, 0, 1)
                @set_left_top(@b2, 3, -1)
                @b3.style.display = "none"
            else
                @set_left_top(@b1, 0, 1)
                @set_left_top(@b2, 3, 0)
                @set_left_top(@b3, 6, -1)

    to_active_status : ->
        @indicate.src = "img/s_app_active.png"
    to_normal_status : ->
        @indicate.src = "img/s_app_open.png"

    try_swap_launcher: ->
        l = Widget.look_up(@app_id)
        if l?
            swap_element(@element, l.element)
            apply_rotate(@element, 0.2)
            l.destroy()

    add_client: (id, icon, title)->
        if @clients.indexOf(id) == -1
            @clients.push id
            @count.innerText = "#{@clients.length}"
            apply_rotate(@element, 1)

        @client_infos[id] =
            "id": id
            "icon": icon
            "title": title

        if @leader != id
            @set_leader(id, icon)
        @handle_clients_change()


    remove_client: (id) ->
        delete @client_infos[id]
        @clients.remove(id)
        @count.innerText = "#{@clients.length}"

        if @clients.length == 0
            @destroy()
        else if @leader == id
            le = @clients[0]
            icon = @client_infos[le].icon
            @set_leader(le, icon)

        @handle_clients_change()

    set_leader: (id, icon)->
        @leader = id
        @img.src=icon

    destroy: ->
        info = DCore.Dock.get_launcher_info(@app_id)
        if info
            l = new Launcher(info.Id, info.Icon, info.Core)
            swap_element(l.element, @element)
            apply_rotate(l.element, 0.5)
        super

    do_buildmenu: ->
        [
            [1, _("OpenNew")],
            [2, _("Close")],
            [],
            [3, _("DockMe")],
        ]

    do_itemselected: (e)=>
        Preview_container.remove_all()
        switch e.id
            when 1 then DCore.Dock.launch_by_app_id(@app_id)
            when 2
                DCore.Dock.close_window(@leader)
            when 3 then DCore.Dock.request_dock_by_client_id(@leader)

    do_click: (e)->
        DCore.Dock.set_active_window(@leader)

    do_mouseover: (e)->
        #Preview_container.show_group(@)



active_group = null
DCore.signal_connect("active_window_changed", (info)->
    if active_group?
        active_group.to_normal_status()
    active_group = Widget.look_up("le_"+info.clss)
    active_group?.to_active_status()
)

DCore.signal_connect("launcher_added", (info) ->
    c = Widget.look_up(info.Id)
    if c
        echo "have..#{info.Id}"
    else
        new Launcher(info.Id, info.Icon, info.Core)
)
DCore.signal_connect("launcher_removed", (info) ->
    Widget.look_up(info.Id)?.destroy()
)


DCore.signal_connect("task_added", (info) ->
    leader = Widget.look_up("le_" + info.clss)

    if not leader
        leader = new ClientGroup("le_"+info.clss, info.app_id)

    if info.icon == "null"
        alert("aaa")
    leader.add_client(info.id, info.icon, info.title)
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
