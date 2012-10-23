do_tray_icon_add = (id) ->
    echo id
    DCore.Dock.set_tray_icon_position(id.id, 30, 0)


DCore.signal_connect('tray_icon_add', do_tray_icon_add)

