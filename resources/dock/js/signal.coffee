DCore.signal_connect("message_notify", (info)->)
DCore.signal_connect("display-mode-changed", ->
    console.log("display-mode-changed")
    if settings
        settings.updateSize(settings.displayMode())
    if debugRegion
        console.warn("[display-mode-changed] update_dock_region")
    update_dock_region(Panel.getPanelMiddleWidth())
)
DCore.signal_connect("resolution-changed", ->
    console.log("resolution-changed")
    systemTray?.updateTrayIcon()
)

DCore.signal_connect("embed_window_configure_changed", (info)->
    # console.log("embed_window_configure_changed")
    # console.log(info)
)
DCore.signal_connect("embed_window_configure_request", (info)->
    # console.log(info)

    item = $EW_MAP[info.XID]
    if not item
        console.log("get item from #{info.XID} failed")
        return

    Preview_container._calc_size(info)
    setTimeout(->
        console.log(item.element)
        console.log("Move Window to #{info.x}, #{info.y}")
        item.moveApplet(info)
    , 50)
)
DCore.signal_connect("embed_window_destroyed", (info)->
    # console.log("embed_window_destroyed")
    delete $EW_MAP[info.XID]
    # console.log(info)
)
DCore.signal_connect("embed_window_enter", (info)->
    console.log("embed_window_enter")
    __clear_timeout()
    clearTimeout(tooltip_hide_id)
    clearTimeout(hide_id)
    # console.log(info)
)
DCore.signal_connect("embed_window_leave", (info)->
    console.log("embed_window_leave")
    # console.log(info)
)

