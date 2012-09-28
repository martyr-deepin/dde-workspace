
create_item = (info, pos) ->
    w = null
    switch info.Type
        when "Application" then w = new DesktopEntry info.Name, info.Icon, info.Exec, info.EntryPath
        when "File" then w = new NormalFile info.Name, info.Icon, info.Exec, info.EntryPath
        when "Dir" then w = new Folder info.Name, info.Icon, info.exec, info.Entrypath
        else echo "don't support type"
    if pos?
        move_to_position(w, pos)


#Desktop.Core.install_monitor()
#TODO: adjust this change

load_desktop_entries = ->
    create_item(info) for info in Desktop.Core.get_desktop_items()
    Desktop.Core.signal_connect("update", do_item_update)
    Desktop.Core.signal_connect("delete", do_item_delete)
    Desktop.Core.signal_connect("rename", do_item_rename)

do_item_delete = (id) ->
    echo "signal delete emit......"
    w = Widget.look_up(id)
    w.destroy()

do_item_update = (info) ->
    create_item(info)

do_item_rename = (id, info) ->
    w = Widget.look_up(id)
    pos = load_position(w)
    w.destroy()

    create_item(info, pos)

