show = false
document.getElementById("icon_default").addEventListener('click', (e) ->
    show = !show
    DCore.Dock.show_desktop(show)
)

