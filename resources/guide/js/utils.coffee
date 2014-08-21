DEBUG = false
ESC_KEYSYM_TO_CODE = 0xff08

primary_info =
    x:0
    y:0
    width:1366
    height:768

#launcher
COLLECT_LEFT = 110
EACH_APP_HEIGHT = 120
EACH_APP_WIDTH = 120
EACH_APP_MARGIN_LEFT = 40
EACH_APP_MARGIN_TOP = 60

COLLECT_APP_NUMBERS = 10
COLLECT_TOP = 84

CATE_TOP_DELTA = 5
CATE_LEFT = 27
CATE_NUMBERS = 7
CATE_EACH_HEIGHT = 62
CATE_EACH_WIDTH = 62
CATE_WIDTH = CATE_EACH_WIDTH
CATE_HEIGHT = CATE_EACH_HEIGHT * CATE_NUMBERS

#dock
COLLECT_WIDTH = primary_info.width - COLLECT_LEFT * 2
COLLECT_APP_LINE_NUM = Math.ceil((COLLECT_APP_NUMBERS * EACH_APP_WIDTH + (COLLECT_APP_NUMBERS - 1) * EACH_APP_MARGIN_LEFT) / COLLECT_WIDTH)
COLLECT_HEIGHT = COLLECT_APP_LINE_NUM * EACH_APP_HEIGHT + (COLLECT_APP_LINE_NUM - 1) * EACH_APP_MARGIN_TOP

DOCK_PADDING = 24
ICON_MARGIN_H = 7
ICON_MARGIN_V_TOP = 3
ICON_MARGIN_V_BOTTOM = 10
ICON_SIZE = 48
POINTER_AREA_SIZE = 64

EACH_ICON = ICON_MARGIN_H + ICON_SIZE

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
t_check_if_done = 10000

POS_TYPE =
    leftup:"leftup"
    leftdown:"leftdown"
    rightup:"rightup"
    rightdown:"rightdown"
    down:"down"
    up:"up"

set_pos = (el,x,y,position_type = "absolute",type = POS_TYPE.leftup)->
    el.style.position = "absolute"
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
    DCore.Guide.disable_keyboard()
    timeout_deepin = null
    input_keysym = []
    modle_keysym_finish = false
    document.body.addEventListener("keyup", (e)->
        if guide?.current_page_id isnt "LauncherSearch" then return
        if modle_keysym_finish then return
        input = e.which
        echo input
        if not (input in white_key_list) then return
        if input is KEYCODE.BACKSPACE
            input = ESC_KEYSYM_TO_CODE
            DCore.Guide.simulate_input(input)
            input_keysym.pop() if input_keysym.length != 0
        else
            input_keysym.push(input)
            DCore.Guide.simulate_input(input)
        if input_keysym.toString() is modle_keysym.toString()
            echo "input_keysym finish!!!!!!!!!!!"
            modle_keysym_finish = true
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
desktop_file_numbers = 2


if DCore
    document.addEventListener('click',(e)->
            e.preventDefault()
            if e.target.tagName is "A"
                DCore.Guide.OpenUrl(e.target.href)
    ,false)


set_center = (el,w,h,x_scale = 1,y_scale = 0.8) ->
    top = (primary_info.height  - h) / 2 * y_scale
    left = (primary_info.width  - w) / 2 * x_scale
    el.style.position = "absolute"
    el.style.top = "#{top}px"
    el.style.left = "#{left}px"


show_webinspector = ->
    DCore.Guide.disable_keyboard()
    document.body.addEventListener("keyup", (e)->
        key = e.which
        if key is KEYCODE.F12
            DCore.Guide.disable_guide_region()
            DCore.Guide.enable_keyboard()
            #document.body.style.background = "rgba(0,0,0,0.0)"
    )


shadow_light = (el,type = "circle") ->
    document.body.style.background = "rgba(0,0,0,0.0)"
    #遮罩效果
    cover = create_element("span","text_cover_tans",guide?.element)
    cover.style.width =  el.style.width
    cover.style.height =  el.style.width
    cover.style.position = "absolute"
    cover.style.left =  el.offsetLeft
    cover.style.top =  el.offsetTop
    guide.element.style.overflow = "hidden"
    border_width = primary_info.width
    cover.style.border = "#{border_width}px solid rgba(0,0,0,0.3)"
    cover.style.borderRadius = "50%" if type is "circle"
    cover.style.borderRadius = "1" if type is "rect"


move_animation = (el,y0,y1,type = "top",pos = "absolute",cb) ->
    el.style.display = "block"
    el.style.position = pos
    t_show = 1000
    pos0 = null
    pos1 = null
    animate_init = ->
        switch type
            when "top"
                el.style.top = y0
                pos0 = {top:y0}
                pos1 = {top:y1}
            when "bottom"
                el.style.bottom = y0
                pos0 = {bottom:y0}
                pos1 = {bottom:y1}
    animate_init()
    jQuery(el).animate(
        pos1,t_show,"linear",=>
            animate_init()
            jQuery(el).animate(pos1,t_show,"linear",cb?())
    )
