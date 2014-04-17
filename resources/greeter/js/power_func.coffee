FREEDESKKTOP_LOGIN1 =
    name:"org.freedesktop.login1",
    path:"/org/freedesktop/login1",
    interface:"org.freedesktop.login1.Manager",

power_request = (power) ->
    try
        dbus_power = get_dbus("system",FREEDESKKTOP_LOGIN1,"Reboot")
        echo dbus_power
    catch e
        echo "dbus_power error:#{e}"
    if not dbus_power? then return
    document.body.style.cursor = "wait" if power isnt "suspend" and power isnt "lock"
    echo "Warning: The system will request ----#{power}----"
    switch power
        when "suspend" then dbus_power.Suspend(true)
        when "restart" then dbus_power.Reboot(true)
        when "shutdown" then dbus_power.PowerOff(true)
        else return

power_can = (power) ->
    if is_greeter
        try
            dbus_power = get_dbus("system",FREEDESKKTOP_LOGIN1,"CanReboot")
            echo dbus_power
        catch e
            echo "dbus_power error:#{e}"
        if not dbus_power? then return
        result = true
        switch power
            when "suspend" then result = dbus_power.CanSuspend_sync()
            when "restart" then result = dbus_power.CanReboot_sync()
            when "shutdown" then result = dbus_power.CanPowerOff_sync()
            else result = false
        echo "power_can : -----------Can_#{power} :#{result}------------"
        if result is undefined then result = true
        return result
    else
        try
            DEEPIN_SESSION =
                name:"com.deepin.SessionManager",
                path:"/com/deepin/SessionManager",
                interface:"com.deepin.SessionManager",
            
            dbus_power = get_dbus("session",DEEPIN_SESSION,"CanReboot")
            echo dbus_power
        catch e
            echo "dbus_power error:#{e}"
        if not dbus_power? then return
        result = true
        switch power
            when "suspend" then result = dbus_power.CanSuspend_sync()
            when "restart" then result = dbus_power.CanReboot_sync()
            when "shutdown" then result = dbus_power.CanShutdown_sync()
            else result = false
        echo "power_can : -----------Can_#{power} :#{result}------------"
        if result is undefined then result = true
        return result

power_force = (power) ->
    try
        dbus_power = get_dbus("system",FREEDESKKTOP_LOGIN1,"Reboot")
        echo dbus_power
    catch e
        echo "dbus_power error:#{e}"
    if not dbus_power? then return
    document.body.style.cursor = "wait" if power isnt "suspend" and power isnt "lock"
    echo "Warning: The system will request ----#{power}----"
    switch power
        when "suspend" then dbus_power.Suspend(false)
        when "restart" then dbus_power.Reboot(false)
        when "shutdown" then dbus_power.PowerOff(false)
        else return
