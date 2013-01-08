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

calc_app_item_size = ->
    apps = $s(".AppItem")
    if apps.length == 0
        return

    w = apps[0].offsetWidth
    last = apps[apps.length-1]
    if last and last.clientWidth != 0
        #TODO: the logic is mess.
        # when the last apps is in withdraw status, the clientWidth will be zero!
        #while last.clientWidth == 0
            #last = last.previousElementSibling
        DCore.Dock.require_region(0, 0, screen.width, DOCK_HEIGHT)
        p = get_page_xy(last, 0, 0)
        offset = p.x + last.clientWidth
        DCore.Dock.release_region(offset + BOARD_WIDTH, 0, screen.width - offset, 30)

        h = w * (BOARD_HEIGHT / BOARD_WIDTH)
        height = h * (BOARD_HEIGHT - BOARD_MARGIN_BOTTOM) / BOARD_HEIGHT + BOARD_MARGIN_BOTTOM
        DCore.Dock.change_workarea_height(height)
    else
        echo "can't find last app #{apps.length}"

    for i in apps
        Widget.look_up(i.id).change_size(w)

active_group = null

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
        setTimeout(c, 200)

    append: (c) ->
        @element.appendChild(c.element)
        run_post(calc_app_item_size)

    do_drop: (e)->
        indicator.hide()
        file = e.dataTransfer.getData("text/uri-list").substring(7)
        if file.length > 9  # strlen("x.desktop") == 9
            DCore.Dock.request_dock(decodeURI(file.trim()))

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


_is_normal_mode = 1
get_mode_size = ->
    if _is_normal_mode
        return 0
    else
        return 26
get_mode_board_size = ->
    if _is_normal_mode
        return 0
    else
        return 26


class AppItem extends Widget
    constructor: (@id, @icon)->
        super
        @add_css_class("AppItem")

        @board = create_img("AppItemBoard", BOARD_IMG_PATH, @element)
        @board.style.left = BOARD_IMG1_LEFT
        @board.style.zIndex = -8

        @img = create_element('img', "AppItemImg", @element)
        @img.src = @icon
        @img.style.left = APP_IMG_LEFT
        app_list.append(@)

        @img.onload = =>
            @update_board_color()

    update_board_color: ->
        color = DCore.Dock.calc_dominant_color_by_path(@img.src.substring(7))
        @board_rgb = "rgb(#{color.r}, #{color.g}, #{color.b})"
        @board.style.backgroundColor = @board_rgb

    is_fixed_pos: false
        
    destroy: ->
        super
        run_post(calc_app_item_size)

    change_size: (w) ->
        board_width = (BOARD_IMG_WIDTH / BOARD_WIDTH) * w
        board_height = board_width * (BOARD_IMG_HEIGHT / BOARD_IMG_WIDTH)

        board_margin_top = BOARD_HEIGHT - board_height - BOARD_MARGIN_BOTTOM
        @set_board_size(board_width, board_height, board_margin_top)

        @img.style.height = board_height * (APP_IMG_HEIGHT / BOARD_IMG_HEIGHT)
        @img.style.width = board_width * (APP_IMG_WIDTH / BOARD_IMG_WIDTH)
        img_margin = board_height * (BOARD_IMG_HEIGHT - APP_IMG_HEIGHT) * 0.5 / BOARD_IMG_HEIGHT

        @img.style.top = img_margin + board_margin_top + get_mode_size()

    set_board_size: (width, height, top)->
        @board.style.top = top + get_mode_board_size()
        @board.style.width = width
        @board.style.height = height

    do_dragstart: (e)->
        Preview_container.remove_all()
        return if @is_fixed_pos
        e.dataTransfer.setData("item-id", @element.id)
        e.dataTransfer.effectAllowed = "move"
        e.stopPropagation()
        @element.style.opacity = "0.5"

    do_dragend: (e)->
        @element.style.opacity = "1"

    do_dragover: (e) ->
        e.preventDefault()
        return if @is_fixed_pos
        sid = e.dataTransfer.getData("item-id")
        if not sid
            return
        did = @element.id
        if sid != did
            swap_element(Widget.look_up(sid).element, Widget.look_up(did).element)

        e.stopPropagation()

    do_drop: (e) ->
        e.preventDefault()
        e.stopPropagation()
        if e.dataTransfer.getData("item-id")
            return
        tmp_list = []
        for file in e.dataTransfer.files
            path = decodeURI(file.path)
            entry = DCore.DEntry.create_by_path(path)
            tmp_list.push(entry)
        switch this.constructor.name
            when "Launcher" then DCore.DEntry.launch(@core, tmp_list)
            when "ClientGroup" then DCore.Dock.launch_by_app_id(@app_id, tmp_list)


