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
    item = $EW_MAP[info.XID]
    if not item
        console.log("get item from #{info.XID} failed")
        return
    item.updateAppletPosition()
)

DCore.signal_connect("embed_window_configure_request", (info)->
    item = $EW_MAP[info.XID]
    if not item
        console.log("get item from #{info.XID} failed")
        return
    item.updateAppletPosition()
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

DCore.signal_connect("icon_theme_changed", ()->
    show_launcher.update_icon()
    trash.update_icon()
    for own id, dbus of $DBus
        icon = dbus.Data[ITEM_DATA_FIELD.icon] || NOT_FOUND_ICON
        Widget.look_up(id)?.change_icon(icon)
)
DCore.signal_connect("use_24_hour_display_changed", (info)->
    time?.setUse24Hour(info.hour_display==24)
    time?.updateTime()
    if settings.displayMode() != DisplayMode.Fashion and systemTray?.isShowing
        systemTray?.updateTrayIcon()
)
