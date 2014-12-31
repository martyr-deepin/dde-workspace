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

        @displayModeCallback = []
        @_displayDate = @dbus.GetDisplayDate_sync()
        @_displayWeek = @dbus.GetDisplayWeek_sync()

        @dbus.connect("HideModeChanged", (mode)=>
            hideStatusManager.updateState()
        )
        @dbus.connect("DisplayModeChanged", (mode)=>
            # dde-session-daemon will restart dock
            # DCore.Dock.quit()
            @updateSize(mode)

            # TODO:
            # switch between different mode.
            switch mode
                when DisplayMode.Fashion
                    switchToFashionMode()
                when DisplayMode.Efficient
                    switchToEfficientMode()
                    systemTray?.updateTrayIcon()
                when DisplayMode.Classic
                    switchToClassicMode()
                    systemTray?.updateTrayIcon()

            for own name, fn of @displayModeCallback
                fn(mode)
        )

    connectDisplayModeChanged: (name, fn)=>
        @displayModeCallback[name] = fn

    disconnectDisplayModeChanged: (name)=>
        delete @displayModeCallback[name]

    connectClockTypeChanged:(fn)->
        @dbus.connect("ClockTypeChanged", fn)

    connectDisplayDateChanged:(fn)->
        @dbus.connect("DisplayDateChanged", (d)=>
            @_displayDate = d
            fn()
        )

    connectDisplayWeekChanged:(fn)->
        @dbus.connect("DisplayWeekChanged", (d)=>
            @_displayWeek = d
            fn()
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
        ITEM_DEFAULT_WIDTH = ALL_ITEM_DEFAULT_WIDTH[mode]

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

    clockType:->
        @dbus.GetClockType_sync()

    setClockType:(t)->
        @dbus.SetClockType(t)

    displayDate:->
        @_displayDate

    setDisplayDate:(d)->
        console.log("set display date to #{d}")
        @dbus.SetDisplayDate(d)

    displayWeek:->
        @_displayWeek

    setDisplayWeek:(d)->
        @dbus.SetDisplayWeek(d)
