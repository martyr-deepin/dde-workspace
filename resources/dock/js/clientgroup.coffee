pop_id = null
hide_id = null
class ClientGroup extends AppItem
    constructor: (@id, @icon, @app_id, @exec)->
        try
            super
            @n_clients = []
            @client_infos = {}

            @leader = null

            # @img is the behind one,
            # @img2 is the middle one,
            # @img3 is the front one.
            # set id for recognition at hand.
            @img.id = 'client_group_image_1'
            @img2 = create_img("AppItemImg", "", @element)
            @img2.id = 'client_group_image_2'
            @img3 = create_img("AppItemImg", "", @element)
            @img3.id = 'client_group_image_3'

            @open_indicator = create_img("OpenIndicator", "", @element)
            @open_indicator.style.left = INDICATER_IMG_MARGIN_LEFT

            @to_normal_status()
        catch error
            alert "Group construcotr :#{error}"

        # contextmenu and preview window cannot be shown at the same time
        @element.addEventListener("contextmenu", (e) =>
            Preview_close_now()
            menu = build_menu([
                [1, _("_New instance")],
                [2, _("_Close")],
                [3, _("Close _All"), @n_clients.length > 1]
                [],
                [4, _("_Dock me"), !DCore.Dock.has_launcher(@app_id)],
            ])
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
            @n_clients.remove(id)
            @n_clients.unshift(id)
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
        @update_scale()

    leader_img: (len) ->
        if len == 1
            return @img
        else if len == 2
            return @img2
        else if len >= 3
            return @img3
        else
            return null

    middle_img: (len) ->
        if len > 2
            return @img2
        else
            return @img3

    behind_img: (len) ->
        if len > 1
            return @img
        else
            return @img3

    add_client: (id)->
        if @n_clients.indexOf(id) == -1
            @n_clients.unshift(id)
            apply_rotate(@leader_img(@n_clients.length), 1)

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
        client_number = @n_clients.length
        @leader_img(client_number).src = @client_infos[@leader].icon
        #@img.setAttribute("title", @client_infos[@leader].title)
        if client_number == 2
            @behind_img(client_number).src = @client_infos[@n_clients[1]].icon
        else if client_number >= 3
            @middle_img(client_number).src = @client_infos[@n_clients[1]].icon
            @behind_img(client_number).src = @client_infos[@n_clients[2]].icon

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
        Preview_close_now()
        @element.style.display = "block"
        @try_build_launcher()
        super

    do_itemselected: (e)=>
        Preview_container.close()
        switch e.id
            when 1
                DCore.Dock.launch_by_app_id(@app_id, @exec, [])
            when 2
                Preview_close_now()
                DCore.Dock.close_window(@leader)
            when 3
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
            when 4 then @record_launcher_position() if DCore.Dock.request_dock_by_client_id(@leader)

    record_launcher_position: ->
        DCore.Dock.insert_apps_position(@app_id, @next()?.app_id)

    do_click: (e)->
        if @n_clients.length == 1 and DCore.Dock.window_need_to_be_minimized(@leader)
            DCore.Dock.iconify_window(@leader)
            @to_normal_status()
        else if @n_clients.length > 1 and DCore.Dock.get_active_window() == @leader
            @next_leader()
            @to_active_status(@leader)
        else
            @to_active_status(@leader)

    do_mouseout: (e)->
        if not Preview_container.is_showing
            update_dock_region()
            hide_id = setTimeout(->
                DCore.Dock.update_hide_mode()
            , 300)
        else
            DCore.Dock.require_all_region()
            hide_id = setTimeout(->
                update_dock_region()
                Preview_close_now()
                DCore.Dock.update_hide_mode()
            , 1000)

    do_mouseover: (e)=>
        e.stopPropagation()
        __clear_timeout()
        clearTimeout(hide_id)
        clearTimeout(tooltip_hide_id)
        clearTimeout(launcher_mouseout_id)
        DCore.Dock.require_all_region()
        if @n_clients.length != 0
            Preview_show(@)

    do_dragleave: (e) ->
        super
        clearTimeout(pop_id) if e.dataTransfer.getData('text/plain') != "swap"

    do_dragenter: (e) ->
        e.preventDefault()
        flag = e.dataTransfer.getData("text/plain")
        if flag != "swap" and @n_clients.length == 1
            pop_id = setTimeout(=>
                @to_active_status(@leader)
                pop_id = null
            , 1000)
        super

    do_drop: (e) ->
        super
        clearTimeout(pop_id) if e.dataTransfer.getData('text/plain') != "swap"
