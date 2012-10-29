show = false
document.getElementById("icon_desktop").addEventListener('click', (e) ->
    show = !show
    DCore.Dock.show_desktop(show)
)
document.getElementById("icon_launcher").addEventListener('click', (e) ->
    DCore.run_command("/home/snyh/deepin-desktop-env/build/launcher")
)

