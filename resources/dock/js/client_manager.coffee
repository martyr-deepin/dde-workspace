clientManager = null
try
    clientManager = get_dbus("session",
        name: "com.deepin.daemon.Dock",
        path:"/dde/dock/ClientManager",
        interface:"dde.dock.ClientManager",
        "ToggleShowDesktop"
    )
catch e
    console.error(e)
    DCore.Dock.quit()
