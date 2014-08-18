changeThemeCss = (theme)->
    css = document.getElementsByTagName("link")[1]
    if not css?
        css = create_element(
            tag:"link",
            rel:"stylesheet",
            document.getElementsByTagName("head")[0]
        )
    css.setAttribute("href", "css/#{theme}/dock.css")
    _b.style.display = 'none'
    setTimeout(->
        _b.style.display = ''
    , 10)


switchToEfficientMode = ->
    changeThemeCss("efficient")
    $("#trayarea").appendChild($("#system"))
    update_dock() if panel
    systemTray?.showAllIcons()
    updateMaxClientListWidth()
    for own k, v of $DBus
        item = Widget.look_up(k)
        if item and item.isApp?()
            # console.log("#{item.id} switch to classic mode")
            item.openIndicator.src = EFFICIENT_ACTIVE_IMG
            item.hoverIndicator.src = EFFICIENT_ACTIVE_HOVER_IMG


switchToClassicMode = ->
    changeThemeCss("classic")
    $("#trayarea").appendChild($("#system"))
    update_dock() if panel
    systemTray?.showAllIcons()
    updateMaxClientListWidth()
    for own k, v of $DBus
        item = Widget.look_up(k)
        if item and item.isApp?()
            # console.log("#{item.id} switch to classic mode")
            item.openIndicator.src = CLASSIC_ACTIVE_IMG
            item.hoverIndicator.src = CLASSIC_ACTIVE_HOVER_IMG

switchToFashionMode = ->
    changeThemeCss("fashion")
    $("#container").insertBefore($("#system"), $("#post_fixed"))
    update_dock() if panel
    updateMaxClientListWidth()
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

update_dock=->
    console.log("[update_dock] panel #{Panel.getPanelMiddleWidth()}")

    panel.set_height(PANEL_HEIGHT)
    panel.set_width(Panel.getPanelMiddleWidth())
    if debugRegion
        console.log("[update_dock] update_dock_region")
    update_dock_region(Panel.getPanelMiddleWidth())

    panel.redraw()
    setTimeout(->
        systemTray?.updateTrayIcon()
    , 1000)

    for own k, v of $DBus
        item = Widget.look_up(k)
        if item and item.isApp?() and item.isActive?()
            item.show_open_indicator()
