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

    show_desktop: (show = true) ->
        DCore.Guide.toggle_show_desktop(show)

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
            #TODO:here should get_dbus util the dbus connect succed!
            #It often console error:launcher dbus .service files not found
            @dbus = DCore.DBus.session(LAUNCHER)
        catch e
            @dbus_error = true
            console.log "#{LAUNCHER} dbus error :#{e}"

    launch: ->
        DCore.Guide.spawn_command_sync("/usr/bin/dde-launcher",false)

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
        console.debug "app_x_y:max:#{APP_NUM_MAX_IN_ONE_ROW};index:#{index};rows:#{rows};cols:#{cols};x:#{x},y:#{y}"
        return {x:x,y:y,rows:rows,cols:cols}

class Dock
    DOCK_SETTING =
        name:"com.deepin.daemon.Dock"
        path:"/dde/dock/DockSetting"
        interface:"dde.dock.DockSetting"
    DOCK_REGION =
        name:"com.deepin.daemon.Dock"
        path:"/dde/dock/DockRegion"
        interface:"dde.dock.DockRegion"
    DOCK_AREA =
        name:"com.deepin.daemon.Dock"
        path:"/dde/dock/XMouseAreaProxyer"
        interface:"dde.dock.XMouseAreaProxyer"
    constructor: ->
        try
            @dock_region_dbus = DCore.DBus.session_object(
                DOCK_REGION.name,
                DOCK_REGION.path,
                DOCK_REGION.interface
            )
            @dock_setting_dbus = DCore.DBus.session_object(
                DOCK_SETTING.name,
                DOCK_SETTING.path,
                DOCK_SETTING.interface
            )
            @dock_area_dbus = DCore.DBus.session_object(
                DOCK_AREA.name,
                DOCK_AREA.path,
                DOCK_AREA.interface
            )
            @launcher_index = 1
            @dss_index = DCore.Guide.get_dock_app_index("dde-control-center") + 2
            @region = @get_dock_region()
        catch e
            echo "dock daemon dbus error:#{e}"

    get_dock_region: ->
        region = @dock_region_dbus?.GetDockRegion_sync()
        pos =
            x0:region[0]
            y0:region[1]
            w:region[2]
            h:region[3]
        pos

    get_icon_pos: (icon_index) ->
        pos =
            x0:0
            y0:0
            w:0
            h:0
        region = @get_dock_region()
        pos.x0 = region.x0 + DOCK_PADDING[_dm][3] + ITEM_SIZE[_dm].w * (icon_index - 1) - 9
        pos.y0 = region.y0 - DOCK_PADDING[_dm][0] + 2
        pos.w = ITEM_SIZE[_dm].w
        pos.h = ITEM_SIZE[_dm].h
        #console.log "[get_icon_pos]:icon_index:#{icon_index}===x0:#{pos.x0},yo:#{pos.y0},x1:#{pos.w},y1:#{pos.h}"
        return pos

    get_launchericon_pos: ->
        return @get_icon_pos(@launcher_index)

    get_dssicon_pos: ->
        return @get_icon_pos(@dss_index)

    hide: ->
        @dock_setting_dbus.SetHideMode(1)
        #@dock_area_dbus.RegisterAreas([@region.x,@region.y,0,@region.h],1)

    show: ->
        @dock_setting_dbus.SetHideMode(0)
        #@dock_area_dbus.RegisterAreas([@region.x,@region.y,@region.w,@region.h],1)


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


class DockMode extends Widget
    constructor:(@id,@mode,parent)->
        super
        echo "new DockMode(#{@id},#{@mode})"
        inject_css(@element,"css/dock.css")
        parent.appendChild(@element)
        @create_dock()

    create_dock: ->
        @icons = []
        cls = "dock_mac"
        cls = "dock_win7" if @mode == DisplayMode.Efficient
        cls = "dock_xp" if @mode == DisplayMode.Classic
        @dock = create_element("div",cls,@element)
        switch @mode
            when DisplayMode.Fashion
                @icon_count = 14
                @applet_count = 0
                left = create_element("div","left",@dock)
                center = create_element("div","center",@dock)
                for i in [1...@icon_count]
                    @icons[i] = create_img("dock_icon_#{i}","img/dock/#{i}.png",center)
                right = create_element("div","right",@dock)
            when DisplayMode.Efficient, DisplayMode.Classic
                @icon_count = 8
                @applet_count = 3
                left = create_element("div","left",@dock)
                for i in [1...@icon_count]
                    @icons[i] = create_img("","img/dock/#{i}.png",left)
                right = create_element("div","right",@dock)
                time = create_element("div","time",right)
                d = new Date()
                time.innerText = @check_time(d.getHours()) + ":" + @check_time(d.getMinutes())
                for applet in ["sound","power","net"].reverse()
                    create_img(applet,"img/dock/#{applet}.png",right)

    get_icon_pos: (icon_index) ->
        if icon_index > @icons.length then icon_index = 1
        icon = {x:null,y:null,w:null,h:null}
        pos = get_page_xy(@icons[icon_index], 0, 0)
        icon.x = pos.x
        icon.y = pos.y
        icon.w = @icons[icon_index].clientWidth
        icon.h = @icons[icon_index].clientHeight
        console.log "[get_icon_pos]:#{icon_index}:(#{icon.x},#{icon.y})===w,h:#{icon.w},#{icon.h}"
        icon


    get_dss_index: ->
        7

    get_launcher_index: ->
        1

    check_time: (t) ->
        if t < 10
            return "0" + t
        t

    destory: ->
        @element.parentElement?.removeChild(@element)
        delete Widget.object_table[@id]

