mode = "argv"


setBackground = (signal) ->
    opacity = 0.5
    switch signal
        when "SwitchMonitors" then opacity = 0.75
        when "SwitchLayout" then opacity = 0.95
        else opacity = 0.5
    DCore.Osd.set_background(opacity)


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
            DBusMediaKey?.connect(signal, do (signal_new = signal)->
                (keydown)->
                    mode = "dbus"
                    if signal_old isnt signal_new
                        signal_changed = true
                        setBackground(signal_new)
                    else
                        signal_changed = false
                    echo "MediaKey signal from #{signal_old} to #{signal_new}:signal_changed == #{signal_changed}"
                    signal_old = signal_new
                    osd[signal_new](keydown)
            )

check_mediakey_signal()

input_argv = DCore.Osd.get_argv()
console.log "input_argv:#{input_argv}"
signal_old = input_argv
setBackground(signal_old)
osd[input_argv]()
