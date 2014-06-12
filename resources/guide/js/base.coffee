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
        @dbus?.connect("RichdirUpdate",@richdir_signal_cb)
    
    item_signal_disconnect: ->
        @dbus?.dis_connect("ItemUpdate",@item_signal_cb)

    richdir_signal_disconnect: ->
        @dbus?.dis_connect("RichdirUpdate",@richdir_signal_cb)
    

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
            @dock_region = @dock_region_dbus.GetDockRegion_sync()
        catch e
            echo "#{DOCK_REGION}: dbus error:#{e}"

    get_icon_pos: (icon_index) ->
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
        pos.y0 = @y0
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


        


class ButtonNext extends Widget
    normal_interval = null
    normal_hover_interval = null
    
    constructor: (@id,@text,@parent)->
        super
        
        @parent?.appendChild(@element)
        @img_src = "img"
        @img_normal = "#{@img_src}/next_normal.png"
        @img_hover = "#{@img_src}/next_hover.png"
        @img_press = "#{@img_src}/next_press.png"
    
    set_img:(@img_normal,@img_hover,@img_press) ->

    create_button:(@cb,@show_animation = false) ->
        @element.style.display = "-webkit-box"
        @element.style.height = "64px"
        @element.style.color = "#fff"
        @element.style.textShadow = "0 1px 1px rgba(0,0,0,0.7)"
        
        @bn_text = create_element("div","bn_text",@element)
        @bn_text.innerText = @text
        @bn_text.style.fontSize = "2.2em"
        @bn_text.style.lineHeight = "3.0em"
        @bn_text.style.textAlign = "right"

        @bn_img = create_img("bn_img",@img_normal,@element)
        @bn_img.style.width = "6.4em"
        @bn_img.style.height = "6.4em"
        if @show_animation then @normal_animation()
        @bn_img.addEventListener("mouseover",=>
            @bn_img.style.cursor = "pointer"
            @stop_animation()
            @bn_img.src = @img_hover
        )
        @bn_img.addEventListener("mouseout",=>
            @bn_img.style.cursor = "normal"
            @bn_img.src = @img_normal
            @stop_animation()
            if @show_animation then @normal_animation()
        )
        @bn_img.addEventListener("click",(e) =>
            e.stopPropagation()
            @bn_img.src = @img_press
            @cb?()
        )

    stop_animation: ->
        clearInterval(normal_interval)
        clearInterval(normal_hover_interval)
        #clearInterval(normal_press_interval)

    normal_animation: ->
        normal_interval = setInterval(=>
            @bn_img.src = @img_normal
        ,400)
        normal_hover_interval = setInterval(=>
            @bn_img.src = @img_hover
        ,500)
        #normal_press_interval = setInterval(=>
        #    @bn_img.src = @img_press
        #,600)

class MenuChoose extends Widget
    choose_num = -1
    select_state_confirm = false
    
    constructor: (@id)->
        super
        
        inject_css(@element,"css/menuchoose.css")
        @current = @id
        
        @option = []
        @option_disable = []
        @message_text = []
        @option_text = []
        @img_url_normal = []
        @img_url_hover = []
        @img_url_click = []

        @opt = []
        @opt_img = []
        @opt_text = []
        
        @element.style.display = "none"
    
    show:->
        @element.style.display = "-webkit-box"

    hide: ->
        for i in [@opt.length - 1..0]
            #delete select_state and then start animate
            @opt[i].style.backgroundColor = "rgba(255,255,255,0.0)"
            @opt[i].style.border = "1px solid rgba(255,255,255,0.0)"
            @opt[i].style.borderRadius = "0px"
            @normal_state[i]
        @element.style.display = "none"
    
    insert: (id, title, img_normal,img_hover,img_click,enable = true,message = null)->
        @option.push(id)
        @option_disable.push(id) if !enable
        @message_text.push(message)
        @option_text.push(title)
        @img_url_normal.push(img_normal)
        @img_url_hover.push(img_hover)
        @img_url_click.push(img_click)
    
    showMessage:(text)->
        @message_div?.style.display = "block"
        @message_div?.textContent = text
    
    hideMessage: ->
        @message_div?.style.display = "none"

    setOptionDefault:(option_id_default)->
        #this key must get From system
        GetinFromKey = false
        for tmp,i in @option
            if tmp is option_id_default
                if GetinFromKey
                    @select_state(i)
                else
                    choose_num = i
                    @hover_state(i)
                @opt[i].focus()

    message_div_build:->
        @message_div = create_element("div","message_div",@frame)
        @message_div.style.display = "none"


    frame_build: ->
        @frame = create_element("div", "frame", @element)
       
        @frame.addEventListener("click",(e)=>
            e.stopPropagation()
            @frame_click = true
        )
        @message_div_build()
        @button = create_element("div","button",@frame)
        
        for tmp ,i in @option_text
            @opt[i] = create_element("div","opt",@button)
            @opt[i].style.backgroundColor = "rgba(255,255,255,0.0)"
            @opt[i].style.border = "1px solid rgba(255,255,255,0.0)"
            @opt[i].value = i
            
            @opt_img[i] = create_img("opt_img",@img_url_normal[i],@opt[i])
            @opt_text[i] = create_element("div","opt_text",@opt[i])
            @opt_text[i].textContent = @option_text[i]
                
            @showMessage(@message_text[i])
            
            that = @
            #hover
            @opt[i].addEventListener("mouseover",->
                that.hover_state(this.value)
            )
            
            #normal
            @opt[i].addEventListener("mouseout",->
                that.normal_state(this.value)
            )

            #click
            @opt[i].addEventListener("click",(e)->
                e.stopPropagation()
                i = this.value
                that.frame_click = true
                that.click_state(i)
                that.current = that.option[i]
                #that.fade(i)
            )


    set_callback: (@cb)->

    fade:(i)->
        echo "--------------fade:#{@option[i]}---------------"
        @hide()
        @cb(@option[i], @option_text[i])

    normal_state:(i)->
        @opt_img[i].src = @img_url_normal[i]

    click_state:(i)->
        @opt_img[i].src = @img_url_click[i]

    hover_state:(i)->
        #choose_num = i
        if select_state_confirm then @select_state(i)
        for tmp,j in @opt_img
            if j == i
                tmp.src = @img_url_hover[i]
                @showMessage(@message_text[i])
            else tmp.src = @img_url_normal[j]
   
    select_state:(i)->
        select_state_confirm = true
        choose_num = i
        for tmp,j in @opt
            if j == i
                tmp.style.backgroundColor = "rgba(255,255,255,0.1)"
                tmp.style.border = "1px solid rgba(255,255,255,0.15)"
                tmp.style.borderRadius = "4px"
                @showMessage(@message_text[i])
            else
                tmp.style.backgroundColor = "rgba(255,255,255,0.0)"
                tmp.style.border = "1px solid rgba(255,255,255,0.0)"
                tmp.style.borderRadius = "0px"

    
    keydown:(e)->
        if @is_hide() then return
        echo "MenuChoose #{@id} keydown from choose_num:#{choose_num}"
        switch e.which
            when LEFT_ARROW
                choose_num--
                if choose_num == -1 then choose_num = @opt.length - 1
                @select_state(choose_num)
            when RIGHT_ARROW
                choose_num++
                if choose_num == @opt.length then choose_num = 0
                @select_state(choose_num)
            when ENTER_KEY
                i = choose_num
                @fade(i)
            when ESC_KEY
                destory_all()
        echo "to choose_num #{choose_num}}"
    
    is_hide:->
        if @element.style.display is "none" then return true
        else return false

    toggle:->
        if @is_hide() then @show()
        else @hide()



