workareaTimer = null
HideMode =
    KeepShowing: "keep-showing"
    KeepHidden: "keep-hidden"
    AutoHide: "auto-hide"

DisplayMode =
    Legacy: "legacy"
    Modern: "modern"

class Setting
    constructor:->
        @dbus = get_dbus(
            'session',
            name: "com.deepin.daemon.Dock",
            path: "/dde/dock/DockSetting",
            interface:"dde.dock.DockSetting",
            "GetHideMode"
        )
        @dbus.connect("HideModeChanged", (mode)=>
            console.log("mode changed to #{mode}")
            hideStatusManager.updateState()
        )
        @dbus.connect("DisplayModeChanged", (mode)=>
            # TODO:
            # switch between different mode.
            console.log("DisplayModeChanged is emited")
        )

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
