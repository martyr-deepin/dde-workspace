_b.addEventListener("click", (e)->
    e.preventDefault()
    console.log("click on body")
    clearRegion()
)
_b.addEventListener("contextmenu", (e)->
    e.preventDefault()
    console.log("rightclick on body")
    clearRegion()
)
_b.addEventListener("dragenter", (e)->
    console.log("dragenter to body")
    _lastHover?.reset()
    updatePanel()
    # DCore.Dock.require_all_region()
)
_b.addEventListener("dragover", (e)->
    app_list.element.style.width = ''
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
    DCore.Dock.set_is_hovered(false)
    if debugRegion
        console.warn("[body.drop] update_dock_region")
    update_dock_region()
    s_id = e.dataTransfer.getData(DEEPIN_ITEM_ID)
    _dragTarget = _dragTargetManager.getHandle(s_id)
    if e.y > screen.height - DOCK_HEIGHT - ITEM_HEIGHT
        console.log("not working area")
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
        console.log("drag target is normal, remove it")
    else
        console.log("drag target is runtime, back to applist")
        _dragTarget.dragToBack = true
)

