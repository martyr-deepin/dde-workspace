_lastCliengGroup = null
pop_id = null
hide_id = null
class ClientGroup extends AppItem
    constructor:(@id, @icon, title, @container)->
        super
        @n_clients = []
        @client_infos = {}
        if (d = $DBus[@id])
            console.log "#{@id}: #{d.Type}, #{d.Data[ITEM_DATA_FIELD.xids]}"
            xids = JSON.parse(d.Data[ITEM_DATA_FIELD.xids])
            if d.Type == ITEM_TYPE.applet
                @embedWindows = new EmbedWindow(xids)
            for xidInfo in xids
                @n_clients.push(xidInfo.Xid)
                @update_client(xidInfo.Xid, xidInfo.Title)
                # console.log "ClientGroup:: Key: #{xidInfo.Xid}, Valvue:#{xidInfo.Title}"
        @leader = null

        @indicatorWarp = create_element(tag:'div', class:"indicatorWarp", @element)
        @openIndicator = create_img(src:OPEN_INDICATOR, class:"indicator OpenIndicator", @indicatorWarp)

    destroy: ->
        # console.log("ClientGroup::destroy")
        Preview_close_now(@)
        @element.style.display = "block"
        # @try_build_activator()
        super

    try_build_activator: ->
        info = DCore.Dock.get_launcher_info(@app_id)
        if info
            l = new Activator(info.Id, @icon, title, @container)
            swap_element(@element, l.element)

    try_swap_activator: ->
        Preview_close_now(@)
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
        _lastCliengGroup?.embedWindows?.hide?()
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
        d = $DBus[@id]
        # console.log d.Type if d
        # console.log @embedWindows
        # console.log("ClientGroup mouseover")
        # console.log(d.Type)
        if d && d.Type == ITEM_TYPE.app
            # console.log("App show preview")
            if @n_clients.length != 0
                Preview_show(@)
        else if @embedWindows
            # console.log("Applet show preview")
            size = @embedWindows.window_size(@embedWindows.xids[0])
            # console.log size
            width = size.width
            height = size.height
            # console.log("size: #{width}x#{height}")
            Preview_show(@, width:width, height:height, =>
                # 6 for container's blur
                extraHeight = PREVIEW_TRIANGLE.height + 6 + PREVIEW_WINDOW_MARGIN + PREVIEW_WINDOW_BORDER_WIDTH + PREVIEW_CONTAINER_BORDER_WIDTH + height
                @embedWindows.show()
                x = xy.x + w/2 - width/2
                y = xy.y - extraHeight
                # console.log("Move Window to #{x}, #{y}")
                @embedWindows.move(@embedWindows.xids[0], x, y)
            )

    on_mouseout: (e)=>
        _lastCliengGroup = @
        super
        if not Preview_container.is_showing
            # console.log "Preview_container is not showing"
            # update_dock_region()
            calc_app_item_size()
            hide_id = setTimeout(=>
                DCore.Dock.update_hide_mode()
                @embedWindows?.hide()
            , 300)
        else
            # console.log "Preview_container is showing"
            DCore.Dock.require_all_region()
            hide_id = setTimeout(=>
                @embedWindows?.hide()
                calc_app_item_size()
                # update_dock_region()
                Preview_close_now(@)
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
