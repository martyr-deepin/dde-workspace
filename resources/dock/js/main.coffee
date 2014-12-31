settings = new Setting()
settings.updateSize(settings.displayMode())
switch settings.displayMode()
    when DisplayMode.Fashion
        switchToFashionMode()
    when DisplayMode.Efficient
        switchToEfficientMode()
    when DisplayMode.Classic
        switchToClassicMode()

hideStatusManager = new HideStatusManager(settings.hideMode())

show_desktop = new ShowDesktop()

panel = new Panel("panel")
panel.draw()

app_list = new AppList("app_list")

EntryManager =
    name:"com.deepin.daemon.Dock"
    path:"/dde/dock/EntryManager"
    interface:"dde.dock.EntryManager"

trayIcon = "img/deepin-systray.png"
systemTray = null
time = null
entryManager = null
show_launcher = null
show_desktop = null
trash = null

initDock = ->
    panel.panel.style.webkitTransform = 'translateY(100%)'
    _CW.style.webkitTransform = "translateY(110%)"
    entryManager = get_dbus('session', EntryManager, "Entries")
    entries = entryManager.Entries

    for path in entries
        try
            d = DCore.DBus.session_object("com.deepin.daemon.Dock", path, "dde.dock.EntryProxyer")
        catch e
            console.log(e)
            continue
        if d.Id == TRASH_ID
            trash = new Trash(TRASH_ID, Trash.get_icon(DCore.DEntry.get_trash_count()), _("Trash"))
            trash.core = d
            trash.is_opened = true
            xids = JSON.parse(d.Data[ITEM_DATA_FIELD.xids])
            trash.w_id = xids[0].Xid
            trash.show_indicator()
        else if !Widget.look_up(d.Id)
            createItem(d)

    initDockedAppPosition()

    entryManager.connect("TrayInited",->
        if not systemTray and not $("#system-tray")
            systemTray = new SystemTray("system-tray", trayIcon, "")
        else if systemTray
            systemTray.clearItems()
            setTimeout(->
                systemTray.core.RetryManager_sync()
            , 1000)
    )

    entryManager.connect("Added", (path)->
        try
            d = DCore.DBus.session_object("com.deepin.daemon.Dock", path, "dde.dock.EntryProxyer")
        catch e
            console.log(e)
            return
        if d.Id == TRASH_ID
            trash.is_opened = true
            trash.core = d
            xids = JSON.parse(d.Data[ITEM_DATA_FIELD.xids])
            trash.w_id = xids[0].Xid
            trash.show_indicator()
            return

        if Widget.look_up(d.Id)
            return

        createItem(d)
        calc_app_item_size()
        if systemTray?.isShowing
            systemTray.updateTrayIcon()

        initDockedAppPosition()
        setTimeout(->
            calc_app_item_size()
            if debugRegion
                console.warn("[entryManager.Added] update_dock_region")
            update_dock_region($("#container").clientWidth)
            if systemTray?.isShowing
                systemTray.updateTrayIcon()
        , 100)
    )

    entryManager.connect("Removed", (id)->
        if id == TRASH_ID
            t = Widget.look_up(id)
            t.core = null
            t.hide_indicator()
            return
        deleteItem(id)
        calc_app_item_size()
        systemTray?.updateTrayIcon()
        if debugRegion
            console.warn("[entryManager.Removed] update_dock_region")
        update_dock_region($("#container").clientWidth)
    )

    try
        icon_launcher = DCore.get_theme_icon("deepin-launcher", 48)

    show_launcher = new LauncherItem("show_launcher", icon_launcher, _("Launcher"))
    if not trash
        trash = new Trash(TRASH_ID, Trash.get_icon(DCore.DEntry.get_trash_count()), _("Trash"))
    show_desktop = new ShowDesktop()

    DCore.Dock.emit_webview_ok()
    DCore.Dock.test()

    setTimeout(->
        try
            if not systemTray and not $("#system-tray")
                systemTray = new SystemTray("system-tray", trayIcon, "")
        catch
            systemTray?.destroy()
            systemTray = null

        DCore.Dock.change_workarea_height(DOCK_HEIGHT)
    , 100)

    if settings.hideMode() == HideMode.KeepHidden
        setTimeout(->
            IN_INIT = false
            READY_FOR_TRAY_ICONS = true
            calc_app_item_size()
            hideStatusManager.updateState()
            if debugRegion
                console.warn("[initDock] update_dock_region")
            update_dock_region($("#container").clientWidth, 0)
            systemTray?.hideAllIcons()
        , 1000)
        return

    setTimeout(->
        IN_INIT = false
        calc_app_item_size()
        _CW.style.webkitTransform = "translateY(0)"
        panel.panel.style.webkitTransform = "translateY(0)"
        hideStatusManager.updateState()
        if debugRegion
            console.warn("[initDock] update_dock_region")
        update_dock_region($("#container").clientWidth)
        setTimeout(->
            READY_FOR_TRAY_ICONS = true
            if settings.displayMode() != DisplayMode.Fashion and systemTray
                systemTray.isShowing = true
                systemTray.updateTrayIcon()
                # TODO:
                systemTray.showAllIcons()
        , SHOW_HIDE_ANIMATION_TIME)
    , 1000)
    if not activeWindow
        activeWindow= new ActiveWindow(clientManager.CurrentActiveWindow_sync())


time = new Time("time", "js/plugins/time/img/panel.png", "")
initDock()
listenInvalidIdSignal()
