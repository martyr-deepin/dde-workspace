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
        if status == ITEM_STATUS.normal
            console.log("Activator #{d.Id}")
            $DBus[entry] = d
            new Activator(entry, icon, title, container)
        else if status == ITEM_STATUS.active
            console.log("ClientGroup #{d.Id}")
            id = "cl_#{entry}"
            $DBus[id] = d
            new ClientGroup(id, icon, title, container)
    else
        console.log("SystemItem #{d.Id}, #{icon}, #{title}")
        $DBus[d.Id] = d
        new SystemItem(d.Id, icon, title)
