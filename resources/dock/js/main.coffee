DCore.signal_connect("in_mini_mode", ->)
DCore.signal_connect("in_normal_mode", ->)
DCore.signal_connect("close_window", (info)->)
DCore.signal_connect("active_window", (info)->)
DCore.signal_connect("message_notify", (info)->)

DCore.signal_connect("embed_window_configure_changed", (info)->
    console.log("embed_window_configure_changed")
    console.log(info)
)
DCore.signal_connect("embed_window_configure_request", (info)->
    console.log(info)

    item = $EW_MAP[info.XID]
    if not item
        console.log("get item from #{info.XID} failed")
        return

    Preview_container._calc_size(info)
    setTimeout(->
        console.warn(item.element)
        xy = get_page_xy(item.element)
        w = item.element.clientWidth || 0
        extraHeight = PREVIEW_TRIANGLE.height + 6 + PREVIEW_WINDOW_BORDER_WIDTH + PREVIEW_CONTAINER_BORDER_WIDTH + info.height
        x = xy.x + w/2 - info.width/2
        y = xy.y - extraHeight
        console.log("Move Window to #{x}, #{y}")
        $EW.move(info.XID, x, y)
    , 50)
)
DCore.signal_connect("embed_window_destroyed", (info)->
    console.log("embed_window_destroyed")
    delete $EW_MAP[info.XID]
    console.log(info)
)
DCore.signal_connect("embed_window_enter", (info)->
    console.log("embed_window_enter")
    __clear_timeout()
    clearTimeout(tooltip_hide_id)
    clearTimeout(hide_id)
    console.log(info)
)
DCore.signal_connect("embed_window_leave", (info)->
    console.log("embed_window_leave")
    console.log(info)
)

_b.addEventListener("click", (e)->
    e.preventDefault()
    console.log("click on body")
    update_dock_region()
)
_b.addEventListener("contextmenu", (e)->
    e.preventDefault()
    console.log("rightclick on body")
    update_dock_region()
)
_b.addEventListener("dragenter", (e)->
    console.log("dragenter to body")
    clearTimeout(cancelInsertTimer)
    _lastHover?.reset()
    updatePanel()
    # DCore.Dock.require_all_region()
)
_b.addEventListener("dragover", (e)->
    clearTimeout(cancelInsertTimer)
    s_id = e.dataTransfer.getData(DEEPIN_ITEM_ID)
    console.log("dragover ##{s_id}# on body")
    t = Widget.look_up(s_id)
    if not t
        return

    e.preventDefault()

    if e.y > screen.height - DOCK_HEIGHT - ITEM_HEIGHT
        e.dataTransfer.dropEffect = 'copy'
    else
        e.dataTransfer.dropEffect = 'move'
)
_b.addEventListener("drop", (e)->
    e.stopPropagation()
    e.preventDefault()
    console.log("drop on body")
    # update_dock_region()
    s_id = e.dataTransfer.getData(DEEPIN_ITEM_ID)
    _dragTarget = _dragTargetManager.getHandle(s_id)
    if e.y > screen.height - DOCK_HEIGHT - ITEM_HEIGHT
        console.error("not working area")
        _dragTarget?.dragToBack = false
        _dragTarget?.back(e.x, e.y)
        _dragTargetManager.remove(s_id)
        update_dock_region()
        return
    s_widget = Widget.look_up(s_id)
    if not s_widget
        return

    if s_widget.isNormal()
        _dragTarget.dragToBack = false
        _dragTarget.reset()
        calc_app_item_size()

        t = s_widget.element
        t.style.position = "fixed"
        _b.appendChild(t)
        t.style.left = "#{e.x - ITEM_WIDTH / 2}px"
        t.style.top = "#{e.y - ITEM_HEIGHT / 2}px"
        s_widget.destroyWidthAnimation()
        _dragTarget.removeImg()
        _dragTargetManager.remove(s_id)
        console.log("drag target is normal, remove it")
    else
        console.log("drag target is runtime, back to applist")
        _dragTarget.dragToBack = true
)

settings = new Setting()
hideStatusManager = new HideStatusManager(settings.hideMode())

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
time = null
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

        calc_app_item_size()
        update_dock_region($("#container").clientWidth)
        DCore.Dock.change_workarea_height(DOCK_HEIGHT)
    , 100)

    if settings.hideMode() == HideMode.KeepHidden
        hideStatusManager.updateState()
        return

    setTimeout(->
        _CW.style.webkitTransform = "translateY(0)"
        panel.panel.style.webkitTransform = "translateY(0)"
        hideStatusManager.updateState()
    , 1000)


time = new Time("time", "js/plugins/time/img/time.png", "")
initDock()
