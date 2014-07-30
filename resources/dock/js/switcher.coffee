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

switchToModernMode = ->
    changeThemeCss("modern")
    $("#container").insertBefore($("#system"), $("#post_fixed"))
    update_dock() if panel

update_dock=->
    setTimeout(->
        console.warn("panel #{Panel.getPanelMiddleWidth()}")

        panel.set_width(Panel.getPanelMiddleWidth())
        update_dock_region(Panel.getPanelMiddleWidth())

        panel.redraw()
        systemTray?.updateTrayIcon()

        console.warn("update region and panel")
    , 2000)
