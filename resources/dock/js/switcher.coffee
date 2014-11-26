changeThemeCss = (theme)->
    _b.style.display = 'none'
    css = $("#theme")
    css.setAttribute("href", "css/#{theme}/dock.css")
    _b.offsetWidth
    _b.style.display = ''


switchToEfficientMode = ->
    changeThemeCss("efficient")
    update_dock() if panel
    systemTray?.showAllIcons()
    for own k, v of $DBus
        item = Widget.look_up(k)
        if item and item.isApp?()
            # console.log("#{item.id} switch to classic mode")
            item.openIndicator.src = EFFICIENT_ACTIVE_IMG
            item.hoverIndicator.src = EFFICIENT_ACTIVE_HOVER_IMG
        if item?.isApplet()
            item.change_icon(item.icon)
    DCore.Dock.fix_switch()


switchToClassicMode = ->
    changeThemeCss("classic")
    update_dock() if panel
    systemTray?.showAllIcons()
    for own k, v of $DBus
        item = Widget.look_up(k)
        if item and item.isApp?()
            # console.log("#{item.id} switch to classic mode")
            item.openIndicator.src = CLASSIC_ACTIVE_IMG
            item.hoverIndicator.src = CLASSIC_ACTIVE_HOVER_IMG
        if item?.isApplet()
            item.change_icon(item.icon)
    DCore.Dock.fix_switch()

switchToFashionMode = ->
    changeThemeCss("fashion")
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
        if item?.isApplet()
            item.change_icon(item.icon)
    DCore.Dock.fix_switch()

update_dock=->
    console.log("[update_dock] panel #{Panel.getPanelMiddleWidth()}")

    app_list = $("#app_list")
    app_list.style.display = 'none'
    panel.set_height(PANEL_HEIGHT)
    setTimeout(->
        app_list.style.display = ''
        panel.set_width(Panel.getPanelMiddleWidth())
        if debugRegion
            console.log("[update_dock] update_dock_region")
        update_dock_region(Panel.getPanelMiddleWidth())

        panel.redraw()
    , 50)
    setTimeout(->
        systemTray?.updateTrayIcon()
    , 1000)

    for own k, v of $DBus
        item = Widget.look_up(k)
        if item and item.isApp?() and item.isActive?()
            item.show_open_indicator()
