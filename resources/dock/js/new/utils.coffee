ENTRY_MANAGER_NAME = "dde.dock.EntryManager"

itemDBus = (path)->
    name: ENTRY_MANAGER_NAME
    path: path
    interface: "dde.dock.EntryProxyer"

$DBus = {}

createItem = (path)->
    d = get_dbus("session", itemDBus(path))
    icon = d.Data[ITEM_DATA_FIELD.icon] || NOT_FOUND_ICON
    if !(icon.indexOf("data:") != -1 or icon[0] == '/' or icon.indexOf("file://") != -1)
        icon = DCore.get_theme_icon(icon, 48)

    title = d.Data[ITEM_DATA_FIELD.title] || "Unknow"

    if d.Type == ITEM_TYPE.app
        container = app_list.element

        status = d.Data[ITEM_DATA_FIELD.status]
        $DBus[d.Id] = d
        new AppItem(d.Id, icon, title, container)
        # if status == ITEM_STATUS.normal
        #     console.log("Activator #{d.Id}")
        #     $DBus[d.Id] = d
        #     new Activator(d.Id, icon, title, container)
        # else if status == ITEM_STATUS.active
        #     console.log("ClientGroup #{d.Id}")
        #     $DBus[d.Id] = d
        #     new ClientGroup(d.Id, icon, title, container)
    else
        console.log("SystemItem #{d.Id}, #{icon}, #{title}")
        $DBus[d.Id] = d
        new SystemItem(d.Id, icon, title)


deleteItem = (path)->
    delete $DBus[path]
    id = path.substr(path.lastIndexOf('/') + 1)
    i = Widget.look_up(id)
    if i
        i.destroy()
    else
        console.log("#{id} not eixst")
