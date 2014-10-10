dbus = null
activeWindowTimer = null
normal_mouseout_id = null
closePreviewWindowTimer = null
_lastCliengGroup = null
pop_id = null
hide_id = null

_clear_item_timeout = ->
    clearTimeout(normal_mouseout_id)

class Item extends Widget
    constructor:(@id, icon, title, @container)->
        super()
        @imgWrap = create_element(tag:'div', class:"imgWrap", @element)
        @imgContainer = create_element(tag:'div', class:"imgContainer", @imgWrap)
        @imgContainer.style.pointerEvents = 'none'
        @img = create_img(src:icon || NOT_FOUND_ICON, class:"AppItemImg", @imgContainer)
        @imgHover = create_img(src:"", class:"AppItemImg", @imgContainer)
        @imgHover.style.display = 'none'
        @imgDark = create_img(src:"", class:"AppItemImg", @imgContainer)
        @imgDark.style.display = 'none'

        @imgWrap.classList.add("ReflectImg")

        @img.onload = =>
            dataUrl = bright_image(@img, 40)
            @imgHover.src = dataUrl
            dataUrl = bright_image(@img, -40)
            @imgDark.src = dataUrl

        switch settings.displayMode()
            when DisplayMode.Fashion
                @imgWrap.draggable = true
            when DisplayMode.Efficient, DisplayMode.Classic
                @imgWrap.draggable = false

        @imgWrap.style.pointerEvents = "auto"
        @imgWrap.addEventListener("mouseover", @on_mouseover)
        @imgWrap.addEventListener("mouseover", @on_mousemove)
        @imgWrap.addEventListener("mouseout", @on_mouseout)
        @imgWrap.addEventListener("mousedown", @on_mousedown)
        @imgWrap.addEventListener("mouseup", @on_mouseup)
        @imgWrap.addEventListener("contextmenu", @on_rightclick)
        @imgWrap.addEventListener("dragstart", @on_dragstart)
        @imgWrap.addEventListener("dragenter", @on_dragenter)
        @imgWrap.addEventListener("dragover", @on_dragover)
        @imgWrap.addEventListener("dragleave", @on_dragleave)
        @imgWrap.addEventListener("drop", @on_drop)
        @imgWrap.addEventListener("dragend", @on_dragend)
        @imgWrap.addEventListener("mousewheel", @on_mousewheel)

        calc_app_item_size()
        @tooltip = null
        @element.classList.add("AppItem")

        e = document.getElementsByName(@id)
        if e.length != 0
            e = e[0]
            e.parentNode.insertBefore(@element, e)
            e.parentNode.removeChild(e)
            sortDockedItem()
        else
            @container?.appendChild?(@element)

        if debugRegion
            console.warn("Item.ctor")
        update_dock_region($("#container").clientWidth)

    change_icon: (src)->
        @img.src = src
        @img.onload = =>
            @imgHover.src = bright_image(@img, 40)
            @imgDark.src = bright_image(@img, -40)

    set_tooltip: (text) ->
        if @windowTitle
            @windowTitle.textContent = text

        if @tooltip == null
            # @tooltip = new ToolTip(@element, text)
            @tooltip = new ArrowToolTip(@imgWrap, text)
            @tooltip.set_delay_time(200)  # set delay time to the same as scale time
            return
        @tooltip.set_text(text)

    destroy_tooltip:->
        @tooltip?.hide()
        @tooltip?.destroy()
        @tooltip = null

    isNormal:->
        true

    isNormalApplet:->
        false

    isActive:->
        false

    isRuntimeApplet:->
        false

    update_scale:->

    displayIcon:(type="")->
        if type
            type = type[0].toUpperCase() + type.substr(1).toLowerCase()
        @img.style.display = 'none'
        @imgHover.style.display = 'none'
        @imgDark.style.display = 'none'
        this["img#{type}"].style.display = ''

    on_mousemove: (e)=>
        if e
            $mousePosition.x = e.x
            $mousePosition.y = e.y

        resetAllItems()
        # clearRegion()

    on_mouseover:(e)=>
        @destroy_tooltip()
        @on_mousemove(e)

        if _isRightclicked || settings.hideMode() != HideMode.KeepShowing and hideStatusManager.state != HideState.Shown
            $tooltip?.hide()
            return
        DCore.Dock.require_all_region()
        @displayIcon('hover')

    on_mouseout:(e)=>
        DCore.Dock.set_is_hovered(false)
        @displayIcon()

    on_mousewheel:(e)=>
        @core?.onMouseWheel(e.x, e.y, e.wheelDeltaY)

    on_rightclick:(e)=>
        _isRightclicked = true
        DCore.Dock.set_is_hovered(false)
        if debugRegion
            console.warn("[Item.on_rightclick] update_dock_region")
        update_dock_region($("#container").clientWidth)
        e.preventDefault()
        e.stopPropagation()
        # @tooltip?.hide()
        @destroy_tooltip()

    on_mousedown:(e)=>
        if e.button != 0
            return
        Preview_close_now()
        # @tooltip?.hide()
        @destroy_tooltip()
        @displayIcon('dark')

    on_mouseup:(e)=>
        @displayIcon('hover')

    # on_click:(e)=>
    #     e?.preventDefault()
    #     e?.stopPropagation()
    #     Preview_close_now()

    on_dragend:(e)=>
        e.preventDefault()
        clearTimeout(@removeTimer || null)
        if debugRegion
            console.warn("[Item.on_dragend] update_dock_region")
        update_dock_region()
        _lastHover?.reset()
        @element.style.position = ''
        @element.style.webkitTransform = ''
        _dragTarget = _dragTargetManager.getHandle(@id)
        if not _dragTarget
            console.log("get handle failed")
            return
        _dragTarget.reset()
        _dragTarget.removeImg()
        if _dragTarget.dragToBack
            _dragTarget.back(e.x, e.y)
        @removeTimer = setTimeout(=>
            _dragTargetManager.remove(@id)
        , 1000)

    on_dragstart: (e)=>
        Preview_close_now()
        _dragTarget = new DragTarget(@)
        clearTimeout(@removeTimer || null)
        clearTimeout(_isDragTimer)
        _dragTargetManager.add(@id, _dragTarget)
        pos = get_page_xy(@element)
        _dragTarget.setOrigin(pos.x, pos.y)
        _lastHover = null
        app_list.setInsertAnchor(@element.nextSibling)
        if el = @element.nextSibling
            el.style.marginLeft = "#{INSERT_INDICATOR_WIDTH}px"
        else if el = @element.previousSibling
            el.style.marginRight = "#{INSERT_INDICATOR_WIDTH}px"

        if el
            if not _isDragging
                updatePanel()
                _isDragging = true
            _lastHover = Widget.look_up(el.getAttribute('id')) || null
        setTimeout(=>
            _b.appendChild(@element)
            @element.style.position = 'absolute'
            @element.style.webkitTransform = "translateY(-#{ITEM_HEIGHT}px)"
            @element.style.display = 'none'
        , 10)
        e.stopPropagation()
        Preview_close_now()
        DCore.Dock.require_all_region()
        return if @is_fixed_pos
        if @isNormal()
            # @tooltip?.hide()
            @destroy_tooltip()
        dt = e.dataTransfer
        dt.setData(DEEPIN_ITEM_ID, @id)

        # flag for doing swap between items
        dt.setData("text/plain", "swap")
        dt.effectAllowed = "copyMove"
        dt.dropEffect = 'none'

    move:(x, threshold)=>
        if _lastHover and _lastHover.id != @id
            _lastHover.reset()
        _lastHover = @

        @reset()
        if x < threshold
            if t = @element.nextSibling
                t.style.marginLeft = ''
                t.style.marginRight = ''
            @element.style.marginLeft = "#{INSERT_INDICATOR_WIDTH}px"
            @element.style.marginRight = ''
            app_list.setInsertAnchor(@element)
        else
            if t = @element.nextSibling
                t.style.marginLeft = "#{INSERT_INDICATOR_WIDTH}px"
                t.style.marginRight = ''
            else
                @element.style.marginLeft = ''
                @element.style.marginRight = "#{INSERT_INDICATOR_WIDTH}px"
            app_list.setInsertAnchor(t)

        if not _isDragging
            updatePanel()
            _isDragging = true

        _isItemExpanded = true
        setTimeout(->
            systemTray.updateTrayIcon()
        , 100)

    reset:->
        setTimeout(->
            systemTray.updateTrayIcon()
        , 100)
        _isItemExpanded = false
        _isDragTimer = setTimeout(->
            _isDragging = false
        , 500)
        # updatePanel()
        @element.style.marginLeft = ''
        @element.style.marginRight = ''
        if t = @element.nextSibling
            t.style.marginRight = ''
            t.style.marginLeft = ''

    on_dragenter: (e)=>
        e.preventDefault()
        e.stopPropagation()
        return if @is_fixed_pos
        # DCore.Dock.require_all_region()
        if dnd_is_deepin_item(e) or dnd_is_desktop(e)
            @move(e.offsetX, @element.clientWidth / 2)
        else
            # TODO
            # activeWindowTimer = setTimeout(=>
            #     if @n_clients.length == 1
            #         clientManager?.ActiveWindow(@n_clients[0])
            #         update_dock_region()
            #     else
            #         @on_mouseover()
            # , 1000)

    on_dragleave: (e)=>
        clearTimeout(activeWindowTimer)
        if debugRegion
            console.warn("[Item.on_dragleave] update_dock_region")
        update_dock_region()
        e.preventDefault()
        e.stopPropagation()

    on_dragover:(e)=>
        e.stopPropagation()
        e.preventDefault()
        return if @is_fixed_pos
        if dnd_is_deepin_item(e) or dnd_is_desktop(e)
            @move(e.offsetX, @element.clientWidth / 2)

    on_drop: (e) =>
        _dropped = true
        e.preventDefault()
        e.stopPropagation()
        updatePanel()
        dt = e.dataTransfer
        _lastHover?.reset()
        tmp_list = []
        for file in dt.files
            path = decodeURI(file.path)
            tmp_list.push(path)
        if tmp_list.length > 0
            fileList = tmp_list.join()
            @core?.onDrop(fileList)
        if debugRegion
            console.warn("[Item.on_drop] update_dock_region")
        update_dock_region()


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

        @set_tooltip(@core.title() || UNKNOWN_TITLE)

        @clientgroupInited = true

    init_activator:->
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
            updateMaxClientListWidth()
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
                    @moveApplet(size)

                    clearTimeout(@showEmWindowTimer || null)
                    if Preview_container.border.classList.contains("moveAnimation")
                        @showEmWindowTimer = setTimeout(=>
                            @embedWindows.show()
                        , 400)
                    else
                        @embedWindows.show()
                )

    moveApplet: (size)=>
        ew = @embedWindows
        xy = get_page_xy(@element)
        w = @element.clientWidth || 0
        extraSize = PREVIEW_SHADOW_BLUR + PREVIEW_WINDOW_BORDER_WIDTH + PREVIEW_CONTAINER_BORDER_WIDTH
        extraHeight = PREVIEW_TRIANGLE.height + extraSize + size.height
        x = xy.x + w/2 - size.width/2
        if x + size.width > screen.width
            x -= x + size.width - screen.width + extraSize
        y = xy.y - extraHeight
        ew.move(ew.xids[0], x, y)

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
