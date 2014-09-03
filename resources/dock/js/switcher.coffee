changeThemeCss = (theme)->
    _b.style.display = 'none'
    css = $("#theme")
    css.setAttribute("href", "css/#{theme}/dock.css")
    _b.offsetWidth
    _b.style.display = ''


switchToEfficientMode = ->
    changeThemeCss("efficient")
    $("#trayarea").appendChild($("#system"))
    update_dock() if panel
    systemTray?.showAllIcons()
    for own k, v of $DBus
        item = Widget.look_up(k)
        if item and item.isApp?()
            # console.log("#{item.id} switch to classic mode")
            item.openIndicator.src = EFFICIENT_ACTIVE_IMG
            item.hoverIndicator.src = EFFICIENT_ACTIVE_HOVER_IMG
            item.imgContainer.draggable = false
    DCore.Dock.fix_switch()


switchToClassicMode = ->
    changeThemeCss("classic")
    $("#trayarea").appendChild($("#system"))
    update_dock() if panel
    systemTray?.showAllIcons()
    for own k, v of $DBus
        item = Widget.look_up(k)
        if item and item.isApp?()
            # console.log("#{item.id} switch to classic mode")
            item.openIndicator.src = CLASSIC_ACTIVE_IMG
            item.hoverIndicator.src = CLASSIC_ACTIVE_HOVER_IMG
            item.imgContainer.draggable = false
    DCore.Dock.fix_switch()

switchToFashionMode = ->
    changeThemeCss("fashion")
    $("#container").insertBefore($("#system"), $("#post_fixed"))
    update_dock() if panel
    if systemTray
        systemTray.hideAllIcons()
        systemTray.hideButton()
        systemTray.fold()
    for own k, v of $DBus
        item = Widget.look_up(k)
        if item and item.isApp?()
            # console.log("#{item.id} switch to fashion mode")
            item.openIndicator.src = OPEN_INDICATOR
            item.hoverIndicator.src = OPEN_INDICATOR
            item.imgContainer.draggable = true
    DCore.Dock.fix_switch()

update_dock=->
    console.log("[update_dock] panel #{Panel.getPanelMiddleWidth()}")

    panel.set_height(PANEL_HEIGHT)
    setTimeout(->
        panel.set_width(Panel.getPanelMiddleWidth())
        if debugRegion
            console.log("[update_dock] update_dock_region")
        update_dock_region(Panel.getPanelMiddleWidth())

        panel.redraw()
    , 50)
    setTimeout(->
        updateMaxClientListWidth()
    , 100)
    setTimeout(->
        systemTray?.updateTrayIcon()
    , 1000)

    for own k, v of $DBus
        item = Widget.look_up(k)
        if item and item.isApp?() and item.isActive?()
            item.show_open_indicator()
