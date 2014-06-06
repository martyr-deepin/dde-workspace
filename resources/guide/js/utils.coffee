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

simulate_input = (old_page,input_str,new_page_cls_name = null) ->
    #DCore.Guide.enable_keyboard()
    #DCore.Guide.set_focus(true)
    echo "input_str:#{input_str}"
    old_page.element.addEventListener("keydown", (e)->
        echo e.which
        switch e.which
            when KEYCODE.ESC_KEY and KEYCODE.WIN
                DCore.Guide.enable_guide_region()
            when KEYCODE.ENTER
                DCore.Guide.enable_guide_region()
                guide?.switch_page(old_page,new_page_cls_name) if new_page_cls_name? and old_page?
            else
                echo e
                input  = e.which
                DCore.Guide.disable_guide_region()
                setTimeout(=>
                    DCore.Guide.simulate_input(input)
                    DCore.Guide.enable_guide_region()
                    DCore.Guide.disable_right_click()
                ,20)
    )
    

body_hide = ->
    document.body.style.opacity = 0

body_show = ->
    document.body.style.opacity = 1