class Launcher extends AppItem
    constructor: (@id, @icon, @core)->
        super

    do_click: (e)->
        DCore.DEntry.launch(@core, [])

    do_itemselected: (e)->
        switch e.id
            when 1 then DCore.DEntry.launch(@core, [])
            when 2 then DCore.Dock.request_undock(@id)
    do_buildmenu: (e)->
        [
            [1, _("Run")],
            [],
            [2, _("UnDock")],
        ]
class ClientGroup extends AppItem
    constructor: (@id, @icon, @app_id)->
        super
        @try_swap_launcher()

        @n_clients = []
        @w_clients = []
        @client_infos = {}

        @indicate = create_img("OpenIndicate", "", @element)

        @in_iconfiy = false
        @leader = null

        @board2 = create_img("AppItemBoard", BOARD_IMG_PATH, @element)
        @board2.style.zIndex = -9

        @board3 = create_img("AppItemBoard", BOARD_IMG_PATH, @element)
        @board3.style.zIndex = -10

        @to_normal_status()

    update_board_color: ->
        @board.style.backgroundColor = @board_rgb
        @board2.style.backgroundColor = @board_rgb
        @board3.style.backgroundColor = @board_rgb

    set_board_size: (width, height, marginTop)->
        super

        @_board_margin_top = marginTop + get_mode_board_size()

        @handle_clients_change()

        @board2.style.width = width
        @board2.style.height = height
        @board2.style.left = BOARD_IMG2_LEFT

        @board3.style.width = width
        @board3.style.height = height
        @board3.style.left = BOARD_IMG3_LEFT

        w = BOARD_WIDTH * width / BOARD_IMG_WIDTH
        h = w * 52 / BOARD_WIDTH
        t = BOARD_HEIGHT - h
        @indicate.style.width = w
        @indicate.style.height = h
        @indicate.style.top = t


    handle_clients_change: ->
        switch @n_clients.length
            when 1
                @board.style.display = "block"
                @board2.style.display = "none"
                @board3.style.display = "none"
                @board.style.top = @_board_margin_top
            when 2
                @board.style.display = "block"
                @board2.style.display = "block"
                @board3.style.display = "none"

                @board.style.top = @_board_margin_top + 1
                @board2.style.top = @_board_margin_top - 1
            else
                @board.style.display = "block"
                @board2.style.display = "block"
                @board3.style.display = "block"

                @board.style.top = @_board_margin_top + 2
                @board2.style.top = @_board_margin_top
                @board3.style.top = @_board_margin_top - 2

    to_active_status : (id)->
        @in_iconfiy = false
        active_group?.to_normal_status()
        @indicate.src = "img/s_app_active.png"
        @leader = id
        DCore.Dock.active_window(@leader)
        active_group = @

    to_normal_status : ->
        @indicate.src = "img/s_app_open.png"

    try_swap_launcher: ->
        l = Widget.look_up(@app_id)
        if l?
            swap_element(@element, l.element)
            apply_rotate(@element, 0.2)
            l.destroy()

    withdraw_child: (id)->
        @w_clients.push(id)
        @remove_client(id, true)

    normal_child: (id)->
        info = @client_infos[id]
        @w_clients.remove(id)
        @add_client(info.id)

    update_client: (id, icon, rgb, title)->
        @board_rgb = rgb
        @img.src = icon if id == @leader
        in_withdraw = id in @w_clients
        @client_infos[id] =
            "id": id
            "icon": icon
            "title": title
        if not in_withdraw
            @add_client(id)

    add_client: (id)->
        if @n_clients.indexOf(id) == -1
            #TODO: new leader should insert at index 1
            @n_clients.remove(id)
            @n_clients.push id
            apply_rotate(@element, 1)

            if @leader != id
                @leader = id
                @update_leader()

            @handle_clients_change()
        @element.style.display = "block"


    remove_client: (id, save_info=false) ->
        if not save_info
            delete @client_infos[id]

        @n_clients.remove(id)

        if @n_clients.length == 0
            if @w_clients.length == 0
                @destroy()
            else
                @element.style.display = "none"
        else if @leader == id
            @next_leader()

        @handle_clients_change()

    next_leader: ->
        @n_clients.push(@n_clients.shift())
        @leader = @n_clients[0]
        @update_leader()
        
    update_leader: ->
        @img.src = @client_infos[@leader].icon

    destroy: ->
        @element.style.display = "block"
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
            [4, _("PreView(Not yet)")]
        ]

    do_itemselected: (e)=>
        Preview_container.remove_all()
        switch e.id
            when 1 then DCore.Dock.launch_by_app_id(@app_id, [])
            when 2 then DCore.Dock.close_window(@leader)
            when 3 then DCore.Dock.request_dock_by_client_id(@leader)
            #when 4 then Preview_container.show_group(@)

    do_click: (e)->
        if @n_clients.length == 1 and active_group == @
            if @in_iconfiy
                @to_active_status(@leader)
            else
                @in_iconfiy = true
                DCore.Dock.iconify_window(@leader)
                @to_normal_status()
        else if @n_clients.length > 1 and active_group == @
            @next_leader()
            @to_active_status(@leader)
        else
            @to_active_status(@leader)

    do_mouseover: (e)->
        #Preview_container.show_group(@)


