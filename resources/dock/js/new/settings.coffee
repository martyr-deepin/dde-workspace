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
        mode = @dbus.GetHideMode_sync()
        if mode == "default" || mode == "intelligent"
            return 'keep-showing'
        mode

    setHideMode:(id)->
        console.log(id)
        @dbus.SetHideMode(id)
