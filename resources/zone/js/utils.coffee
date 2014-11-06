DEBUG = false

 #-------------------------------------------
DSS_SHOWIN =
    left: "dbus-send --print-reply --dest=com.deepin.dde.ControlCenter /com/deepin/dde/ControlCenter com.deepin.dde.ControlCenter.ToggleInLeft"
    toggle: "dbus-send --print-reply --dest=com.deepin.dde.ControlCenter /com/deepin/dde/ControlCenter com.deepin.dde.ControlCenter.Toggle"

cfgKeyVal = []
zoneKeyText = []
cfgKey = ["left-up","left-down","right-up","right-down"]

# option_text must be one-to-one with cfgValue
option_text = [_("Control Center"),_("All Windows"),_("Launcher"),_("Desktop"),_("None")]

cfgValue = [
    DSS_SHOWIN.toggle,
    "/usr/bin/xdotool key Super+w",
    "/usr/bin/dde-launcher"
    "/usr/lib/deepin-daemon/desktop-toggle",
    ""
]

 #-------------------------------------------

zoneDBus = null
getZoneDBus = ->
    ZONE = "com.deepin.daemon.Zone"
    try
        zoneDBus = DCore.DBus.session(ZONE)
    catch e
        echo "zoneDBus #{ZONE} error : #{e}"

enableZoneDetect = (enable) ->
    try
        zoneDBus?.EnableZoneDetected_sync(enable)
    catch e
        echo "setZoneDBusSettings error : #{e}"


setZoneDBusSettings = (key,value)->
    echo "setZoneDBusSettings : key: #{key}------value: #{value}"
    try
        switch key
            when "left-up" then zoneDBus?.SetTopLeft_sync(value)
            when "left-down" then zoneDBus?.SetBottomLeft_sync(value)
            when "right-up" then zoneDBus?.SetTopRight_sync(value)
            when "right-down" then zoneDBus?.SetBottomRight_sync(value)
    catch e
        echo "setZoneDBusSettings error : #{e}"

 #-------------------------------------------
update_cfgValue = (key,value) ->
    if value in [DSS_SHOWIN.left,DSS_SHOWIN.toggle]
        console.debug "[update_cfgValue]::[key]:#{key};value:#{value}"
        if key in ["left-up","left-down"]
            value = DSS_SHOWIN.left
        else
            value = DSS_SHOWIN.toggle
        cfgValue[0] = value
        console.debug "[update_cfgValue]::[key]:#{key};value updated to ====:#{value}"
    value

getZoneConfig = ->
    for key,i in cfgKey
        value = DCore.Zone.get_config(key)
        value = update_cfgValue(key,value)
        cfgKeyVal[key] = value
        zoneKeyText[key] = option_text[j] for val ,j in cfgValue when val is value

setZoneConfig = (key,value)->
    value = update_cfgValue(key,value)
    cfgKeyVal[key] = value
    zoneKeyText[key] = option_text[j] for val ,j in cfgValue when val is value
    console.debug "setZoneCfg : key: #{key}------value: #{value}"
    DCore.Zone.set_config(key,value)
    setZoneDBusSettings(key,value)

 #-------------------------------------------

bgRadial = ->
    wWidth = window.innerWidth
    wHeight = window.innerHeight
    canvas = create_element("canvas","canvas",document.body)
    context = canvas.getContext("2d")
    x = wWidth / 2
    y = wHeight / 2
    r = wWidth / 2
    echo wWidth + "------" + wHeight + ";" + x + "-----" + y + "r:#{r}"

    rg = context.createRadialGradient(x,y,0,x,y,r)
    rg.addColorStop(0,'#FFFFFF')
    rg.addColorStop(1,'#000000')

    context.fillStyle = rg
    context.beginPath()
    context.arc(x,y,r,0,2 * Math.PI)
    context.fill()

#bgRadial()
