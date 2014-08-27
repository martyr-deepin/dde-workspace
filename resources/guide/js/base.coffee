class Fcitx
    FCITX =
        name:"org.fcitx.Fcitx-0"
        path:"/inputmethod"
        interface:"org.fcitx.Fcitx.InputMethod"

    constructor: ->
        @dbus = null
        @IMList = []
        @IMTrueList = []
        try
            @dbus = DCore.DBus.session(
                FCITX.name,
                FCITX.path,
                FCITX.interface
            )
            @IMList = @DBusIM.IMList
            @IMTrueList.push(im[1]) for im in @IMList when im[3]
        catch e
            console.log "dbus #{FCITX.interface} error :#{e}"

    setCurrentIM: (im)->
        if im not in @IMTrueList then return
        @dbus?.setCurrentIM_sync(im)

class Session
    SESSION = "com.deepin.SessionManager"
    constructor: ->
        @STAGE = {
            SessionStageInitEnd:1
            SessionStageCoreBegin:2
            SessionStageCoreEnd:3
            SessionStageAppsBegin:4
            SessionStageAppsEnd:5
        }
        try
            @dbus = DCore.DBus.session(SESSION)
        catch e
            console.log "dbus #{SESSION} error :#{e}"

    getStage : ->
        return @dbus?.Stage

class Desktop
    DESKTOP = "com.deepin.dde.desktop"
    constructor: ->
        try
            @dbus = DCore.DBus.session(DESKTOP)
        catch e
            console.log "dbus #{DESKTOP} error :#{e}"

    item_signal: (@item_signal_cb) ->
        @dbus?.connect("ItemUpdate",@item_signal_cb)

    richdir_signal: (@richdir_signal_cb) ->
        @dbus?.connect("RichdirCreate",@richdir_signal_cb)

    item_signal_disconnect: ->
        @dbus?.dis_connect("ItemUpdate",@item_signal_cb)

    richdir_signal_disconnect: ->
        @dbus?.dis_connect("RichdirCreate",@richdir_signal_cb)

class Dss
    DSS = "com.deepin.dde.ControlCenter"
    constructor: ->
        try
            @dbus = DCore.DBus.session(DSS)
        catch e
            console.log "dbus error :#{e}"

    hide: ->
        @dbus?.Hide_sync()

    toggle: ->
        @dbus?.Toggle_sync()

    show: ->
        @dbus?.Show_sync()

class Launcher
    LAUNCHER = "com.deepin.dde.launcher"
    constructor: ->
        @dbus_error = false
        try
            @dbus = DCore.DBus.session(LAUNCHER)
        catch e
            @dbus_error = true
            console.log "#{LAUNCHER} dbus error :#{e}"

    hide: ->
        @dbus?.Hide_sync()

    toggle: ->
        @dbus?.Toggle_sync()

    show: ->
        @dbus?.Show_sync()

    hide_signal: (@hide_signal_cb) ->
        @dbus?.connect("Closed",@hide_signal_cb)

    show_signal: (@show_signal_cb) ->
        @dbus?.connect("Shown",@show_signal_cb)

    show_signal_disconnect: ->
        @dbus?.dis_connect("Shown",@show_signal_cb)

    hide_signal_disconnect: ->
        @dbus?.dis_connect("Closed",@hide_signal_cb)

class LauncherDaemon
    LAUNCHER_DAEMON = "com.deepin.dde.daemon.Launcher"
    constructor: ->
        @dbus_error = false
        try
            @dbus = DCore.DBus.session(LAUNCHER_DAEMON)
        catch e
            @dbus_error = true
            console.log "#{LAUNCHER_DAEMON} dbus error :#{e}"

    search: (str) ->
        return @dbus?.Search_sync(str)

    app_x_y: (index) ->
        rows = Math.floor(index / APP_NUM_MAX_IN_ONE_ROW)
        cols = index % APP_NUM_MAX_IN_ONE_ROW
        x = COLLECT_LEFT + (EACH_APP_WIDTH + EACH_APP_MARGIN_LEFT) * cols
        y = COLLECT_TOP + (EACH_APP_WIDTH + EACH_APP_MARGIN_TOP) * rows
        echo "app_x_y:max:#{APP_NUM_MAX_IN_ONE_ROW};index:#{index};rows:#{rows};cols:#{cols};x:#{x},y:#{y}"
        return {x:x,y:y,rows:rows,cols:cols}

class Dock
    DOCK_REGION =
        name:"com.deepin.daemon.Dock"
        path:"/dde/dock/DockRegion"
        interface:"dde.dock.DockRegion"

    constructor: ->
        try
            @dock_region_dbus = DCore.DBus.session_object(
                DOCK_REGION.name,
                DOCK_REGION.path,
                DOCK_REGION.interface
            )
        catch e
            echo "#{DOCK_REGION}: dbus error:#{e}"

    get_icon_pos: (icon_index) ->
        @dock_region = @dock_region_dbus?.GetDockRegion_sync()
        @x0 = @dock_region[0]
        @y0 = @dock_region[1]
        @x1 = @dock_region[2]
        @y1 = @dock_region[3]
        pos =
            x0:0
            y0:0
            x1:0
            y1:0
        pos.x0 = @x0 + DOCK_PADDING + EACH_ICON * (icon_index - 1)
        pos.y0 = @y0# - 8
        pos.x1 = pos.x0 + ICON_SIZE
        pos.y1 = pos.y0 + ICON_SIZE
        return pos

    get_launchericon_pos: ->
        pos = @get_icon_pos(1)
        return pos

    get_dssicon_pos: ->
        pos = @get_icon_pos(8)
        return pos


class Page extends Widget
    constructor: (@id)->
        super
        echo "new #{@id} Page"
        @img_src = "img"
        document.body.style.background = "rgba(0,0,0,0.6)"
        @element.style.display = "-webkit-box"
        @element.style.width = "100%"
        @element.style.height = "100%"
        @element.style.webkitBoxPack = "center"
        @element.style.webkitBoxAlign = "center"
        #@element.style.webkitBoxOrient = "vertical"
        @msg_tips = create_element("div","msg_tips",@element)
        @msg_tips.style.position = "relative"
        @msg_tips.style.color = "#fff"
        @msg_tips.style.textAlign = "center"
        @msg_tips.style.textShadow = "0 1px 1px rgba(0,0,0,0.7)"

    show_message: (@message) ->
        if not @message_div?
            @message_div = create_element("div","message_#{@id}",@msg_tips)
            @message_div.style.fontSize = "2em"
            @message_div.style.lineHeight = "200%"
        @message_div.innerText = @message

    show_tips: (@tips) ->
        if not @tips_div?
            @tips_div = create_element("div","tips_#{@id}",@msg_tips)
            @tips_div.style.fontSize = "1.6em"
            @tips_div.style.lineHeight = "200%"
            @tips_div.style.position = "relative"
            @tips_div.style.marginTop = "40px"
        @tips_div.innerText = @tips
