changeThemeCss = (theme)->
    css = document.getElementsByTagName("link")[1]
    css.setAttribute("href", "css/#{theme}/dock.css")
    _b.style.display = 'none'
    run_post(->
        _b.style.display = ''
    )


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
    tray.style.position = 'fixed'
    tray.style.bottom = '1px'
    tray.style.right = '32px'
    tray.style.height = '46px'
    tray.appendChild($("#system"))
    _b.appendChild(tray)

switchToModernMode = ->
    changeThemeCss("modern")

    $("#panel").classList.add("fixed_center")
    $("#containerWarp").classList.add("fixed_center")

    $("#eontainerWarp").appendChild($("#system"))
    $("#trayarea")?.style.display = 'none'
    $("#post_fixed").style.display = ''
