#Copyright (c) 2011 ~ 2012 Deepin, Inc.
#              2011 ~ 2012 yilang
#
#Author:      bluth <yuanchenglu@linuxdeepin.com>
#             LongWei <yilang2007lw@gmail.com>
#                     <snyh@snyh.org>
#Maintainer:  bluth <yuanchenglu@linuxdeepin.com>
#
#This program is free software; you can redistribute it and/or modify
#it under the terms of the GNU General Public License as published by
#the Free Software Foundation; either version 3 of the License, or
#(at your option) any later version.
#
#This program is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.
#
#You should have received a copy of the GNU General Public License
#along with this program; if not, see <http://www.gnu.org/licenses/>.

class MenuChoose extends Widget
    choose_num = 0
    select_state_confirm = false

    #var for animation
    t_userinfo_show_hide = 600
    t_userinfo_show_delay = 500

    t_max = 200
    t_min = 100
    t_delay = 30

    XMove = -50
    XBack = 0
    XStartShow = 300
    XEndHide = 300

    init_width = 80 * 0.8
    final_width = 80

    constructor: (@id,@parent = document.body)->
        super
        menuchoose.push(@) if not (@ in menuchoose)
        inject_css(_b,"css/menuchoose.css")
        @from_enter = false
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
        @animation_end = true

        @element.style.display = "none"
        @element.style.position = "absolute"
        @element.style.zIndex = 30
        @parent.appendChild(@element)

    setPos:->
        left = (screen.width  - @element.clientWidth) / 2
        top = (screen.height  - @element.clientHeight) / 2 * 0.9
        @element.style.left = "#{left}px"
        @element.style.top = "#{top}px"
        XStartShow = (screen.width - left) - @element.clientWidth
        XEndHide = XStartShow

    show_direct: ->
        _current_user?.hide()
        $("#div_users").style.display = "none"
        @element.style.display = "-webkit-box"
        @animation_end = true

    show:->
        echo "show"
        if !@animation_end then return
        @animation_end = false
        animation_opt_text_show = (i)=>
            if i != @opt.length - 1 then return
            for tmp in @opt_text
                jQuery(tmp).animate(
                    {opacity:'1.0';},
                    t_min,
                    "linear",=>
                        @animation_end = true
                )


        animation_opt_move_show = (i,t_delay)=>
            text_el = @opt_text[i]
            img_el = @opt_img[i]
            opt_el = @opt[i]
            #init el css and then can animate
            text_el.style.opacity = "0.0"
            img_el.style.width = "#{init_width / 10}em"
            img_el.style.height = "#{init_width / 10}em"
            opt_el.style.opacity = "0.0"
            opt_el.style.left = XStartShow
            animation_scale(img_el,final_width / init_width,t_max)
            jQuery(opt_el).delay(t_delay).animate(
                {opacity: '1.0';left:XMove},
                t_max,
                'linear',=>
                    jQuery(opt_el).animate(
                        {left:XBack;},
                        t_min,
                        'linear',=>
                        animation_opt_text_show(i)
                    )
            )

        jQuery('.div_users').animate(
            {opacity:'0.0';},
            t_userinfo_show_hide,
            'linear',=>
                _current_user?.hide()
                $("#div_users").style.display = "none"
                @element.style.display = "-webkit-box"
                @setPos()
                for tmp,i in @opt
                    animation_opt_move_show(i,i * t_delay)
        )

    hide_direct: ->
        @animation_end = true
        @element.style.display = "none"
        _current_user?.show()
        $("#div_users").style.display = "-webkit-box"
        $("#div_users").style.opacity = 1.0

    hide: ->
        echo "hide"
        if !@animation_end then return
        @animation_end = false
        animation_user_show = (i)=>
            if i != 0 then return
            @element.style.display = "none"
            _current_user?.show()
            if @id is "user_menuchoose"
                if @frame_click or @from_enter
                    echo "hide switch_to_userinfo(#{@current})"
                    @from_enter = false
                    user?.switch_to_userinfo(@current)
            $("#div_users").style.display = "-webkit-box"
            jQuery('.div_users').delay(t_userinfo_show_delay).animate(
                {opacity:'1.0';},
                t_userinfo_show_hide,
                "linear",=>
                    @animation_end = true
            )

        animation_opt_move_hide = (i,t_delay)=>
            text_el = @opt_text[i]
            img_el = @opt_img[i]
            opt_el = @opt[i]

            jQuery(text_el).animate(
                {opacity:'0.0';},
                t_min,
                'linear',=>
                    jQuery(opt_el).animate(
                        {opacity:'0.5';left:XMove;},
                        t_min,
                        'linear',=>
                            time = (t_min + t_delay) / 2
                            animation_scale(img_el,1.0,time)
                            jQuery(opt_el).animate(
                                {opacity:'0.0';left:XEndHide;},
                                time,
                                'linear',=>
                                animation_user_show(i)
                            )
                    )
            )

        j = 0
        for i in [@opt.length - 1..0]
            #delete select_state and then start animate
            @opt[i].style.backgroundColor = "rgba(255,255,255,0.0)"
            @opt[i].style.border = "1px solid rgba(255,255,255,0.0)"
            @opt[i].style.borderRadius = "0px"
            j++
            animation_opt_move_hide(i,j * t_delay)


    insert: (id, title, img_normal,img_hover,img_click,enable,message = null)->
        @option.push(id)
        @option_disable.push(id) if !enable
        @message_text.push(message)
        @option_text.push(title)
        @img_url_normal.push(img_normal)
        @img_url_hover.push(img_hover)
        @img_url_click.push(img_click)

    body_click_to_hide:->
        document.body.addEventListener("click",(e)=>
            e.stopPropagation()
            if !@frame_click and @element.style.display isnt "none"
                echo "body_click_to_hide"
                @hide()
                $(".password")?.focus()
            else
                @frame_click = false
        )

    showMessage:(text)->
        if text is null or text is undefined
            return
        @message_div?.style.opacity = 1
        @message_text_div?.textContent = text

    hideMessage: ->
        @message_div.style.opacity = 0

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
        @message_div = create_element("div","message_div",@element)
        @message_img_div = create_element("div","message_img_div",@message_div)
        @message_img_div.style.backgroundImage = "url(images/waring.png)"
        @message_text_div = create_element("div","message_text_div",@message_div)
        @message_div.style.opacity = 0

    frame_build: ->
        @message_div_build()
        @frame = create_element("div", "frame", @element)
        @button = create_element("div","button",@frame)
        @frame.addEventListener("click",(e)=>
            e.stopPropagation()
            @frame_click = true
        )
        @body_click_to_hide()
        for tmp ,i in @option_text
            @opt[i] = create_element("div","opt",@button)
            @opt[i].style.backgroundColor = "rgba(255,255,255,0.0)"
            @opt[i].style.border = "1px solid rgba(255,255,255,0.0)"
            @opt[i].value = i
            @opt_img[i] = create_img("opt_img_m0",@img_url_normal[i],@opt[i])
            @opt_text[i] = create_element("div","opt_text",@opt[i])
            @opt_text[i].textContent = @option_text[i]
            that = @
            #hover
            @opt[i].addEventListener("mouseover",->
                that.hover_state(this.value)
            )
            #normal
            @opt[i].addEventListener("mouseout",->
                that.normal_state(this.value)
            )
            @opt[i].addEventListener("click",(e)->
                e.stopPropagation()
                i = this.value
                that.frame_click = true
                that.click_state(i)
                that.fade(i)
            )

        @check_disable_message()

    set_callback: (@cb)->

    fade:(i)->
        @current = @option[i]
        if @is_disable(i) then return
        echo "--------------fade:#{@current}---------------"
        @cb(@option[i], @option_text[i])
        @hide()

    check_disable_message: ->
        for bt,i in @opt
            @css_disable(i)
            @showMessage(@message_text[i])

    is_disable: (i) ->
        return (@option[i] in @option_disable)

    css_disable:(i)->
        disable = @is_disable(i)
        if disable is true
            @opt[i].disable = "true"
            @opt_img[i].style.opacity = "0.3"
            @opt[i].style.cursor = "default"
        else
            @opt[i].disable = "false"
            @opt_img[i].style.opacity = "1.0"
            @opt[i].style.cursor = "pointer"
        return disable

    normal_state:(i)->
        if @is_disable(i) then return
        @opt_img[i].src = @img_url_normal[i]

    click_state:(i)->
        if @is_disable(i) then return
        @opt_img[i].src = @img_url_click[i]

    hover_state:(i)->
        #choose_num = i
        if select_state_confirm then @select_state(i)
        @showMessage(@message_text[i])
        for tmp,j in @opt_img
            if j == i and !@is_disable(i) then tmp.src = @img_url_hover[i]
            else tmp.src = @img_url_normal[j]

    select_state:(i)->
        select_state_confirm = true
        choose_num = i
        @showMessage(@message_text[i])
        for tmp,j in @opt
            if j == i and !@is_disable(i)
                tmp.style.backgroundColor = "rgba(255,255,255,0.1)"
                tmp.style.border = "1px solid rgba(255,255,255,0.15)"
                tmp.style.borderRadius = "4px"
            else
                tmp.style.backgroundColor = "rgba(255,255,255,0.0)"
                tmp.style.border = "1px solid rgba(255,255,255,0.0)"
                tmp.style.borderRadius = "0px"

    keydown:(e)->
        if @is_hide() then return
        echo "MenuChoose #{@id} keydown from choose_num:#{choose_num}"
        GetinFromKey = true
        switch e.which
            when LEFT_ARROW
                choose_num = choose_num - 1
                if choose_num < 0 then choose_num = @opt.length - 1
                @select_state(choose_num)
            when RIGHT_ARROW
                choose_num = choose_num + 1
                if choose_num > @opt.length - 1 then choose_num = 0
                @select_state(choose_num)
            when ENTER_KEY
                @from_enter = true
                @fade(choose_num)
            when ESC_KEY
                destory_all()
        echo "to choose_num #{choose_num}"

    is_hide:->
        if @element.style.display is "none" then return true
        else return false

    toggle:->
        if @is_hide() then @show()
        else @hide()


