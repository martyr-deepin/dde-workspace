itemDBus = (path)->
    name: "com.deepin.daemon.Dock"
    path: path
    interface: "dde.dock.EntryProxyer"

$DBus = {}

createItem = (d)->
    icon = d.Data[ITEM_DATA_FIELD.icon] || NOT_FOUND_ICON
    if !(icon.indexOf("data:") != -1 or icon[0] == '/' or icon.indexOf("file://") != -1)
        icon = DCore.get_theme_icon(icon, 48)

    title = d.Data[ITEM_DATA_FIELD.title] || "Unknow"

    if d.Type == ITEM_TYPE.app
        container = app_list.element

        $DBus[d.Id] = d
        console.log("AppItem #{d.Id}")
        new AppItem(d.Id, icon, title, container)
    else
        console.log("SystemItem #{d.Id}, #{icon}, #{title}")
        $DBus[d.Id] = d
        new SystemItem(d.Id, icon, title)


deleteItem = (id)->
    delete $DBus[id]
    # id = path.substr(path.lastIndexOf('/') + 1)
    i = Widget.look_up(id)
    if i
        i.destroy()
    else
        # console.log("#{id} not eixst")
