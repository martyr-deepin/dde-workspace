DCore.signal_connect("in_mini_mode", ->)
DCore.signal_connect("in_normal_mode", ->)
DCore.signal_connect("close_window", (info)->)
DCore.signal_connect("active_window", (info)->)
DCore.signal_connect("message_notify", (info)->)

DCore.signal_connect("embed_window_configure_changed", (info)->console.log(info))
DCore.signal_connect("embed_window_destroyed", (info)->console.log(info))
DCore.signal_connect("embed_window_enter", (info)->console.log(info))
DCore.signal_connect("embed_window_leave", (info)->console.log(info))

document.body.addEventListener("contextmenu", (e)->
    e.preventDefault()
)
document.body.addEventListener("drop", (e)->
    console.log("drop on body")
    update_dock_region()
    if e.y > screen.height - DOCK_HEIGHT - ITEM_HEIGHT
        return
    s_id = e.dataTransfer.getData(DEEPIN_ITEM_ID)
    s_widget = Widget.look_up(s_id)
    if s_widget and s_widget.isNormal()
        t = app_list.element.removeChild(s_widget.element)
        calc_app_item_size()

        t.style.position = "fixed"
        document.body.appendChild(t)
        t.style.left = (e.x - s_widget.element.clientWidth/2)+ "px"
        t.style.top = (e.y - s_widget.element.clientHeight/2)+ "px"
        s_widget.destroyWidthAnimation()
)
document.body.addEventListener("dragenter", (e)->
    clearTimeout(cancelInsertTimer)
    # app_list.hide_indicator()
    _lastHover?.reset()
)
document.body.addEventListener("dragover", (e)->
    clearTimeout(cancelInsertTimer)
    app_list.hide_indicator()
    s_id = e.dataTransfer.getData(DEEPIN_ITEM_ID)
    console.log("dragover ##{s_id}# on body")
    t = Widget.look_up(s_id)
    if not t
        return

    if t.isNormal()
        e.preventDefault()

    console.log("set cursor")
    if e.y > screen.height - DOCK_HEIGHT - ITEM_HEIGHT
        console.log("set to auto")
        e.dataTransfer.dropEffect = 'none'
    else
        console.log("set to cancel pointer")
        e.dataTransfer.dropEffect = 'move'
)

settings = new Setting()

show_desktop = new ShowDesktop()

panel = new Panel("panel")
panel.draw()

app_list = new AppList("app_list")

$DBus = {}

EntryManager =
    name:"com.deepin.daemon.Dock"
    path:"/dde/dock/EntryManager"
    interface:"dde.dock.EntryManager"

trayIcon = DCore.get_theme_icon("deepin-systray", 48) || NOT_FOUND_ICON
systemTray = null
entryManager = null
show_launcher = null
show_desktop = null

initDock = ->
    entryManager = get_dbus('session', EntryManager, "Entries")
    entries = entryManager.Entries

    trash = null

    for path in entries
        console.log(path)
        d = DCore.DBus.session_object("com.deepin.daemon.Dock", path, "dde.dock.EntryProxyer")
        console.log("init add: #{d.Id}")
        if d.Id == TRASH_ID
            trash = new Trash(TRASH_ID, Trash.get_icon(DCore.DEntry.get_trash_count()), _("Trash"))
            trash.core = d
            trash.is_opened = true
            xids = JSON.parse(d.Data[ITEM_DATA_FIELD.xids])
            console.log(xids[0])
            trash.w_id = xids[0].Xid
            trash.show_indicator()
        else if !Widget.look_up(d.Id)
            createItem(d)

    initDockedAppPosition()

    entryManager.connect("TrayInited",->
        if not systemTray and not $("#system-tray")
            systemTray = new SystemTray("system-tray", trayIcon, "")
    )

    entryManager.connect("Added", (path)->
        console.log("entry manager Added signal is emited: #{path}")
        d = DCore.DBus.session_object("com.deepin.daemon.Dock", path, "dde.dock.EntryProxyer")
        console.log("try to Add #{d.Id}")
        if d.Id == TRASH_ID
            trash.is_opened = true
            trash.core = d
            xids = JSON.parse(d.Data[ITEM_DATA_FIELD.xids])
            console.log(xids[0])
            trash.w_id = xids[0].Xid
            trash.show_indicator()
            return

        if Widget.look_up(d.Id)
            return

        console.log("Added #{path}")
        createItem(d)
        # console.log("added done")
        calc_app_item_size()
        if systemTray?.isShowing
            systemTray.updateTrayIcon()

        initDockedAppPosition()
        setTimeout(->
            calc_app_item_size()
            if systemTray?.isShowing
                systemTray.updateTrayIcon()
        , 100)
    )

    entryManager.connect("Removed", (id)->
        console.log("entry manager Removed signal is emited: #{id}")
        if id == TRASH_ID
            t = Widget.look_up(id)
            t.core = null
            t.hide_indicator()
            return
        deleteItem(id)
        calc_app_item_size()
        systemTray?.updateTrayIcon()
    )

    try
        icon_launcher = DCore.get_theme_icon("start-here", 48)

    show_launcher = new LauncherItem("show_launcher", icon_launcher, _("Launcher"))
    if not trash
        trash = new Trash(TRASH_ID, Trash.get_icon(DCore.DEntry.get_trash_count()), _("Trash"))
    show_desktop = new ShowDesktop()

    DCore.Dock.emit_webview_ok()
    DCore.Dock.test()

    setTimeout(->
        IN_INIT = false
        try
            if not systemTray and not $("#system-tray")
                systemTray = new SystemTray("system-tray", trayIcon, "")
        catch
            systemTray?.destroy()
            systemTray = null

        new Time("time", "js/plugins/time/img/time.png", "")
        calc_app_item_size()
        # apps are moved up, so add 8
        DCore.Dock.change_workarea_height(ITEM_HEIGHT * ICON_SCALE + 8)
    , 100)

    setTimeout(->
        $("#containerWarp").style.bottom = "5px"
        $("#panel").style.bottom = "0px"
    , 1000)

setTimeout(initDock , 1000)
