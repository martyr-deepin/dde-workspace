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

power_get_inhibit = (power) ->
    result = null
    try
        dbus_login1 = get_dbus("system",FREEDESKKTOP_LOGIN1,"ListInhibitors")
    catch e
        echo "dbus_login1 error:#{e}"
    if not dbus_login1? then return result
    
    inhibitorsList = dbus_login1.ListInhibitors_sync()
    echo "inhibitorsList.lengt:" + inhibitorsList.length
    echo inhibitorsList
    cannot_excute = []
    for inhibit,i in inhibitorsList
        if inhibit is undefined then break
        echo inhibit
        try
            if inhibit[3] is "block"
                type = inhibit[0]
                switch type
                    when "shutdown" then cannot_excute.push({type:"shutdown",inhibit:inhibit})
                    when "idle"  then cannot_excute.push({type:"suspend",inhibit:inhibit})
                    when "handle-suspend-key"  then cannot_excute.push({type:"suspend",inhibit:inhibit})
                    when "handle-power-key"
                        cannot_excute.push({type:"restart",inhibit:inhibit})
                        cannot_excute.push({type:"shutdown",inhibit:inhibit})
                        cannot_excute.push({type:"logout",inhibit:inhibit})
        catch e
            echo "#{e}"


    if cannot_excute.length == 0 then return result
    for tmp in cannot_excute
        if power is tmp.type then result = tmp.inhibit
    echo "power_get_inhibit(#{power}) result:#{result}"
    return result

power_can = (power)->
    inhibit = power_get_inhibit(power)
    if inhibit is null
        echo "power_can:#{power} true"
        return true
    else
        echo "power_can:#{power} false"
        return false


power_can_freedesktop = (power) ->
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
