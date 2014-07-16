calc_app_item_size = ->
    return if IN_INIT
    # TODO:
    # calc when added/removed
    #systemTray?.updateTrayIcon()
    apps = $s(".AppItem")
    return if apps.length = 0

    container = $("#container")
    list_width = container.clientWidth
    container_list = container.children
    item_num = 0
    for i in [0...container_list.length]
        item_num += container_list[i].children.length
    client_width = $("#containerWarp").clientWidth
    w = clamp(client_width / item_num, 34, ITEM_WIDTH * MAX_SCALE)
    ICON_SCALE = clamp(w / ITEM_WIDTH, 0, MAX_SCALE)
    # console.log "new ICON_SCALE: #{ICON_SCALE}"

    for i in apps
        Widget.look_up(i.id)?.update_scale()

        h = w * (ITEM_HEIGHT / ITEM_WIDTH)
        # apps are moved up, so add 8

    height = h * (ITEM_HEIGHT - BOARD_IMG_MARGIN_BOTTOM) / ITEM_HEIGHT + BOARD_IMG_MARGIN_BOTTOM * ICON_SCALE + 8
    # DCore.Dock.change_workarea_height(height)

    # update_dock_region($("#container").clientWidth)
    if panel
        panel.set_width(Panel.getPanelWidth())

update_dock_region = do->
    lastWidth = null
    (w, h=DOCK_HEIGHT)->
        console.log("update_dock_region: last Width: #{lastWidth}, height: #{h}")
        if w
            lastWidth = w
        else if lastWidth
            w = lastWidth
        # console.log("width: #{w}")
        apps = $s(".AppItem")
        last = apps[apps.length-1]
        if last and last.clientWidth != 0
            if w
                app_len = w
            else
                app_len = w #ITEM_WIDTH * apps.length
            panel_width = Panel.getPanelWidth()
            if settings.displayMode() == 'win7'
                left_offset = 0
            else
                left_offset = (screen.width - app_len) / 2
                # console.log("set dock region height to #{DOCK_HEIGHT}")
                # if setting.hideMode() != HideMode.Showing
                #     h = 0
            DCore.Dock.force_set_region(left_offset, 0, ICON_SCALE * ITEM_WIDTH * apps.length, panel_width, h)

_b.onresize = ->
    calc_app_item_size()
    update_dock_region($("#container").clientWidth)

clearRegion = ->
    DCore.Dock.set_is_hovered(false)
    update_dock_region()
