mode = "argv"
signal_old = null

check_mediakey_signal= ->
    #MediaKey DBus
    MEDIAKEY =
        name: "com.deepin.daemon.KeyBinding"
        path: "/com/deepin/daemon/MediaKey"
        interface: "com.deepin.daemon.MediaKey"
    try
        DBusMediaKey = DCore.DBus.session_object(MEDIAKEY.name, MEDIAKEY.path, MEDIAKEY.interface)
    catch e
        echo "Error:-----DBusMediaKey:#{e}"
    for own signal of osd
        if signal isnt "SwitchMonitors"
            DBusMediaKey?.connect(signal, do (signal_each = signal)->
                (keydown)->
                    allElsHide() if signal_old isnt signal
                    signal_old = signal
                    echo signal_each + "-------callback"
                    mode = "dbus"
                    osd[signal_each](keydown)
            )

check_mediakey_signal()

input_argv = DCore.Osd.get_argv()
console.log "input_argv:#{input_argv}"
osd[input_argv]()
