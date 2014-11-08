_b.addEventListener("click", (e)->
    e.preventDefault()
    clearRegion()
)
_b.addEventListener("contextmenu", (e)->
    e.preventDefault()
    clearRegion()
)
_b.addEventListener("dragenter", (e)->
    _lastHover?.reset()
    updatePanel()
    # DCore.Dock.require_all_region()
)
_b.addEventListener("dragover", (e)->
    app_list.element.style.width = ''
    s_id = e.dataTransfer.getData(DEEPIN_ITEM_ID)
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
    DCore.Dock.set_is_hovered(false)
    if debugRegion
        console.warn("[body.drop] update_dock_region")
    update_dock_region()
    s_id = e.dataTransfer.getData(DEEPIN_ITEM_ID)
    _dragTarget = _dragTargetManager.getHandle(s_id)
    if e.y > screen.height - DOCK_HEIGHT - ITEM_HEIGHT
        _dragTarget?.dragToBack = false
        _dragTarget?.back(e.x, e.y)
        _dragTargetManager.remove(s_id)
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
    else
        _dragTarget.dragToBack = true
)

try
    launcherDaemon = DCore.DBus.session(LAUNCHER_DAEMON)
    launcherDaemon.connect("ItemChanged", (status, info, categories)->
        if !!status.match(/^deleted$/i)
            path = info[0]
            name = info[1]
            id = info[2]
            icon = info[3]
            dockedAppManager?.Undock(id)
    )
catch e
    console.error e
    # DCore.Dock.quit()


XMouseAreaDBusInfo =
    name: "com.deepin.api.XMouseArea"
    path: "/com/deepin/api/XMouseArea"
    interface: "com.deepin.api.XMouseArea"

try
    mousearea = get_dbus("session", XMouseAreaDBusInfo, "RegisterFullScreen")
    mousearea.connect("CancelAllArea", ->
        if settings.hideMode() == HideMode.KeepHidden
            update_dock_region($("#container").clientWidth, 0)
        else
            update_dock_region($("#container").clientWidth)
    )
catch e
    console.error("connect XMouseArea dbus failed #{e}")
    DCore.Dock.quit()
