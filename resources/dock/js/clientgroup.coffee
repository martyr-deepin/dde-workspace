active_group = null
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

    change_size: (w) ->
        board_width = (BOARD_IMG_WIDTH / BOARD_WIDTH) * w
        board_height = board_width * (BOARD_IMG_HEIGHT / BOARD_IMG_WIDTH)

        board_margin_top = BOARD_HEIGHT - board_height - BOARD_IMG_MARGIN_BOTTOM
        @img.style.width = board_width
        @img.style.height = board_height
        @img.style.marginTop = board_margin_top

        w = BOARD_WIDTH * board_width / BOARD_IMG_WIDTH
        h = w * 60 / BOARD_WIDTH
        t = BOARD_HEIGHT - h
        #@indicate.style.width = w
        #@indicate.style.height = h
        #@indicate.style.top = t

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

