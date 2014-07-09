dockedAppManager
try
    dockedAppManager = get_dbus(
        "session",
        name:"com.deepin.daemon.Dock",
        path:"/dde/dock/DockedAppManager",
        interface:"dde.dock.DockedAppManager",
        "DockedAppList"
    )
catch e
    console.log e

dockedAppManager?.connect("Docked", (id)->
    console.log("Docked #{id}")
    items = []
    appList = $("#app_list")
    for i in [0...appList.children.length]
        child = appList.children[i]
        name = child.getAttribute('name')
        if name
            console.log(name)
            items.push(name)
        else
            items.push(child.id)

    if not $DBus[id] and items.indexOf(id) == -1
        # append to the last.
        # dock-apps-builder will listen Docked signal, and emit Added signal if
        # necessary.
        console.log("Send to Dock")
        items.push(id)

    console.log("docked items: #{items}")
    dockedAppManager.Sort(items)
)
dockedAppManager?.connect("Undocked", (id)->
    console.log("Undocked #{id}")
    item = Widget.look_up(id)
    if item and !item.isActive()
        item.destroy()
        delete $DBus[id]
    # $("#app_list").removeChild($("##{id}"))
    calc_app_item_size()
)

initDockedAppPosition = ->
    if !dockedAppManager
        return
    dockedPosition = dockedAppManager.DockedAppList_sync()
    list = $("#app_list")
    for i in [dockedPosition.length-1..0]
        target = $("##{dockedPosition[i]}")
        if target
            list.insertBefore(target, list.firstElementChild)


sortDockedItem = ->
    items = []
    ch = app_list.element.children
    for i in [0...ch.length]
        child = ch[i]
        items.push(child.id)
    console.log(items)
    dockedAppManager?.Sort(items)
