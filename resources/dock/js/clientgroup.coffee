class ClientGroup extends AppItem
    constructor: (@id, @icon, @app_id, @exec)->
        try
            super
            @n_clients = []
            @client_infos = {}

            @open_indicator = create_img("OpenIndicator", "", @element)
            @open_indicator.style.left = INDICATER_IMG_MARGIN_LEFT

            @leader = null

            @img2 = create_img("AppItemImg", "", @element)
            @img3 = create_img("AppItemImg", "", @element)

            @to_normal_status()
        catch error
            alert "Group construcotr :#{error}"

    update_scale: ->
        super
        #TODO: why @n_clients maybe invalid !!!!!!!!!!!!
        if @n_clients
            @handle_clients_change()

    handle_clients_change: ->
        if not @_img_margin_top
            @_img_margin_top = 6 * ICON_SCALE
        switch @n_clients.length
            when 1
                @img.style.display = "block"
                @img2.style.display = "none"
                @img3.style.display = "none"
                @img.style.marginTop = @_img_margin_top

            when 2
                @img.style.display = "block"
                @img2.style.display = "block"
                @img3.style.display = "none"

                @img.style.marginTop = Number(@_img_margin_top) - 1 * ICON_SCALE
                @img2.style.marginTop = Number(@_img_margin_top) + 1 * ICON_SCALE

                @img.style.marginLeft = BOARD_IMG_MARGIN_LEFT_TWO_RIGHT
                @img2.style.marginLeft = BOARD_IMG_MARGIN_LEFT_TWO_LEFT
            else
                @img.style.display = "block"
                @img2.style.display = "block"
                @img3.style.display = "block"

                @img.style.marginTop = Number(@_img_margin_top) - 2 * ICON_SCALE
                @img2.style.marginTop = @_img_margin_top
                @img3.style.marginTop = Number(@_img_margin_top) + 2 * ICON_SCALE

                @img.style.marginLeft = BOARD_IMG_MARGIN_LEFT_THREE_RIGHT
                @img2.style.marginLeft = BOARD_IMG_MARGIN_LEFT
                @img3.style.marginLeft = BOARD_IMG_MARGIN_LEFT_THREE_LEFT

    to_active_status : do ->
        active_group = null
        (id)->
            active_group?.to_normal_status()
            @open_indicator.src = ACTIVE_STATUS_INDICATOR
            @leader = id
            DCore.Dock.active_window(@leader)
            active_group = @

    to_normal_status : ->
        @open_indicator.src = NORMAL_STATUS_INDICATOR

    update_client: (id, icon, title)->
        icon = NOT_FOUND_ICON if not icon
        @client_infos[id] =
            "id": id
            "icon": icon
            "title": title
        @add_client(id)
        @update_leader()

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

        @n_clients.remove(id)


        if @n_clients.length == 0
            @destroy()
        else if @leader == id
            @next_leader()

        @handle_clients_change()

    next_leader: ->
        @n_clients.push(@n_clients.shift())
        @leader = @n_clients[0]
        @update_leader()

    update_leader: ->
        @img.src = @client_infos[@leader].icon
        #@img.setAttribute("title", @client_infos[@leader].title)
        @img2.src = @client_infos[@n_clients[1]].icon if @n_clients.length > 1
        @img3.src = @client_infos[@n_clients[2]].icon if @n_clients.length > 2

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
            [1, _("New instance")],
            [2, _("Close")],
            [],
            [3, _("Dock me"), !DCore.Dock.has_launcher(@app_id)],
        ]

    do_itemselected: (e)=>
        Preview_container.close()
        switch e.id
            when 1 then DCore.Dock.launch_by_app_id(@app_id, @exec, [])
            when 2 then DCore.Dock.close_window(@leader)
            when 3 then @record_launcher_position() if DCore.Dock.request_dock_by_client_id(@leader)

    record_launcher_position: ->
        DCore.Dock.insert_apps_position(@app_id, @next()?.app_id)

    do_click: (e)->
        if @n_clients.length == 1 and DCore.Dock.window_need_to_be_minimized(@leader)
            DCore.Dock.iconify_window(@leader)
            @to_normal_status()
        else if @n_clients.length > 1 and DCore.Dock.is_active_window(@leader)
            @next_leader()
            @to_active_status(@leader)
        else
            @to_active_status(@leader)

    do_mouseover: (e)->
        e.stopPropagation()
        Preview_show(@)
