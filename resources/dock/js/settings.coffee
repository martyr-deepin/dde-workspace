workareaTimer = null
HideMode =
    KeepShowing: 0
    KeepHidden: 1
    AutoHide: 2

HideModeNameMap =
    "keep-showing": 0
    "keep-hidden": 1
    "auto-hide": 2

DisplayMode =
    Modern: 0
    Classic: 1

DisplayModeNameMap =
    "modern": 0
    "classic": 1

class Setting
    constructor:->
        @dbus = get_dbus(
            'session',
            name: "com.deepin.daemon.Dock",
            path: "/dde/dock/DockSetting",
            interface:"dde.dock.DockSetting",
            "GetHideMode"
        )
        if not @dbus
            console.error("connect to DockSetting failed")
            DCore.Dock.quit()

        @dbus.connect("HideModeChanged", (mode)=>
            console.log("mode changed to #{mode}")
            hideStatusManager.updateState()
        )
        @dbus.connect("DisplayModeChanged", (mode)=>
            # TODO:
            # switch between different mode.
            console.log("DisplayModeChanged is emited")
            switch mode
                when DisplayMode.Classic
                    switchToClassicMode()
                when DisplayMode.Modern
                    switchToModernMode()
            @update_height(mode)
        )

    update_height:(mode)->
        switch mode
            when DisplayMode.Classic
                DOCK_HEIGHT = 48
                PANEL_HEIGHT = 48
            when DisplayMode.Modern
                DOCK_HEIGHT = 68
                PANEL_HEIGHT = 60

        DCore.Dock.set_height(DOCK_HEIGHT)
        DCore.Dock.set_panel_height(PANEL_HEIGHT)

    hideMode:->
        mode = @dbus.GetHideMode_sync()
        if mode == "default" || mode == "intelligent"
            return HideMode.KeepShowing
        mode

    setHideMode:(id)->
        console.log("setHideMode: #{id}")
        @dbus.SetHideMode(id)

    displayMode:->
        return @dbus.GetDisplayMode_sync()

    setDisplayMode:(id)->
        @dbus.SetDisplayMode(id)
