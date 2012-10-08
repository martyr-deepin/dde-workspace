connect_default_signals = ->
    Desktop.Core.signal_connect("item_update", do_item_update)
    Desktop.Core.signal_connect("item_delete", do_item_delete)
    Desktop.Core.signal_connect("item_rename", do_item_rename)

    Desktop.Core.signal_connect("workarea_changed", do_workarea_changed)
    Desktop.Core.notify_workarea_size()

do_item_delete = (id) ->
    w = Widget.look_up(id)
    w.destroy()

do_item_update = (info) ->
    create_item(info)

do_item_rename = (data) ->
    w = Widget.look_up(data.old_id)
    pos = load_position(w)
    w.destroy()

    create_item(data.info, pos)

do_workarea_changed = (allo) ->
    echo allo
