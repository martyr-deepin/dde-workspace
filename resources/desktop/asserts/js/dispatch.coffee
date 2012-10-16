create_item = (info) ->
    w = null
    echo info
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

load_desktop_all_items = ->
    for info in DCore.Desktop.get_desktop_items()
        w = create_item(info)
        if w?
            move_to_anywhere(w)