class ShowDesktop extends Launcher
    constructor: (@id)->
        super
        @add_css_class("AppItem")
        @show = false
        @img.src = "img/desktop.png"
        @img.setAttribute("draggable", "false")

    do_click: (e)->
        @show = !@show
        DCore.Dock.show_desktop(@show)
    do_buildmenu: ->
        []
    is_fixed_pos: true

class LauncherItem extends Launcher
    constructor: (@id)->
        super
        @add_css_class("AppItem")
        @img.src = "img/launcher.png"
        @img.setAttribute("draggable", "false")

    do_click: (e)->
        @show = !@show
        DCore.run_command("launcher")
    do_buildmenu: ->
        []
    is_fixed_pos: true


show_desktop = new ShowDesktop("show_desktop")
show_launcher = new LauncherItem("show_launcher")
app_list.element.appendChild(show_desktop.element)
app_list.element.appendChild(show_launcher.element)


DCore.signal_connect("active_window_changed", (info)->
    active_group?.to_normal_status()
    active_group = Widget.look_up("le_"+info.clss)
    active_group?.to_active_status(info.id)
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

DCore.signal_connect("task_updated", (info) ->
    leader = Widget.look_up("le_" + info.clss)

    if not leader
        leader = new ClientGroup("le_"+info.clss, info.icon, info.app_id)

    rgb = "rgb(#{info.r}, #{info.g}, #{info.b})"
    leader.update_client(info.id, info.icon, rgb, info.title)
)

DCore.signal_connect("task_removed", (info) ->
    Widget.look_up("le_"+info.clss)?.remove_client(info.id)
)

DCore.signal_connect("task_withdraw", (info) ->
    Widget.look_up("le_" + info.clss).withdraw_child(info.id)
)

DCore.signal_connect("task_normal", (info) ->
    Widget.look_up("le_" + info.clss).normal_child(info.id)
)

DCore.signal_connect("in_mini_mode", ->
    _is_normal_mode = 0
    run_post(calc_app_item_size())
)

DCore.signal_connect("in_normal_mode", ->
    _is_normal_mode = 1
    run_post(calc_app_item_size())
)

DCore.Dock.emit_webview_ok()

init_app_item_size = ->
    apps = $s(".AppItem")
    w = apps[0].offsetWidth
    for i in apps
        Widget.look_up(i.id).change_size(w)
setTimeout(calc_app_item_size, 100)
setTimeout(calc_app_item_size, 1000)
setTimeout(calc_app_item_size, 1800)
setTimeout(calc_app_item_size, 2800)
setTimeout(calc_app_item_size, 4000)
