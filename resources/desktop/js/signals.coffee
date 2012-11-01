connect_default_signals = ->
    DCore.signal_connect("item_update", do_item_update)
    DCore.signal_connect("item_delete", do_item_delete)
    DCore.signal_connect("item_rename", do_item_rename)

    DCore.signal_connect("workarea_changed", do_workarea_changed)
    DCore.Desktop.notify_workarea_size()

do_item_delete = (id) ->
    w = Widget.look_up(id)?.destroy()

do_item_update = (info) ->
    echo info
    Widget.look_up(info.EntryPath)?.destroy()
    w = create_item(info)
    if w?
        move_to_anywhere(w)

do_item_rename = (data) ->
    w = Widget.look_up(data.old_id)?.destroy()

    update_position(data.old_id, data.info.EntryPath)

    w = create_item(data.info)
    if w?
        move_to_anywhere(w)

do_workarea_changed = (allo) ->
    update_gird_position(allo.x + 4, allo.y + 4, allo.width - 8, allo.height - 8)
