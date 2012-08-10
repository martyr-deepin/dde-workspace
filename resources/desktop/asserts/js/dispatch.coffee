
create_item = (info, pos) ->
    w = null
    switch info.type
        when "Entry" then w = new DesktopEntry info.name, info.icon, info.exec, info.path
        when "File" then w = new NormalFile info.name, info.icon, info.exec, info.path
        when "Dir" then w = new Folder info.name, info.icon, info.exec, info.path
        else echo "don't support type"
    if pos?
        move_to_position(w, pos)


Desktop.Core.install_monitor()

load_desktop_entries = ->
    grid = document.querySelector("#grid")
    grid.width = document.body.scrollWidth
    grid.height = document.body.scrollHeight
    create_item(info) for info in Desktop.Core.get_desktop_items()
    Desktop.Core.item_connect("update", do_item_update)
    Desktop.Core.item_connect("delete", do_item_delete)
    Desktop.Core.item_connect("rename", do_item_rename)

do_item_delete = (id) ->
    w = Widget.look_up(id)
    w.destroy()

do_item_update = (info) ->
    create_item(info)

do_item_rename = (id, info) ->
    w = Widget.look_up(id)
    pos = load_position(w)
    w.destroy()

    create_item(info, pos)
