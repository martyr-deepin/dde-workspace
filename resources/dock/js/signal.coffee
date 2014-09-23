DCore.signal_connect("message_notify", (info)->)
DCore.signal_connect("display-mode-changed", ->
    if settings
        settings.updateSize(settings.displayMode())
    if debugRegion
        console.warn("[display-mode-changed] update_dock_region")
    update_dock_region(Panel.getPanelMiddleWidth())
)
DCore.signal_connect("resolution-changed", ->
    systemTray?.updateTrayIcon()
)

DCore.signal_connect("embed_window_configure_changed", (info)->
)
DCore.signal_connect("embed_window_configure_request", (info)->
    item = $EW_MAP[info.XID]
    if not item
        console.log("get item from #{info.XID} failed")
        return

    Preview_container._calc_size(info)
    setTimeout(->
        item.moveApplet(info)
    , 50)
)
DCore.signal_connect("embed_window_destroyed", (info)->
    delete $EW_MAP[info.XID]
)
DCore.signal_connect("embed_window_enter", (info)->
    __clear_timeout()
    clearTimeout(tooltip_hide_id)
    clearTimeout(hide_id)
)
DCore.signal_connect("embed_window_leave", (info)->
)