class UserMenuChoose extends MenuChoose
    t_usermenu = 500
    t_text_show = 500

    constructor: (@id,@parent = document.body)->
        super(@id,@parent)
        @moveX = []
        @img_div = []
        @current = _current_user.id

    frame_build: ->
        @frame = create_element("div", "frame", @element)
        @button = create_element("div","button",@frame)
        @frame.addEventListener("click",(e)=>
            e.stopPropagation()
            @frame_click = true
        )
        @body_click_to_hide()
        for tmp ,i in @option_text
            @opt[i] = create_element("div","opt",@button)
            @opt[i].style.backgroundColor = "rgba(255,255,255,0.0)"
            @opt[i].style.border = "1px solid rgba(255,255,255,0.0)"
            @opt[i].value = i
            @img_div[i] = create_element("div","img_div",@opt[i])
            img_border = create_element("div","img_border",@img_div[i])
            img_background = create_element("div","img_background",img_border)
            @opt_img[i] = create_img("opt_img_m1", @img_url_normal[i], img_background)

            @opt_text[i] = create_element("div","opt_text_user",@opt[i])
            @opt_text[i].textContent = @option_text[i]
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
                that.fade(i)
            )
        @element.style.display = "none"

    opt_pos_init: ->
        @final_width = 120
        @element.style.display = "-webkit-box"
        for opt,i in @opt
            @left = (screen.width  - 250) / 2 + 53
            @top = (screen.height  - 180) / 2 * 0.8 - 19
            opt.style.position = "fixed"
            opt.style.padding = "20px 10px 20px 10px"
            opt.style.left = @left
            opt.style.top = @top
        console.debug "MenucChoose.opt:left:#{@left},top:#{@top}"
        @element.style.display = "none"

    show:->
        echo "show_usermenu========="
        @opt_pos_init()
        if !@animation_end then return
        @animation_end = false
        $('#div_users').style.display = "none"
        _current_user?.hide()
        @element.style.display = "-webkit-box"
        OPT_MARGIN = 30
        center_index = Math.round((@opt.length - 1) / 2)
        for opt,i in @opt
            @moveX[i] = (@final_width + OPT_MARGIN) * (i - center_index)
            if @opt.length % 2 == 0
                @moveX[i] += (@final_width + OPT_MARGIN * 2) / 2
            console.log "#{i}===moveX:#{@moveX[i]}"
            if @option[i] is @current
                console.debug "@current:#{_current_user.username}"
                opt.style.zIndex = 40
                opt.style.opacity = "1.0"
                jQuery(opt).animate(
                    {
                        left:"+=#{@moveX[i]}px"
                    },t_usermenu)
                animation_scale(@img_div[i],0.8,t_usermenu)
            else
                opt.style.zIndex = 30
                opt.style.opacity = "0"
                jQuery(opt).animate(
                    {
                        opacity:"1.0"
                        left:"+=#{@moveX[i]}px"
                    },t_usermenu)
                animation_scale(@img_div[i],0.8,1)
            @opt_text[i].style.opacity = 0
            jQuery(@opt_text[i]).animate({opacity:1},t_usermenu)
        setTimeout(=>
            @animation_end = true
        ,t_usermenu)

    hide:->
        echo "hide_usermenu========="
        if !@animation_end then return
        @animation_end = false
        if @frame_click or @from_enter
           @from_enter = false
           user?.set_current_userinfo(@current)
        @element.style.display = "-webkit-box"
        $('#div_users').style.display = "-webkit-box"
        _current_user?.show()
        _current_user.userbase.style.opacity = 0
        _current_user.login.element.style.opacity = 0

        for opt,i in @opt
            opt.style.backgroundColor = "rgba(255,255,255,0.0)"
            opt.style.border = "1px solid rgba(255,255,255,0.0)"
            opt.style.borderRadius = "0px"
            console.log "#{i}===moveX:#{@moveX[i]}"
            if @option[i] is @current
                console.debug "@current:#{_current_user.username}"
                opt.style.zIndex = 40
                opt.style.opacity = "1.0"
                animation_scale(@img_div[i],1,t_usermenu)
                jQuery(opt).animate(
                    {
                        left:"-=#{@moveX[i]}px"
                    },t_usermenu)
                jQuery(@opt_text[i]).animate(
                    {
                        opacity:0
                    },t_usermenu + t_text_show)
                jQuery(_current_user.login.element).animate({opacity:1},t_usermenu + 200)
            else
                opt.style.zIndex = 30
                jQuery(@opt_text[i]).animate({opacity:0},t_usermenu)
                opt.style.opacity = "1.0"
                jQuery(opt).animate(
                    {
                        opacity:"0.0"
                        left:"-=#{@moveX[i]}px"
                    },t_usermenu)
        setTimeout(=>
            @animation_end = true
            setTimeout(=>
                @element.style.display = "none"
            ,t_text_show)
            $('#div_users').style.display = "-webkit-box"
            console.debug "_current_user?.show();#{_current_user.username}"
            _current_user?.show()
            _current_user.userbase.style.opacity = 1
            _current_user.username_div.style.opacity = 0
            jQuery(@opt_text[i]).animate({fontSize:"1.6em"},t_text_show,"linear",=>
            )
            jQuery(_current_user.username_div).animate({opacity:1},t_text_show)
        ,t_usermenu)


