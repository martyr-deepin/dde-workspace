show_desktop = new ShowDesktop()

panel = new Panel("panel")
panel.draw()

app_list = new AppList("app_list")
apps = {}

EntryManager = "dde.dock.EntryManager"
entryManager = get_dbus('session', EntryManager)

entryManager.connect("Added", (path)->
    console.log('added', path)
    d = get_dbus("session", itemDBus(path))
    if d.Status == 0
        console.log("Activator", d.Id)
        apps[entry] = new Activator(entry, d, app_list)
    else
        console.log("ClientGroup", d.Id)
        apps[entry] = new ClientGroup(entry, d, app_list)
)
entryManager.connect("Removed", (id)->
    console.log('added', id)
)

entries = entryManager.Entries
for entry in entries
    # console.log(entry)
    # console.log(itemDBus(entry))
    d = get_dbus("session", itemDBus(entry))
    if d.Status == 2
        console.log("Activator", d.Id)
        apps[entry] = new Activator(entry, d, app_list)
    else
        console.log("ClientGroup", d.Id)
        apps[entry] = new ClientGroup(entry, d, app_list)
    # console.log('created end')
    # console.log(d.Status)

setTimeout(->
    IN_INIT = false
    calc_app_item_size()
    # apps are moved up, so add 8
    DCore.Dock.change_workarea_height(ITEM_HEIGHT * ICON_SCALE + 8)
, 100)

try
    icon_launcher = DCore.get_theme_icon("start-here", 48)

show_launcher = new LauncherItem("show_launcher", icon_launcher, _("Launcher"))
# clock = create_clock(DCore.Dock.clock_type())
trash = new Trash("trash", Trash.get_icon(DCore.DEntry.get_trash_count()), _("Trash"))
show_desktop = new ShowDesktop()

DCore.Dock.emit_webview_ok()
DCore.Dock.test()

