connect_default_signals = ->
    DCore.signal_connect("item_update", do_item_update)
    DCore.signal_connect("item_delete", do_item_delete)
    DCore.signal_connect("item_rename", do_item_rename)

    DCore.signal_connect("workarea_changed", do_workarea_changed)
    DCore.Desktop.notify_workarea_size()

do_item_delete = (id) ->
    w = Widget.look_up(id)
    if w?
        echo id
        w.destroy()

do_item_update = (info) ->
    w = create_item(info)
    if w?
        move_to_anywhere(w)

do_item_rename = (data) ->
    w = Widget.look_up(data.old_id)
    w.destroy()

    w = create_item(data.info)
    if w?
        move_to_anywhere(w)

do_workarea_changed = (allo) ->
    #echo "do_workarea_changed"
    update_gird_position(allo.x + 4, allo.y + 4, allo.width - 8, allo.height - 8)
