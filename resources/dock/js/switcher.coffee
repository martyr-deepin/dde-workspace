changeThemeCss = (theme)->
    _b.style.display = 'none'
    css = $("#theme")
    css.setAttribute("href", "css/#{theme}/dock.css")
    _b.offsetWidth
    _b.style.display = ''


switchToEfficientModeTimer = null
switchToClassicModeTimer = null


switchMode = (modeName, normalImg, hoverImg, op)->
    clearTimeout(switchToClassicModeTimer)
    clearTimeout(switchToEfficientModeTimer)
    changeThemeCss(modeName)
    update_dock() if panel
    for own k, v of $DBus
        item = Widget.look_up(k)
        if item and item.isApp?()
            item.openIndicator.src = normalImg
            item.hoverIndicator.src = hoverImg
        if item?.isApplet()
            item.change_icon(item.icon)
    DCore.Dock.fix_switch()
    op()


switchToFashionMode = ->
    switchMode("fashion", OPEN_INDICATOR, OPEN_INDICATOR, ->
        systemTray?.hideButton()
        systemTray?.fold()
    )


switchToEfficientMode = ->
    switchMode("efficient", EFFICIENT_ACTIVE_IMG, EFFICIENT_ACTIVE_HOVER_IMG, ->
        switchToEfficientModeTimer = setTimeout(->
            systemTray?.showAllIcons()
        , 800)
    )


switchToClassicMode = ->
    switchMode("classic", CLASSIC_ACTIVE_IMG, CLASSIC_ACTIVE_HOVER_IMG,->
        switchToClassicModeTimer = setTimeout(->
            systemTray?.showAllIcons()
        , 800)
    )


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
