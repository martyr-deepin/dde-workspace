class AppItem extends Item
    is_fixed_pos: false
    constructor:(@id, icon, title, @container)->
        super
        @changeImgTimer = null
        @currentImg = @img

        @core = new EntryProxy($DBus[@id])

        @lastStatus = @core.status()
        @clientgroupInited = @isActive()
        @indicatorWrap = create_element(tag:'div', class:"indicatorWrap", @element)
        @openingIndicator = create_img(src:OPENING_INDICATOR, class:"indicator OpeningIndicator", @indicatorWrap)
        @openingIndicator.addEventListener("webkitAnimationEnd", @on_animationend)
        @windowTitleWrap = create_element(tag:"div", class:"windowTitleWrap", @imgContainer)
        @windowTitle = create_element(tag:"div", class:"windowTitle vertical_center", @windowTitleWrap)
        switch settings.displayMode()
            when DisplayMode.Fashion
                @openIndicator = create_img(src:OPEN_INDICATOR, class:"indicator OpenIndicator", @indicatorWrap)
                @hoverIndicator = create_img(src:OPEN_INDICATOR, class:"indicator HoverOpenIndicator", @indicatorWrap)
            when DisplayMode.Efficient
                @openIndicator = create_img(src:EFFICIENT_ACTIVE_IMG, class:"indicator OpenIndicator", @indicatorWrap)
                @hoverIndicator = create_img(src:EFFICIENT_ACTIVE_HOVER_IMG, class:"indicator HoverOpenIndicator", @indicatorWrap)
            when DisplayMode.Classic
                @openIndicator = create_img(src:CLASSIC_ACTIVE_IMG, class:"indicator OpenIndicator", @indicatorWrap)
                @hoverIndicator = create_img(src:CLASSIC_ACTIVE_HOVER_IMG, class:"indicator HoverOpenIndicator", @indicatorWrap)

        @tooltip = null

        @hide_open_indicator()
        if @isNormal() || @isNormalApplet()
            @init_activator()
        else
            @init_clientgroup()

        if @isRuntimeApplet()
            @hide_open_indicator()

        @core?.connect("DataChanged", (name, value)=>
            # console.log("DataChanged[#{name}]")
            switch name
                when ITEM_DATA_FIELD.xids
                    if not @clientgroupInited
                        return
                    # [{Xid:0, Title:""}]
                    xids = JSON.parse(value)
                    for info in xids
                        @update_client(info.Xid, info.Title)

                    ids = @n_clients.slice(0)
                    for id in ids
                        needDelete = true
                        for info in xids
                            if id == info.Xid
                                needDelete = false
                                break
                        if needDelete
                            @remove_client(id)

                    return
                when ITEM_DATA_FIELD.status
                    if @lastStatus == value
                        return
                    @lastStatus = value
                    if @isNormal()
                        console.log("is normal")
                        @swap_to_activator()
                    else if @isActive()
                        if @openingIndicator.style.webkitAnimationName == ''
                            @swap_to_clientgroup()
                when ITEM_DATA_FIELD.icon
                    if value.substring(0, 7) == "file://" || value.substring(0, 10) == "data:image"
                        @change_icon(value)
                    else
                        v = DCore.get_theme_icon(value, 48)
                        @change_icon(v)
                when ITEM_DATA_FIELD.title
                    @set_tooltip(value || UNKNOWN_TITLE)
        )

    hide_open_indicator:->
        @element.classList.remove("active_hover")
        @element.classList.remove("active")
        @element.classList.remove("ClientGroup_hover")

    show_open_indicator:->
        @hide_open_indicator()
        if activeWindow and activeWindow.itemId and activeWindow.itemId == @id
            @element.classList.add("active")

    show_hover_indicator:->
        @hide_open_indicator()
        if activeWindow and activeWindow.itemId and activeWindow.itemId == @id
            @element.classList.add("active_hover")
        else
            @element.classList.add("ClientGroup_hover")

    init_clientgroup:->
        @n_clients = []
        @client_infos = {}
        @leader = null

        if settings.displayMode() != DisplayMode.Fashion
            @update_draggable(@element)
        else
            @update_draggable(@imgWrap)

        if not @core or not (xids = JSON.parse(@core.xids()))
            return

        for xidInfo in xids
            @n_clients.push(xidInfo.Xid)
            @update_client(xidInfo.Xid, xidInfo.Title)

        if @isApplet()
            for xid in xids
                $EW_MAP[xid.Xid] = @
            @embedWindows = new EmbedWindow(xids)
        else
            @show_open_indicator()
            @element.classList.remove("Activator")
            @element.classList.add("ClientGroup")
            launcherDaemon?.MarkLaunched(@id)
            launcherDaemon?.RecordRate(@id)

        @set_tooltip(@core.title() || UNKNOWN_TITLE)

        @clientgroupInited = true

    init_activator:->
        @update_draggable(@imgWrap)

        @hide_open_indicator()
        title = @core.title() || UNKNOWN_TITLE
        @set_tooltip(title)
        @clientgroupInited = false
        @element.classList.remove("ClientGroup")
        @element.classList.add("Activator")

    swap_to_clientgroup:->
        @openingIndicator.style.display = 'none'
        @openingIndicator.style.webkitAnimationName = ''
        if not @isApplet()
            @show_open_indicator()
        @destroy_tooltip()
        @init_clientgroup()

    swap_to_activator:->
        @element.style.display = 'none'
        @hide_open_indicator()
        Preview_close_now()
        @init_activator()
        @element.offsetWidth # force web to calculate, otherwise it won't work.
        @element.style.display = ''

    update_client: (id, title)->
        @client_infos[id] =
            "id": id
            "title": title
        @add_client(id)
        @update_scale()

    add_client: (id)->
        if @n_clients.indexOf(id) == -1
            @n_clients.unshift(id)

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

    destroy: ->
        if @isNormal()
            super
            @destroy_tooltip()
            calc_app_item_size()
            if debugRegion
                console.warn("[AppItem.destroy] update_dock_region")
            update_dock_region($("#container").clientWidth)
        else
            if Preview_container._current_group && @id == Preview_container._current_group.id
                Preview_close_now(@)
            @element.style.display = "block"
            super

        delete $DBus[@id]

    destroyWidthAnimation:->
        @img.classList.remove("ReflectImg")
        @rotate(300)
        setTimeout(=>
            @destroy()
            dockedAppManager.Undock(@id)
        ,300)

    rotate:(time=1000)->
        apply_animation(@imgWrap, "rotateOut", time)

    isNormal:->
        @core.isNormal?()

    isActive:->
        @core.isActive?()

    isApp:->
        @core.isApp?()

    isApplet:->
        @core.isApplet?()

    isRuntimeApplet:->
        @core?.isRuntimeApplet?()

    isNormalApplet:->
        @core?.isNormalApplet?()

    on_mouseover:(e)=>
        super
        if _isRightclicked || settings.hideMode() != HideMode.KeepShowing and hideStatusManager.state != HideState.Shown
            console.log("hide state is not Shown")
            @destroy_tooltip()
            # $tooltip?.hide()
            return
        if @isNormal() || @isNormalApplet()
            @set_tooltip(@core.title() || UNKNOWN_TITLE)
            @tooltip.show()
            clearTimeout(hide_id)
            closePreviewWindowTimer = setTimeout(->
                Preview_close_now(Preview_container._current_group)
            , 200)
        else
            if @isApp()
                @show_hover_indicator()

            if _lastCliengGroup and _lastCliengGroup.id != @id
                _lastCliengGroup.embedWindows?.hide?()

            e?.stopPropagation()
            __clear_timeout()
            clearTimeout(hide_id)
            clearTimeout(tooltip_hide_id)
            clearTimeout(closePreviewWindowTimer)
            _clear_item_timeout()

            _lastCliengGroup = @
            if @core && @isApp()
                if @n_clients.length != 0
                    Preview_show(@)
            else if @embedWindows
                @core?.showQuickWindow()

                try
                    size = @embedWindows.window_size(@embedWindows.xids[0])
                catch e
                    console.log(e)
                Preview_show(@, size, (c)=>
                    clearTimeout(@showEmWindowTimer || null)
                    @showEmWindowTimer = setTimeout(=>
                        _lastCliengGroup?.embedWindows?.hide?()
                        for own xid, value of $EW_MAP
                            $EW.hide(xid)
                        @embedWindows.show()
                    , 0)
                    @updateAppletPosition()
                )

    updateAppletPosition: ()=>
        size = @embedWindows.window_size(@embedWindows.xids[0])
        ew = @embedWindows
        xy = get_page_xy(@element)
        w = @element.clientWidth || 0
        extraSize = PREVIEW_SHADOW_BLUR + PREVIEW_WINDOW_BORDER_WIDTH + PREVIEW_CONTAINER_BORDER_WIDTH
        extraHeight = PREVIEW_TRIANGLE.height + extraSize + size.height
        x = xy.x + w/2 - size.width/2
        if x + size.width > screen.width
            x -= x + size.width - screen.width + extraSize
        y = xy.y - extraHeight

        clearTimeout(@__move_applet_timeout)
        @__move_applet_timeout = setTimeout(=>
            ew.move(ew.xids[0], x, y)
            if Preview_container._current_group == @
                Preview_container._calc_size(size)
        , 10)

    on_mouseout:(e)=>
        super
        clearTimeout(@showEmWindowTimer)
        if @isNormal()
            if Preview_container.is_showing
                __clear_timeout()
                clearTimeout(closePreviewWindowTimer)
                clearTimeout(tooltip_hide_id)
                DCore.Dock.require_all_region()
                normal_mouseout_id = setTimeout(->
                    if debugRegion
                        console.warn("[AppItem.on_mouseout] update_dock_region")
                    update_dock_region()
                , 1000)
            else
                if debugRegion
                    console.warn("[AppItem.on_mouseout] update_dock_region")
                update_dock_region()
                normal_mouseout_id = setTimeout(->
                    hideStatusManager.updateState()
                , 500)
        else
            if not @isApplet()
                @show_open_indicator()
            __clear_timeout()
            _clear_item_timeout()
            if not Preview_container.is_showing
                # calc_app_item_size()
                hide_id = setTimeout(=>
                    if debugRegion
                        console.warn("[AppItem.on_mouseout] update_dock_region")
                    update_dock_region()
                    hideStatusManager.updateState()
                    # @embedWindows?.hide()
                , 300)
            else
                DCore.Dock.require_all_region()
                hide_id = setTimeout(=>
                    if debugRegion
                        console.warn("[AppItem.on_mouseout] update_dock_region")
                    update_dock_region()
                    Preview_close_now(@)
                    hideStatusManager.updateState()
                , 1000)

    on_rightclick:(e)=>
        super
        _clear_item_timeout()
        clearTimeout(@showEmWindowTimer)
        Preview_close_now()
        setTimeout(->
            Preview_close_now()
        , 300)
        xy = get_page_xy(@element)

        clientHalfWidth = @element.clientWidth / 2
        menuContent = @core.menuContent?()
        if not menuContent
            _isRightclicked = false
            return

        screenOffset =
            x: e.screenX - e.pageX
            y: e.screenY - e.pageY

        menu =
            x: xy.x + clientHalfWidth + screenOffset.x
            y: xy.y + screenOffset.y - ITEM_MENU_OFFSET
            isDockMenu: true
            cornerDirection: DEEPIN_MENU_CORNER_DIRECTION.DOWN
            menuJsonContent: menuContent

        menuJson = JSON.stringify(menu)

        try
            manager = get_dbus(
                "session",
                name:DEEPIN_MENU_NAME,
                path:DEEPIN_MENU_PATH,
                interface:DEEPIN_MENU_MANAGER_INTERFACE,
                "RegisterMenu"
            )
        catch e
            console.log(e)
            _isRightclicked = false
            return

        menu_dbus_path = manager.RegisterMenu_sync()
        # echo "menu path is: #{menu_dbus_path}"
        try
            dbus = get_dbus(
                "session",
                name:DEEPIN_MENU_NAME,
                path:menu_dbus_path,
                interface:DEEPIN_MENU_INTERFACE,
                "ShowMenu"
            )
        catch e
            conosle.log("get menu dbus failed: #{e}")
            _isRightclicked = false
            return

        dbus.connect("ItemInvoked", @on_itemselected($DBus[@id]))
        dbus.connect("MenuUnregistered", ->
            handleMenuUnregister()
            dbus = null
        )
        dbus.ShowMenu(menuJson)

    on_itemselected: (d)->
        (id)->
            d?.HandleMenuItem(id)

    startSuccess:=>
        if @isNormal() and settings.displayMode() == DisplayMode.Fashion
            @openNotify()

    startError:=>
        dockedAppManager.Undock(@id)

    on_mouseup:(e)=>
        super
        if e.button != 0
            return

        @core.activate?(0, 0, @startSuccess, @startError)

    openNotify:->
        @openingIndicator.style.display = 'inline'
        @openingIndicator.style.webkitAnimationName = 'Breath'

    on_animationend: (e)=>
        @openingIndicator.style.webkitAnimationName = ''
        @openingIndicator.style.display = 'none'
        if @lastStatus == "active"
            @swap_to_clientgroup()

    to_active_status : (id)->
        @leader = id
        @n_clients.remove(id)
        @n_clients.unshift(id)

    on_dragleave: (e) =>
        super
        clearTimeout(pop_id) if e.dataTransfer.getData('text/plain') != "swap"

    on_drop: (e) =>
        super
        clearTimeout(pop_id) if e.dataTransfer.getData('text/plain') != "swap"

