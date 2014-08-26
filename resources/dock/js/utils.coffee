itemDBus = (path)->
    name: "com.deepin.daemon.Dock"
    path: path
    interface: "dde.dock.EntryProxyer"


moveHoverInfo = do->
    moveHoverInfoTimer = null
    ->
        clearTime(moveHoverInfoTimer)
        moveHoverInfoTimer = setTimeout(_moveHoverInfo, 300)

_moveHoverInfo = ->
    el = document.elementFromPoint($mousePosition.x, $mousePosition.y)

    if el
        console.log("#{el.tagName}##{el.id||""}")
        if el.tagName != "IMG"
            itemEl = null
     else
         console.log("[_moveHoverInfo] get element failed")
         return

    try
        itemEl = el.parentNode.parentNode.parentNode
    catch
        console.log("[_moveHoverInfo] the mouse hoverd is not item")
        itemEl = null

    if itemEl == null
        console.log("[_moveHoverInfo] get item element failed")
        DCore.Dock.set_is_hovered(false)
        $tooltip?.hide()
        Preview_close()
        systemTray?.updateTrayIcon()
        return

    console.log("[_moveHoverInfo] element id: #{itemEl.id}")
    item = Widget.look_up(itemEl.id)

    if not item
        console.log("[_moveHoverInfo] get item failed")
        DCore.Dock.set_is_hovered(false)
        $tooltip?.hide()
        Preview_close()
        systemTray?.updateTrayIcon()
        return

    console.log("[_moveHoverInfo] item id: #{item.id}, #{item.isRuntimeApplet()}")
    if item.isNormal() or item.isNormalApplet()
        Preview_close_now()
        console.log("this item should show tooltip")
        item.tooltip?.on_mouseover()
        # $tooltip?.show()
    else
        $tooltip?.hide()
        currentPreview = Preview_container._current_group
        if Preview_container.is_showing && item.id == currentPreview.id && not currentPreview.isRuntimeApplet()
            Preview_container._calc_size()
        else
            Preview_container._current_group = null
            item?.on_mouseover()


createItem = (d)->
    icon = d.Data[ITEM_DATA_FIELD.icon] || NOT_FOUND_ICON
    if !(icon.indexOf("data:") != -1 or icon[0] == '/' or icon.indexOf("file://") != -1)
        icon = DCore.get_theme_icon(icon, 48)

    title = d.Data[ITEM_DATA_FIELD.title] || "Unknow"

    $DBus[d.Id] = d
    if d.Type == ITEM_TYPE.app
        container = app_list.element

        console.log("AppItem #{d.Id}")
        item = new AppItem(d.Id, icon, title, container)
    else if d.Id == TIME_ID
        console.log("AppletDateTime")
        time.core = new EntryProxy(d)
        time.init_clientgroup()
        time.core.showQuickWindow()
    else
        console.log("SystemItem #{d.Id}, #{icon}, #{title}")
        item = new SystemItem(d.Id, icon, title)

    updateMaxClientListWidth()

    if activeWindow and activeWindow.active_window and activeWindow.itemId == null
        activeWindow.itemId = item.id
        if item.isApp() and item.isActive()
            item.show_open_indicator()

    if DCore.Dock.is_hovered()
        console.warn("[create item] dock is hoverd")
        moveHoverInfo()


deleteItem = (id)->
    # console.log("delete item #{id}")
    delete $DBus[id]
    # id = path.substr(path.lastIndexOf('/') + 1)
    i = Widget.look_up(id)
    if i
        i.destroy()
    # else
        # console.log("#{id} not eixst")

    updateMaxClientListWidth()

    if DCore.Dock.is_hovered()
        console.warn("delete item, is hovered")
        moveHoverInfo()


iconCanvas = create_element(tag:'canvas', document.body)
iconCanvas.width = iconCanvas.height = 48
iconCanvas.style.position = 'absolute'
iconCanvas.style.top = -screen.height

bright_image = (img, adjustment)->
    ctx = iconCanvas.getContext("2d")
    # clear the last icon.
    ctx.clearRect(0, 0, iconCanvas.width, iconCanvas.height)
    ctx.drawImage(img, 0, 0, iconCanvas.width, iconCanvas.height)
    origDataUrl = iconCanvas.toDataURL()
    dataUrl = DCore.Dock.bright_image(origDataUrl, adjustment)
    # i = new Image()
    # i.src = dataUrl
    # i.onload = ->
    #     ctx.drawImage(i, 0, 0)
    return dataUrl

dark_image = (img, adjustment)->
    ctx = iconCanvas.getContext("2d")
    # clear the last icon.
    ctx.clearRect(0, 0, iconCanvas.width, iconCanvas.height)
    ctx.drawImage(img, 0, 0, iconCanvas.width, iconCanvas.height)
    origDataUrl = iconCanvas.toDataURL()
    dataUrl = DCore.Dock.dark_image(origDataUrl, adjustment)
    # i = new Image()
    # i.src = dataUrl
    # i.onload = ->
    #     ctx.drawImage(i, 0, 0)
    return dataUrl

updatePanel = do ->
    _updatePanelTimer = null
    ->
        _isDragging = false
        clearTimeout(_updatePanelTimer)
        panel.cancelAnimation()
        panel.updateWithAnimation()
        _updatePanelTimer = setTimeout(->
            panel.cancelAnimation()
            _updatePanelTimer = null
        , 300)


getSiblingFromPoint = (x, y, sentinel, step, stepHandler)->
    el = null
    while 1
        x = stepHandler(x, step)
        el = document.elementFromPoint(x, y)
        console.log("#{x}, #{y}")
        console.log(el)
        if not el
            console.log("failed")
            return null if not el
        if el.classList?.contains("AppItemImg")
            id = el.parentNode.parentNode.parentNode.id
            console.log(id)
            if id == sentinel
                console.log("get self")
                return null
            return el
        else if el.tagName == "BODY"
            console.log("FOUND BODY")
            return null

getPreviousSiblingFromPoint = (x, y, sentinel, step=6)->
    getSiblingFromPoint(x, y, sentinel, step, (x, step)->x - step)

getNextSiblingFromPoint = (x, y, sentinel, step=6)->
    getSiblingFromPoint(x, y, sentinel, step, (x, step)->x + step)


handleMenuUnregister = ->
    _isRightclicked = false
    hideStatusManager?.updateState()

resetAllItems = ->
    if not _isItemExpanded
        return

    clearRegion()
    _isItemExpanded = false
    for k, v of $DBus
        Widget.look_up(k)?.reset()

    updatePanel()

drawLine = (ctx, x0, y0, x1, y1, opt)->
    ctx.beginPath()
    ctx.moveTo(x0, y0)
    ctx.lineTo(x1, y1)

    ctx.lineWidth = opt.lineWidth if opt.lineWidth?
    ctx.strokeStyle = opt.lineColor if opt.lineColor?

    ctx.stroke()


updateMaxClientListWidth = ->
    if settings.displayMode() == DisplayMode.Classic
        trayWidth = 0
        if systemTray and systemTray.items
            trayWidth = (TRAY_ICON_WIDTH + TRAY_ICON_MARGIN * 2) * systemTray.items.length
            console.warn(TRAY_ICON_WIDTH + TRAY_ICON_MARGIN * 2)
            console.warn(systemTray.items.length)
        console.warn("trayWidth: #{trayWidth}, applet:#{$("#trayarea").clientWidth}")
        width = screen.width - $("#trayarea").clientWidth - 32 - trayWidth
        $("#app_list").style.width = width - $("#pre_fixed").clientWidth
    else
        $("#app_list").style.width = ''
