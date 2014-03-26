class Setting
    constructor:->
        @dbus = get_dbus(
            'session',
            name: "dde.dock.Daemon",
            path: "/dde/dock/DockSetting",
            interface:"dde.dock.DockSetting"
        )
        @dbus.connect("HideModeChanged", (mode)=>
            console.log("mode changed to #{mode}")
        )
        console.log(@dbus)

    hideMode:->
        @dbus.GetHideMode_sync()

    setHideMode:(id)->
        console.log(id)
        @dbus.SetHideMode(id)
