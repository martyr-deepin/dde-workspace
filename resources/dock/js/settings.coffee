workareaTimer = null
HideMode=
    KeepShowing: "keep-showing"
    KeepHidden: "keep-hidden"
    AutoHide: "auto-hide"

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
            console.warn("mode changed to #{mode}")
            hideStatusManager.updateState()
        )

    hideMode:->
        mode = @dbus.GetHideMode_sync()
        if mode == "default" || mode == "intelligent"
            return HideMode.KeepShowing
        mode

    setHideMode:(id)->
        console.log("setHideMode: #{id}")
        @dbus.SetHideMode(id)
