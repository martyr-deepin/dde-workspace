pop_id = null
hide_id = null
class ClientGroup extends AppItem
    constructor:(@id, @dbus, @container)->
        super
        @n_clients = []
        @client_infos = {}
        for own k, v of @dbus.Data
            k = parseInt(k, 10)
            @n_clients.push(k)
            @update_client(k, v)
            console.log "ClientGroup:: Key: #{k}, Value:#{v}"
        @leader = null

        @indicatorWarp = create_element(tag:'div', class:"indicatorWarp", @element)
        @openIndicator = create_img(src:OPEN_INDICATOR, class:"indicator OpenIndicator", @indicatorWarp)

    destroy: ->
        Preview_close_now()
        @element.style.display = "block"
        @try_build_activator()
        super

    try_build_activator: ->
        info = DCore.Dock.get_launcher_info(@app_id)
        if info
            l = new Activator(info.Id, @dbus, @container)
            swap_element(@element, l.element)

    try_swap_activator: ->
        Preview_close_now()
        l = Widget.look_up(@app_id)
        if l?
            swap_element(@element, l.element)
            apply_rotate(@img, 0.2)
            l.destroy()

    to_active_status : (id)->
        @leader = id
        @n_clients.remove(id)
        @n_clients.unshift(id)
        # DCore.Dock.active_window(@leader)

    update_client: (id, title)->
        @client_infos[id] =
            "id": id
            "title": title
        @add_client(id)
        @update_scale()

    add_client: (id)->
        if @n_clients.indexOf(id) == -1
            @n_clients.unshift(id)
            apply_rotate(@img, 1)

            if @leader != id
                @leader = id

        @element.style.display = "block"


    remove_client: (id, used_internal=false) ->
        if not used_internal
            delete @client_infos[id]

        @n_clients.remove(id)

        if @n_clients.length == 0
            @destroy()
        else if @leader == id
            @next_leader()

    next_leader: ->
        @n_clients.push(@n_clients.shift())
        @leader = @n_clients[0]

    on_click:(e)=>
        super
        @notify_flag?.style.visibility = "hidden"

    on_mouseover: (e)=>
        super
        xy = get_page_xy(@element)
        w = @element.clientWidth || 0
        # console.log("mouseover: "+xy.y + ","+xy.x, +"clientWidth"+w)
        e.stopPropagation()
        __clear_timeout()
        clearTimeout(hide_id)
        clearTimeout(tooltip_hide_id)
        clearTimeout(launcher_mouseout_id)
        DCore.Dock.require_all_region()
        console.log @dbus.Type
        if @dbus.Type == "App"
            if @n_clients.length != 0
                Preview_show(@)
        else
            # console.log(@dbus.Allocation)
            Preview_show(@, width:@dbus.Allocation[2], height:@dbus.Allocation[3])

            # 3 for border's margin to element
            extraHeight = PREVIEW_TRIANGLE.height + PREVIEW_CONTAINER_BORDER_WIDTH * 2 + PREVIEW_WINDOW_MARGIN + PREVIEW_WINDOW_BORDER_WIDTH + 3
            @dbus.QuickWindow(xy.x + w/2, xy.y - extraHeight)

    on_mouseout: (e)=>
        super
        if not Preview_container.is_showing
            console.log "Preview_container is not showing"
            @dbus.HideQuickWindow?()
            # update_dock_region()
            calc_app_item_size()
            hide_id = setTimeout(->
                DCore.Dock.update_hide_mode()
            , 300)
        else
            console.log "Preview_container is showing"
            DCore.Dock.require_all_region()
            hide_id = setTimeout(=>
                calc_app_item_size()
                # update_dock_region()
                Preview_close_now()
                @dbus.HideQuickWindow?()
                DCore.Dock.update_hide_mode()
            , 1000)

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
