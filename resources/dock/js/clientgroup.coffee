pop_id = null
hide_id = null
class ClientGroup extends AppItem
    constructor: (@id, @icon, @app_id, @exec, @actions)->
        try
            super
            @n_clients = []
            @client_infos = {}

            @leader = null

            @open_indicator_short = create_img("OpenIndicator", SHORT_INDICATOR, @element)
            @open_indicator_long = create_img("OpenIndicator", LONG_INDICATOR, @element)
        catch error
            alert "Group constructor :#{error}"


    update_scale: ->
        super
        #TODO: why @n_clients maybe invalid !!!!!!!!!!!!
        if @n_clients
            @handle_clients_change()

    handle_clients_change: ->
        if not @_img_margin_top
            @_img_margin_top = 6 * ICON_SCALE

        if @n_clients.length > 1
            @open_indicator = @open_indicator_long
            @open_indicator_short.style.display = 'none'
            @open_indicator_long.style.display = 'block'
        else if @n_clients.length == 1
            @open_indicator = @open_indicator_short
            @open_indicator_short.style.display = 'block'
            @open_indicator_long.style.display = 'none'

    to_active_status : (id)->
        @leader = id
        @n_clients.remove(id)
        @n_clients.unshift(id)
        DCore.Dock.active_window(@leader)

    update_client: (id, icon, title)->
        icon = NOT_FOUND_ICON if not icon
        @client_infos[id] =
            "id": id
            "icon": icon
            "title": title
        @add_client(id)
        @update_scale()

    add_client: (id)->
        if @n_clients.indexOf(id) == -1
            @n_clients.unshift(id)
            apply_rotate(@img, 1)

            if @leader != id
                @leader = id

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

    try_swap_launcher: ->
        Preview_close_now()
        l = Widget.look_up(@app_id)
        if l?
            swap_element(@element, l.element)
            apply_rotate(@img, 0.2)
            l.destroy()

    try_build_launcher: ->
        info = DCore.Dock.get_launcher_info(@app_id)
        if info
            l = new Launcher(info.Id, info.Icon, info.Core, info.Actions)
            swap_element(@element, l.element)

    destroy: ->
        Preview_close_now()
        @element.style.display = "block"
        @try_build_launcher()
        super


    do_rightclick: (e)=>
        Preview_close_now()

        @menu?.destroy()
        @menu = null
        app_name = DCore.get_name_by_appid(@app_id)
        if app_name
            app_name = "_#{app_name}"
        else
            app_name = _("_New Window")
        @menu = new Menu(
            DEEPIN_MENU_TYPE.NORMAL,
            new MenuItem('10', app_name)
        ).addSeparator()

        action_len = @actions.length
        for i in [0...action_len]
            @menu.append(new MenuItem("#{i}", "_#{@actions[i].name}"))

        if action_len != 0
            @menu.addSeparator()

        @menu.append(new MenuItem("30", _("Close _All")))

        @menu.append(
            new MenuSeparator,
            new MenuItem("40", _("_Dock me")).setActive(!DCore.Dock.has_launcher(@app_id))
        )

        xy = get_page_xy(@element)
        # echo "#{menu}"
        # echo "#{xy.x}(+#{@element.clientWidth / 2})x#{xy.y}(+#{OFFSET_DOWN})"
        @menu.addListener(@on_itemselected).showMenu(
            xy.x + @element.clientWidth / 2,
            xy.y + OFFSET_DOWN,
            DEEPIN_MENU_CORNER_DIRECTION.DOWN
        )

    on_itemselected: (id, checked)=>
        super

        id = parseInt(id)
        # echo "id: #{id}"
        action = @actions[id]
        if action?
            # echo "#{action.name}, #{action.exec}"
            DCore.Dock.launch_from_commandline(@app_id, action.exec)
            return

        switch id
            when 10
                DCore.Dock.launch_by_app_id(@app_id, @exec, [])
            when 30
                @close_all_windows()
            when 40 then @record_launcher_position() if DCore.Dock.request_dock_by_client_id(@leader)

    close_all_windows: ->
        Preview_close_now()
        for i in [0...@n_clients.length]
            leader = @leader
            @next_leader()
            error = DCore.Dock.close_window(leader)
            if not error
                @remove_client(leader)

    record_launcher_position: ->
        DCore.Dock.insert_apps_position(@app_id, @next()?.app_id)

    notify: =>
        @notify_flag ?= create_img("NotifyFlag", NOTIFY_FLAG, @element)
        @notify_flag.style.visibility = "visible"

    do_click: (e)=>
        @notify_flag?.style.visibility = "hidden"
        if @n_clients.length == 1 and DCore.Dock.window_need_to_be_minimized(@leader)
            DCore.Dock.iconify_window(@leader)
        else
            if @n_clients.length > 1 and DCore.Dock.get_active_window() == @leader
                @next_leader()
            @to_active_status(@leader)

    do_mouseout: (e)=>
        super
        if not Preview_container.is_showing
            # update_dock_region()
            calc_app_item_size()
            hide_id = setTimeout(->
                DCore.Dock.update_hide_mode()
            , 300)
        else
            DCore.Dock.require_all_region()
            hide_id = setTimeout(->
                calc_app_item_size()
                # update_dock_region()
                Preview_close_now()
                DCore.Dock.update_hide_mode()
            , 1000)

    do_mouseover: (e)=>
        super
        e.stopPropagation()
        __clear_timeout()
        clearTimeout(hide_id)
        clearTimeout(tooltip_hide_id)
        clearTimeout(launcher_mouseout_id)
        DCore.Dock.require_all_region()
        if @n_clients.length != 0
            Preview_show(@)

    do_dragleave: (e) =>
        super
        clearTimeout(pop_id) if e.dataTransfer.getData('text/plain') != "swap"

    do_dragenter: (e) =>
        e.preventDefault()
        flag = e.dataTransfer.getData("text/plain")
        if flag != "swap" and @n_clients.length == 1
            pop_id = setTimeout(=>
                @to_active_status(@leader)
                pop_id = null
            , 1000)
        super

    do_drop: (e) =>
        super
        clearTimeout(pop_id) if e.dataTransfer.getData('text/plain') != "swap"

