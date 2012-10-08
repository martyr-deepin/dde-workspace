
create_item = (info) ->
    w = null
    switch info.Type
        when "Application"
            w = new DesktopEntry info.Name, info.Icon, info.Exec, info.EntryPath
        when "File"
            w = new NormalFile info.Name, info.Icon, info.Exec, info.EntryPath
        when "Dir"
            w = new Folder info.Name, info.Icon, info.exec, info.EntryPath
        else
            echo "don't support type"

    div_grid.appendChild(w.element)
    return w


Desktop.Core.install_monitor()

load_desktop_entries = ->
    for info in Desktop.Core.get_desktop_items()
        w = create_item(info)
        if w?
            move_to_anywhere(w)

    Desktop.Core.item_connect("update", do_item_update)
    Desktop.Core.item_connect("delete", do_item_delete)
    Desktop.Core.item_connect("rename", do_item_rename)

do_item_delete = (id) ->
    w = Widget.look_up(id)
    if w?
        w.destroy()

do_item_update = (info) ->
    w = create_item(info)
    if w?
        move_to_anywhere(w)

do_item_rename = (id, info) ->
    w = Widget.look_up(id)
    pos = load_position(w)
    w.destroy()

    w = create_item(info)
    if w?
        move_to_anywhere(w)
