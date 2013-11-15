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
            alert "Group construcotr :#{error}"

        @build_menu()

    build_menu: ->
        # contextmenu and preview window cannot be shown at the same time
        @element.addEventListener("contextmenu", (e) =>
            Preview_close_now()
            menu_list = [
                [10, _("_New instance")],
                []
            ]
            i = 0
            len = @actions.length

            while i < len
                i = i + 1
                menu_list.push([i, @actions[i - 1].name])

            if len != 0
                menu_list.push([])

            menu_list.push([20, _("_Close")])
            menu_list.push([30, _("Close _All"), @n_clients.length > 1])
            menu_list.push([])
            menu_list.push([40, _("_Dock me"), !DCore.Dock.has_launcher(@app_id)])
            menu = build_menu(menu_list)

            @element.contextMenu = menu
            e.stopPropagation()
        )

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

    do_itemselected: (e)=>
        super
        Preview_container.close()

        index = e.id - 1
        action = @actions[index]
        if action?
            DCore.Dock.launch_from_commandline(@app_id, action.exec)
            return

        switch e.id
            when 10
                echo "#{@app_id}, #{@exec}"
                DCore.Dock.launch_by_app_id(@app_id, @exec, [])
            when 20
                Preview_close_now()
                DCore.Dock.close_window(@leader)
            when 30
                @close_all_windows()
            when 40 then @record_launcher_position() if DCore.Dock.request_dock_by_client_id(@leader)

    close_all_windows: ->
            Preview_close_now()
            i = 0
            size = @n_clients.length
            while i < size
                leader = @leader
                @next_leader()
                error = DCore.Dock.close_window(leader)
                if not error
                    @remove_client(leader)
                i += 1

    record_launcher_position: ->
        DCore.Dock.insert_apps_position(@app_id, @next()?.app_id)

    do_click: (e)=>
        if @n_clients.length == 1 and DCore.Dock.window_need_to_be_minimized(@leader)
            DCore.Dock.iconify_window(@leader)
        else if @n_clients.length > 1 and DCore.Dock.get_active_window() == @leader
            @next_leader()
            @to_active_status(@leader)
        else
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

