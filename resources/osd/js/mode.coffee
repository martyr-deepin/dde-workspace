
mode = "argv"# or "dbus"
DBusMediaKey = null
input_argv = null
switch mode
    when "dbus"
        #MediaKey DBus
        MEDIAKEY =
            name: "com.deepin.daemon.KeyBinding"
            path: "/com/deepin/daemon/MediaKey"
            interface: "com.deepin.daemon.MediaKey"
        try
            DBusMediaKey = DCore.DBus.session_object(MEDIAKEY.name, MEDIAKEY.path, MEDIAKEY.interface)
        catch e
            echo "Error:-----DBusMediaKey:#{e}"
        echo DBusMediaKey
    when "argv"
        input_argv = DCore.Osd.get_argv()
        console.log "input_argv:#{input_argv}"
        osd[input_argv]()
