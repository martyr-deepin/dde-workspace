workareaTimer = null

class Setting
    constructor:->
        try
            @dbus = get_dbus(
                'session',
                name: "com.deepin.daemon.Dock",
                path: "/dde/dock/DockSetting",
                interface:"dde.dock.DockSetting",
                "GetHideMode"
            )
        catch e
            console.error(e)
            DCore.Dock.quit()

        @dbus.connect("HideModeChanged", (mode)=>
            hideStatusManager.updateState()
        )
        @dbus.connect("DisplayModeChanged", (mode)=>
            @updateSize(mode)

            # TODO:
            # switch between different mode.
            switch mode
                when DisplayMode.Fashion
                    switchToFashionMode()
                when DisplayMode.Efficient
                    switchToEfficientMode()
                    $("#trayarea").style.webkitTransform = 'translateY(0)'
                    systemTray?.updateTrayIcon()
                when DisplayMode.Classic
                    switchToClassicMode()
                    $("#trayarea").style.webkitTransform = 'translateY(0)'
                    systemTray?.updateTrayIcon()
        )

    updateSize:(mode)->
        if typeof DisplayMode[mode] == undefined
            console.warn("#{mode} is not defined")
            return
        DOCK_HEIGHT = ALL_DOCK_HEIGHT[mode]
        PANEL_HEIGHT = ALL_PANEL_HEIGHT[mode]
        ITEM_HEIGHT = ALL_ITEM_HEIGHT[mode]
        ITEM_WIDTH = ALL_ITEM_WIDTH[mode]
        ICON_WIDTH = ALL_ICON_WIDTH[mode]
        ICON_HEIGHT = ALL_ICON_HEIGHT[mode]
        ITEM_MENU_OFFSET = ALL_ITEM_MENU_OFFSET[mode]

    hideMode:->
        mode = @dbus.GetHideMode_sync()
        if mode == "default" || mode == "intelligent"
            return HideMode.KeepShowing
        mode
    setHideMode:(id)->
        @dbus.SetHideMode(id)

    displayMode:->
        return @dbus.GetDisplayMode_sync()

    setDisplayMode:(id)->
        @dbus.SetDisplayMode(id)
