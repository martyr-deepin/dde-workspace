mode = "argv"

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
        DBusMediaKey?.connect(signal, (keydown)=>
            echo signal + "-----------"
            mode = "dbus"
            osd[signal](keydown)
        )
    
    #如果osd已经起来了，且还没有自动退出时，
    #监听dbus，跟正常的connect一样，调起来
    #mediakey_signal = true#for test


input_argv = DCore.Osd.get_argv()
console.log "input_argv:#{input_argv}"
osd[input_argv]()

check_mediakey_signal()
