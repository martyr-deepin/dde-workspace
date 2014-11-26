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
    constructor:(@id, @icon, title, @container)->
        super()
        @imgWrap = create_element(tag:'div', class:"imgWrap", @element)
        @imgContainer = create_element(tag:'div', class:"imgContainer", @imgWrap)
        @imgContainer.style.pointerEvents = 'none'
        @img = create_img(src:"", class:"AppItemImg", @imgContainer)
        @imgHover = create_img(src:"", class:"AppItemImg", @imgContainer)
        @imgHover.style.display = 'none'
        @imgDark = create_img(src:"", class:"AppItemImg", @imgContainer)
        @imgDark.style.display = 'none'

        @imgWrap.classList.add("ReflectImg")

        @change_icon(icon || NOT_FOUND_ICON)

        @imgWrap.style.pointerEvents = "auto"
        @imgWrap.addEventListener("mouseover", @on_mouseover)
        @imgWrap.addEventListener("mouseover", @on_mousemove)
        @imgWrap.addEventListener("mouseout", @on_mouseout)
        @imgWrap.addEventListener("mousedown", @on_mousedown)
        @imgWrap.addEventListener("mouseup", @on_mouseup)
        @imgWrap.addEventListener("contextmenu", @on_rightclick)
        @imgWrap.addEventListener("mousewheel", @on_mousewheel)

        @draggable = null
        @update_draggable(@imgWrap)

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
        if not (src.substring(0, 7) == "file://" || src.substring(0, 10) == "data:image")
            icon_size = 48
            src = DCore.get_theme_icon(src, icon_size) || DCore.get_theme_icon(NOT_FOUND_ICON, 48)
        @img.src = src
        @img.onload = =>
            console.error(@img.src)
            @imgHover.src = bright_image(@img, 40)
            @imgHover.onerror = =>
                if @imgHover.src != @img.src
                    @imgHover.src = @img.src
            @imgDark.src = bright_image(@img, -40)
            @imgDark.onerror = =>
                if @imgDark.src != @img.src
                    @imgDark.src = @img.src

        @img.onerror = =>
            console.error("wrong img")
            if @img.src != DCore.get_theme_icon(NOT_FOUND_ICON, 48)
                @img.src = DCore.get_theme_icon(NOT_FOUND_ICON)

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

    update_draggable: (el)->
        if @draggable && @draggable.isSameNode(el)
            return
        if @draggable != null
            @draggable.draggable = false
            @draggable.removeEventListener("dragstart", @on_dragstart)
            @draggable.removeEventListener("dragenter", @on_dragenter)
            @draggable.removeEventListener("dragover", @on_dragover)
            @draggable.removeEventListener("dragleave", @on_dragleave)
            @draggable.removeEventListener("drop", @on_drop)
            @draggable.removeEventListener("dragend", @on_dragend)

        @draggable = el
        @draggable.draggable = true
        @draggable.addEventListener("dragstart", @on_dragstart)
        @draggable.addEventListener("dragenter", @on_dragenter)
        @draggable.addEventListener("dragover", @on_dragover)
        @draggable.addEventListener("dragleave", @on_dragleave)
        @draggable.addEventListener("drop", @on_drop)
        @draggable.addEventListener("dragend", @on_dragend)

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
        _dragTarget.setSpace(@element.clientWidth)
        clearTimeout(@removeTimer || null)
        clearTimeout(_isDragTimer)
        _dragTargetManager.add(@id, _dragTarget)
        pos = get_page_xy(@element)
        _dragTarget.setOrigin(pos.x, pos.y)
        _lastHover = null
        # app_list.setInsertAnchor(@element.nextSibling)
        if el = @element.nextSibling
            el.style.marginLeft = "#{_dragTarget.getSpace()}px"
        else if el = @element.previousSibling
            el.style.marginRight = "#{_dragTarget.getSpace()}px"
        console.warn("on_dragstart #{_dragTarget.getSpace()}")

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

    move:(e, threshold)=>
        x = e.offsetX
        if _lastHover and _lastHover.id != @id
            _lastHover.reset()
        _lastHover = @

        @reset()

        id = e.dataTransfer.getData(DEEPIN_ITEM_ID)
        _dragTarget = _dragTargetManager.getHandle(id)
        space = 0
        if _dragTarget
            space = _dragTarget.getSpace() || ITEM_DEFAULT_WIDTH
        else
            switch settings.displayMode()
                when DisplayMode.Fashion
                    space = ITEM_DEFAULT_WIDTH
                when DisplayMode.Efficient
                    space = ITEM_DEFAULT_WIDTH
                when DisplayMode.Classic
                    space = ITEM_DEFAULT_WIDTH

        if x < threshold
            if t = @element.nextSibling
                t.style.marginLeft = ''
                t.style.marginRight = ''
            if @element.style.marginLeft != "#{space}px"
                @element.style.marginLeft = "#{space}px"
                @element.style.marginRight = ''
                # app_list.setInsertAnchor(@element)
        else
            if t = @element.nextSibling
                if t.style.marginLeft != "#{space}px"
                    t.style.marginLeft = "#{space}px"
                    t.style.marginRight = ''
            else if @element.style.marginRight != "#{space}px"
                @element.style.marginLeft = ''
                @element.style.marginRight = "#{space}px"
            # app_list.setInsertAnchor(t)

        if not _isDragging
            updatePanel()
            _isDragging = true

        _isItemExpanded = true
        setTimeout(->
            systemTray?.updateTrayIcon()
        , 100)

    reset:->
        setTimeout(->
            systemTray?.updateTrayIcon()
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
            @move(e, @element.clientWidth / 2)
        # else
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
            @move(e, @element.clientWidth / 2)

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
