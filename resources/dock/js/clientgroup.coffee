active_group = null
class ClientGroup extends AppItem
    constructor: (@id, @icon, @app_id)->
        super
        @try_swap_launcher()
        #@element.setAttribute("title", "ID:#{@id} APPID:#{@app_id}")

        @n_clients = []
        @w_clients = []
        @client_infos = {}

        @indicate = create_img("OpenIndicate", "", @element)
        @indicate.style.left = INDICATER_IMG_MARGIN_LEFT

        @in_iconfiy = false
        @leader = null

        @img2 = create_img("AppItemImg", "", @element)
        @img3 = create_img("AppItemImg", "", @element)

        @to_normal_status()

    change_size: ->
        super
        #TODO: why @n_clients maybe invalid !!!!!!!!!!!!
        if @n_clients
            @handle_clients_change()

    handle_clients_change: ->
        if not @_img_margin_top
            @_img_margin_top = 6
        #echo "#{@n_clients.length} Img_Margin_top #{Number(@_img_margin_top)}"
        switch @n_clients.length
            when 1
                @img.style.display = "block"
                @img2.style.display = "none"
                @img3.style.display = "none"
                @img.style.marginTop = @_img_margin_top

                @img.style.marginLeft = BOARD_IMG_MARGIN_LEFT
            when 2
                @img.style.display = "block"
                @img2.style.display = "block"
                @img3.style.display = "none"

                @img.style.marginTop = Number(@_img_margin_top) - 1
                @img2.style.marginTop = Number(@_img_margin_top) + 1

                @img.style.marginLeft = BOARD_IMG_MARGIN_LEFT_TWO_RIGHT
                @img2.style.marginLeft = BOARD_IMG_MARGIN_LEFT_TWO_LEFT
            else
                @img.style.display = "block"
                @img2.style.display = "block"
                @img3.style.display = "block"

                @img.style.marginTop = Number(@_img_margin_top) - 2
                @img2.style.marginTop = @_img_margin_top
                @img3.style.marginTop = Number(@_img_margin_top) + 2

                @img.style.marginLeft = BOARD_IMG_MARGIN_LEFT_THREE_RIGHT
                @img2.style.marginLeft = BOARD_IMG_MARGIN_LEFT
                @img3.style.marginLeft = BOARD_IMG_MARGIN_LEFT_THREE_LEFT

    to_active_status : (id)->
        @in_iconfiy = false
        active_group?.to_normal_status()
        @indicate.src = "img/s_app_active.png"
        @leader = id
        DCore.Dock.active_window(@leader)
        active_group = @

    to_normal_status : ->
        @indicate.src = "img/s_app_open.png"

    withdraw_child: (id)->
        @w_clients.push(id)
        @remove_client(id, true)

    normal_child: (id)->
        @w_clients.remove(id)
        info = @client_infos[id]
        @add_client(info.id)

    update_client: (id, icon, title)->
        @img.src = icon if id == @leader
        icon = NOT_FOUND_ICON if not icon
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
            apply_rotate(@img, 1)

            if @leader != id
                @leader = id
                @update_leader()

            @handle_clients_change()
        @element.style.display = "block"


    remove_client: (id, used_internal=false) ->
        if not used_internal
            delete @client_infos[id]
            @w_clients.remove(id)

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
        try
            @img2.src = @client_infos[@n_clients[1]].icon
            @img3.src = @client_infos[@n_clients[2]].icon

    try_swap_launcher: ->
        l = Widget.look_up(@app_id)
        if l?
            swap_element(@element, l.element)
            apply_rotate(@img, 0.2)
            l.destroy()

    try_build_launcher: ->
        info = DCore.Dock.get_launcher_info(@app_id)
        if info
            l = new Launcher(info.Id, info.Icon, info.Core)
            swap_element(@element, l.element)

    destroy: ->
        @element.style.display = "block"
        @try_build_launcher()
        super

    do_buildmenu: ->
        [
            [1, _("OpenNew")],
            [2, _("Close")],
            [],
            [3, _("DockMe")],
            #[4, _("PreView"), false]
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
