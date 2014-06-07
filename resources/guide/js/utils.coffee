DOCK_PADDING = 24
ICON_MARGIN_H = 7
ICON_MARGIN_V_TOP = 3
ICON_MARGIN_V_BOTTOM = 10
ICON_SIZE = 48

EACH_ICON = ICON_MARGIN_H + ICON_SIZE
        
POS_TYPE =
    leftup:"leftup"
    leftdown:"leftdown"
    rightup:"rightup"
    rightdown:"rightdown"
    down:"down"
    up:"up"

AREA_TYPE =
    circle:"circle"
    circle_white:"circle_white"
    corner:"corner"

CLICK_TYPE =
    leftclick:1
    copy:2
    rightclick:3
    scrollup:4
    scrolldown:5


pages_id = [
    "Welcome",
    "Start",
    "LauncherLaunch",
    "LauncherCollect",
    "LauncherAllApps",
    "LauncherScroll"
]

t_switch_page = 4000
t_min_switch_page = 500

set_pos = (el,x,y,position_type = "fixed",type = POS_TYPE.leftup)->
    el.style.position = position_type
    switch type
        when POS_TYPE.leftup
            el.style.left = x
            el.style.top = y
        when POS_TYPE.leftdown
            el.style.left = x
            el.style.bottom = y
        when POS_TYPE.rightup
            el.style.right = x
            el.style.top = y
        when POS_TYPE.rightdown
            el.style.right = x
            el.style.bottom = y
        else
            el.style.left = x
            el.style.top = y
#-------------------------------------------

zoneDBus = null
enableZoneDetect = (enable) ->
    echo "enableZoneDetect :#{enable}"
    ZONE = "com.deepin.daemon.Zone"
    try
        zoneDBus = DCore.DBus.session(ZONE)
        zoneDBus?.EnableZoneDetected_sync(enable)
    catch e
        echo "zoneDBus #{ZONE} error : #{e}"
 #-------------------------------------------

simulate_click = (type,old_page = null,new_page_cls_name = null) ->
    DCore.Guide.disable_guide_region()
    setTimeout(=>
        DCore.Guide.simulate_click(type)
        DCore.Guide.enable_guide_region()
        if type is CLICK_TYPE.rightclick
            DCore.Guide.enable_right_click()
        else
            DCore.Guide.disable_right_click()
        guide?.switch_page(old_page,new_page_cls_name) if new_page_cls_name? and old_page?
    ,20)


black_key_list = [
    KEYCODE.ESC,
    KEYCODE.WIN,
    KEYCODE.ENTER
]


deepin_keysym = [68,69,69,80,73,78]
deepin_keysym_str = deepin_keysym.toString()
timeout_deepin = null
input_keysym = []

simulate_input = (old_page,modle_keysym,new_page_cls_name = null) ->
    document.body.addEventListener("keydown", (e)->
        echo e.which
        if e.which in black_key_list
            echo "black_key_list key :#{e.which}"
        else if e.which is KEYCODE.BACKSPACE
            if input_keysym.length > 0 then input_keysym.pop()
        else
            input = e.which
            input_keysym.push(input)
            input_keysym_str = input_keysym.toString()
            DCore.Guide.disable_guide_region()
            setTimeout(=>
                DCore.Guide.enable_keyboard()
                DCore.Guide.simulate_input(input)
                DCore.Guide.enable_guide_region()
                DCore.Guide.disable_keyboard()
            ,2)
            
            if input_keysym_str.indexOf(deepin_keysym_str) == 0
                echo "deepin_keysym_str:#{deepin_keysym_str}"
                clearTimeout(timeout_deepin)
                timeout_deepin = setTimeout(=>
                    guide?.switch_page(old_page,new_page_cls_name)
                ,t_switch_page)
    )
    

body_hide = ->
    document.body.style.opacity = 0

body_show = ->
    document.body.style.opacity = 1


