changeThemeCss = (theme)->
    css = document.getElementsByTagName("link")[1]
    css.setAttribute("href", "css/#{theme}/dock.css")
    _b.style.display = 'none'
    setTimeout(->
        _b.style.display = ''
    , 10)


switchToClassicMode = ->
    changeThemeCss("classic")
    $("#trayarea").appendChild($("#system"))
    update_dock() if panel
    systemTray?.showAllIcons()
    for own k, v of $DBus
        item = Widget.look_up(k)
        if item and item.isApp?() and item.isActive?()
            item.openIndicator.src = CLASSIC_ACTIVE_IMG
            item.hoverIndicator.src = CLASSIC_ACTIVE_HOVER_IMG

switchToModernMode = ->
    changeThemeCss("modern")
    $("#container").insertBefore($("#system"), $("#post_fixed"))
    update_dock() if panel
    if systemTray
        systemTray.hideAllIcons()
        systemTray.hideButton()
        systemTray.fold()
    for own k, v of $DBus
        item = Widget.look_up(k)
        if item and item.isApp?() and item.isActive?()
            item.openIndicator.src = OPEN_INDICATOR
            item.hoverIndicator.src = OPEN_INDICATOR

update_dock=->
    console.log("panel #{Panel.getPanelMiddleWidth()}")

    panel.set_height(PANEL_HEIGHT)
    panel.set_width(Panel.getPanelMiddleWidth())
    update_dock_region(Panel.getPanelMiddleWidth())

    panel.redraw()
    setTimeout(->
        systemTray?.updateTrayIcon()
    , 1000)

    for own k, v of $DBus
        item = Widget.look_up(k)
        if item and item.isApp?() and item.isActive?()
            item.show_open_indicator()

    console.warn("update region and panel")