class ComboBox extends Widget
    constructor: (@id, @on_click_cb) ->
        super
        @current_img = create_img("current_img", "", @element)
        if @id == "user"
            @menu = new UserMenuChoose("#{@id}_menuchoose")
        else
            @menu = new MenuChoose("#{@id}_menuchoose")
        @menu.set_callback(@on_click_cb)

    insert: (id, title, img_normal,img_hover,img_click,can_exe = true,message_text = null)->
        @menu.insert(id, title, img_normal,img_hover,img_click,can_exe,message_text)

    frame_build: ->
        @menu.frame_build()

    showMessage:(msg)->
        @menu.showMessage(msg)


    insert_noimg: (id, title)->
        @menu.insert_noimg(id, title)

    only_show_current_Menuchoose: ->
       echo "only_show_current_Menuchoose"
       for menu in menuchoose
           if menu?.id isnt @id
               menu?.hide_direct()

    do_click: (e)->
        e.stopPropagation()
        echo "current_img do_click:#{@id}"
        if !@menu.is_hide() then return
        @only_show_current_Menuchoose()
        @menu.toggle()

    hide:->
        @element.style.display = "none"

    show:->
        @element.style.display = "block"

    is_hide:->
        if @element.style.display == "none" then return true
        else return false

    get_current: ->
        @menu_current_id = localStorage.getItem("menu_current_id_#{@id}")
        @menu.current = @menu_current_id
        return @menu.current

    currentTextShow: ->
        @current_text = create_element("div","current_text",@element) if not @current_text?
        @menu_current_id = localStorage.getItem("menu_current_id_#{@id}")
        @current_text.textContent = @menu_current_id
        @current_text.style.display = "block"
        XInit = -30
        XMove = 15
        @current_text.style.opacity = "0.0"
        @current_text.style.right = XInit
        t = 100
        mouseenter = =>
            @menu_current_id = localStorage.getItem("menu_current_id_#{@id}")
            @current_text.textContent = @menu_current_id
            jQuery(@current_text).animate(
                {opacity:'1.0';right:XMove;},t
            )
        mouseleave = =>
            jQuery(@current_text).animate(
                {opacity:'0.0';right:XInit;},t
            )
        jQuery(@element).hover(mouseenter,mouseleave)


    set_current: (current)->
        #@menu.current = current
        @current_text?.textContent = current
        localStorage.setItem("menu_current_id_#{@id}",current)
        return current

