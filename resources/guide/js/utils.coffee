DEBUG = DCore.Guide.is_debug()

move_mouse = (x,y,relative = false) ->
    cmd = null
    if relative
        cmd = "/usr/bin/xdotool mousemove_relative #{x} #{y}"
    else
        cmd = "/usr/bin/xdotool mousemove #{x} #{y}"
    DCore.Guide.spawn_command_sync(cmd,false)


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

simulate_input = (old_page,new_page_cls_name = null) ->
    DCore.Guide.disable_keyboard()
    timeout_deepin = null
    input_keysym = []
    document.body.addEventListener("keyup", (e)->
        if guide?.current_page_id isnt "LauncherSearch" then return
        input = e.which
        if not (input in white_key_list) then return
        if input is KEYCODE.BACKSPACE
            input = ESC_KEYSYM_TO_CODE
            DCore.Guide.simulate_input(input)
            input_keysym.pop() if input_keysym.length != 0
        else
            input_keysym.push(input)
            DCore.Guide.simulate_input(input)
        if timeout_deepin == null
            timeout_deepin = setTimeout(->
                guide?.switch_page(old_page,new_page_cls_name)
            ,t_switch_page)
    )

body_hide = ->
    document.body.style.opacity = 0

body_show = ->
    document.body.style.opacity = 1


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
