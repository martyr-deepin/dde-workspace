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
        DCore.Dock.update_hide_mode()
