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
        try
            @dbus = get_dbus(
                'session',
                name: "com.deepin.daemon.Dock",
                path: "/dde/dock/DockSetting",
                interface:"dde.dock.DockSetting",
                "GetHideMode"
            )
        catch e
            console.error("connect to DockSetting failed: #{e}")
            DCore.Dock.quit()

        @dbus.connect("HideModeChanged", (mode)=>
            console.log("mode changed to #{mode}")
            hideStatusManager.updateState()
        )
        @dbus.connect("DisplayModeChanged", (mode)=>
            console.log("DisplayModeChanged is emited")
            @updateSize(mode)
            # TODO:
            # switch between different mode.
            switch mode
                when DisplayMode.Classic
                    switchToClassicMode()
                when DisplayMode.Modern
                    switchToModernMode()
        )

    updateSize:(mode)->
        switch mode
            when DisplayMode.Classic
                DOCK_HEIGHT = 48
                PANEL_HEIGHT = 48

                ITEM_HEIGHT = 46.0
                ITEM_WIDTH = 48

                ICON_WIDTH = 32
                ICON_HEIGHT = 32
            when DisplayMode.Modern
                DOCK_HEIGHT = 68
                PANEL_HEIGHT = 60

                ITEM_HEIGHT = 60.0
                ITEM_WIDTH = 54.0

                ICON_WIDTH = 48.0
                ICON_HEIGHT = 48.0

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
