power_request = (power) ->
    # option = ["lock","suspend","logout","restart","shutdown"]
    document.body.style.cursor = "wait"
    echo "Warning: The system will request ----#{power}----"
    dbus_power = DCore.DBus.session("com.deepin.daemon.ShutdownManager")
    switch power
        when "lock" then dbus_power.RequestLock()
        when "suspend" then dbus_power.RequestSuspend()
        when "logout" then dbus_power.RequestLogout()
        when "restart" then dbus_power.RequestReboot()
        when "shutdown" then dbus_power.RequestShutdown()
        else return

power_can = (power) ->
    dbus_power = DCore.DBus.session("com.deepin.daemon.ShutdownManager")
    switch power
        when "lock" then return true
        when "suspend" then return dbus_power.CanSuspend()
        when "logout" then return dbus_power.CanLogout()
        when "restart" then return dbus_power.CanReboot()
        when "shutdown" then return dbus_power.CanShutdown()
        else return false


power_force = (power) ->
    # option = ["lock","suspend","logout","restart","shutdown"]
    document.body.style.cursor = "wait"
    echo "Warning: The system will ----#{power}---- Force!!"
    dbus_power = DCore.DBus.session("com.deepin.daemon.ShutdownManager")
    switch power
        when "lock" then dbus_power.RequestLock()
        when "suspend" then dbus_power.RequestSuspend()
        when "logout" then dbus_power.ForceLogout()
        when "restart" then dbus_power.ForceReboot()
        when "shutdown" then dbus_power.ForceShutdown()
        else return


