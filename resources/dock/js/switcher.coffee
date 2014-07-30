changeThemeCss = (theme)->
    css = document.getElementsByTagName("link")[1]
    css.setAttribute("href", "css/#{theme}/dock.css")
    _b.style.display = 'none'
    setTimeout(->
        _b.style.display = ''
    , 10)


switchToClassicMode = ->
    changeThemeCss("classic")

    $("#panel").classList.remove("fixed_center")
    $("#containerWarp").classList.remove("fixed_center")
    $("#post_fixed").style.display = 'none'

    if tray = $("#trayarea")
        tray.style.display = ''
        tray.appendChild($("#system"))
        return

    tray = create_element(tag:'div', id:"trayarea")
    tray.appendChild($("#system"))
    _b.appendChild(tray)

    update_dock() if panel

switchToModernMode = ->
    changeThemeCss("modern")

    $("#panel").classList.add("fixed_center")
    $("#containerWarp").classList.add("fixed_center")

    $("#container").insertBefore($("#system"), $("#post_fixed"))
    $("#trayarea")?.style.display = 'none'
    $("#post_fixed").style.display = ''

    update_dock() if panel

update_dock=->
    setTimeout(->
        update_dock_region(Panel.getPanelMiddleWidth())
        panel.set_width(Panel.getPanelMiddleWidth())
        panel.redraw()
        console.warn("update region and panel")
    , 2000)
