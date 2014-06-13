
ESC_KEYSYM_TO_CODE = 0xff08

#launcher
COLLECT_LEFT = 110
COLLECT_WIDTH = screen.width - COLLECT_LEFT * 2
EACH_APP_HEIGHT = 120
EACH_APP_WIDTH = 120
EACH_APP_MARGIN_LEFT = 40
EACH_APP_MARGIN_TOP = 60

COLLECT_APP_NUMBERS = 10
COLLECT_APP_LINE_NUM = Math.ceil((COLLECT_APP_NUMBERS * EACH_APP_WIDTH + (COLLECT_APP_NUMBERS - 1) * EACH_APP_MARGIN_LEFT) / COLLECT_WIDTH)
COLLECT_HEIGHT = COLLECT_APP_LINE_NUM * EACH_APP_HEIGHT + (COLLECT_APP_LINE_NUM - 1) * EACH_APP_MARGIN_TOP
COLLECT_TOP = 84

CATE_TOP_DELTA = 5
CATE_LEFT = 27
CATE_NUMBERS = 7
CATE_EACH_HEIGHT = 62
CATE_EACH_WIDTH = 62
CATE_WIDTH = CATE_EACH_WIDTH
CATE_HEIGHT = CATE_EACH_HEIGHT * CATE_NUMBERS

#dock
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
t_mid_switch_page = 2000
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


enableZoneDetect = (enable) ->
    echo "enableZoneDetect :#{enable}"
    ZONE = "com.deepin.daemon.Zone"
    try
        zoneDBus = DCore.DBus.session(ZONE)
        zoneDBus?.EnableZoneDetected_sync(enable)
    catch e
        echo "zoneDBus #{ZONE} error : #{e}"

simulate_rightclick = (page,cb) ->
    DCore.Guide.enable_right_click()
    page.element.addEventListener("contextmenu",(e)->
        e.preventDefault()
        e.stopPropagation()
        echo "simulate_rightclick"
        DCore.Guide.disable_guide_region()
        setTimeout(=>
            DCore.Guide.simulate_click(CLICK_TYPE.rightclick)
            setTimeout(=>
                DCore.Guide.enable_guide_region()
                DCore.Guide.enable_right_click()
                cb?()
            ,500)
        ,200)
    )

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


white_key_list_num = [48...57]
white_key_list_char = [65...90]
white_key_list_spec_key = [KEYCODE.BACKSPACE]
white_key_list = []
white_key_list = white_key_list.concat(white_key_list_num,white_key_list_char,white_key_list_spec_key)


simulate_input = (modle_keysym,old_page,new_page_cls_name = null) ->
    #enableZoneDetect(true)
    modle_keysym_str = modle_keysym.toString()
    DCore.Guide.disable_keyboard()
    timeout_deepin = null
    deepin = 0
    input_keysym = []
    key_times = null
    backspace_times = null
    key_times_jump = null
    document.body.addEventListener("keyup", (e)->
        if guide?.current_page_id isnt "LauncherSearch" then return
        key_times++
        input = e.which
        if not (input in white_key_list) then return
        if input is KEYCODE.BACKSPACE
            input = ESC_KEYSYM_TO_CODE
            backspace_times++
            input_keysym.pop()
        else
            input_keysym.push(input)
        DCore.Guide.enable_keyboard()
        DCore.Guide.simulate_input(input)
        DCore.Guide.disable_keyboard()
        
        input_keysym_str = input_keysym.toString()
        length = input_keysym.length
        #echo "length:===#{length}==="
        if (key_times - backspace_times) != length
            echo "==========================="
            echo "key_times:#{key_times}"
            echo "backspace_times:#{backspace_times}"
            echo "length:#{length}"
            echo "key_times_jump:#{key_times - backspace_times - length}"
            input_keysym = []
            key_times = null
            backspace_times = null
            key_times_jump = null
            for i in [1...key_times]
                DCore.Guide.enable_keyboard()
                DCore.Guide.simulate_input(ESC_KEYSYM_TO_CODE)
                DCore.Guide.disable_keyboard()


            
        if input_keysym_str is modle_keysym_str
            deepin++
            echo "input_keysym_str is \"deepin\" #{deepin}!!!!!!!!!!!"
            DCore.Guide.disable_keyboard()
            clearTimeout(timeout_deepin)
            timeout_deepin = setTimeout(=>
                guide?.switch_page(old_page,new_page_cls_name)
            ,t_mid_switch_page)
    )
    

body_hide = ->
    document.body.style.opacity = 0

body_show = ->
    document.body.style.opacity = 1

each_item_update_times = 3
each_richdir_update_times = 1
desktop_file_numbers = 3


if DCore
    document.addEventListener('click',(e)->
            e.preventDefault()
            if e.target.tagName is "A"
                DCore.Guide.OpenUrl(e.target.href)
    ,false)

