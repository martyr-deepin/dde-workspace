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

switchToModernMode = ->
    changeThemeCss("modern")
    $("#container").insertBefore($("#system"), $("#post_fixed"))
    update_dock() if panel
    if systemTray
        systemTray.hideAllIcons()
        systemTray.hideButton()
        systemTray.fold()

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
            item.hide_open_indicator()
            item.show_open_indicator()

    console.warn("update region and panel")
