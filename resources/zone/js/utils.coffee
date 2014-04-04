
cfgKeyVal = []
zoneKeyText = []
cfgKey = ["left-up","left-down","right-up","right-down"]

option_text = [_("Launcher"),_("System Settings"),_("Workspace"),_("Desktop"),_("None")]
cfgValue = [
    "/usr/bin/launcher"
    "dbus-send --type=method_call --dest=com.deepin.Dss /com/deepin/Dss com.deepin.Dss.Toggle",
    "workspace",
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
    echo "zoneDBus not null" if zoneDBus?
    try
        switch key
            when "left-up" then zoneDBus?.SetTopLeft_sync(value)
            when "left-down" then zoneDBus?.SetBottomLeft_sync(value)
            when "right-up" then zoneDBus?.SetTopRight_sync(value)
            when "right-down" then zoneDBus?.SetBottomRight_sync(value)
    catch e
        echo "setZoneDBusSettings error : #{e}"

 #-------------------------------------------

getZoneConfig = ->
    for key,i in cfgKey
        value = DCore.Zone.get_config(key)
        cfgKeyVal[key] = value
        zoneKeyText[key] = option_text[j] for val ,j in cfgValue when val is value
    echo "cfgKeyVal:"
    echo cfgKeyVal
    echo "zoneKeyText:"
    echo zoneKeyText
 
setZoneConfig = (key,value)->
    cfgKeyVal[key] = value
    zoneKeyText[key] = option_text[j] for val ,j in cfgValue when val is value
    echo "setZoneCfg : key: #{key}------value: #{value}"
    DCore.Zone.set_config(key,value)

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
