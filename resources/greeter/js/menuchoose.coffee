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
    choose_num = -1
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
    
    constructor: (@id)->
        super
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
        
        document.body.style.fontSize = "62.5%"
        document.body.appendChild(@element)
        @element.style.display = "none"
    
    setPos:->
        left = (screen.width  - @element.clientWidth) / 2
        top = (screen.height  - @element.clientHeight) / 2 * 0.9
        @element.style.left = "#{left}px"
        @element.style.top = "#{top}px"
        XStartShow = (screen.width - left) - @element.clientWidth
        XEndHide = XStartShow
    
    show:->
        echo "show"
        
        @animation_end = false
        animation_opt_text_show = (i)=>
            if i != @opt.length - 1 then return
            #echo "opt_text[#{i}] show"
            for tmp in @opt_text
                jQuery(tmp).animate(
                    {opacity:'1.0';},
                    t_min,
                    "linear",=>
                        @animation_end = true
                )


        animation_opt_move_show = (i,t_delay)=>
            #echo "animation_opt_move_show(#{i})"
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
                $("#div_users").style.display = "none"
                @element.style.display = "-webkit-box"
                @setPos()
                for tmp,i in @opt
                    animation_opt_move_show(i,i * t_delay)
        )


   
    hide:->
        echo "hide"
        
        @animation_end = false
        
        animation_user_show = (i)=>
            if i != 0 then return
            echo "animation_user_show(#{i})"
            @element.style.display = "none"
            $("#div_users").style.display = "-webkit-box"
            jQuery('.div_users').delay(t_userinfo_show_delay).animate(
                {opacity:'1.0';},
                t_userinfo_show_hide,
                "linear",=>
                    @animation_end = true
            )

        animation_opt_move_hide = (i,t_delay)=>
            #echo "animation_opt_move_hide(#{i})"
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
                            #echo "opt_el[#{i}] Move From #{opt_el.style.left} To #{XEndHide}"
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


    insert: (id, title, img_normal,img_hover,img_click,disable = false,message = null)->
        @option.push(id)
        @option_disable.push(id) if disable
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
                if !@animation_end then return
                @hide()
                $(".password").focus()
            else
                @frame_click = false
        )
    
    showMessage:(text)->
        @message_div?.style.display = "-webkit-box"
        @message_text_div?.textContent = text
    
    hideMessage: ->
        @message_div?.style.display = "none"

    setOptionDefault:(option_default)->
        #this key must get From system
        GetinFromKey = false
        for tmp,i in @option
            if tmp is option_default
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
        @message_div.style.display = "none"

    frame_build:(id,title,img)->
        @frame = create_element("div", "frame", @element)
        @button = create_element("div","button",@frame)
       
        @frame.addEventListener("click",(e)=>
            e.stopPropagation()
            @frame_click = true
        )
        @body_click_to_hide()
        @message_div_build()
        
        for tmp ,i in @option
            @opt[i] = create_element("div","opt",@button)
            @opt[i].style.backgroundColor = "rgba(255,255,255,0.0)"
            @opt[i].style.border = "1px solid rgba(255,255,255,0.0)"
            @opt[i].value = i
            
            @opt_img[i] = create_img("opt_img",@img_url_normal[i],@opt[i])
            @opt_text[i] = create_element("div","opt_text",@opt[i])
            @opt_text[i].textContent = @option_text[i]
                
            @check_disable_state(i)
            
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
                that.fade(i)
            )


    set_callback: (@cb)->

    fade:(i)->
        echo "--------------fade:#{@option[i]}---------------"
        @hide()
        @cb(@option[i], @option_text[i])

    
    is_disable: (option) ->
        if @option_disable.length == 0 then return false
        if option in @option_disable then return true
        else return false

    check_disable_state:(i)->
        disable = @is_disable(@option[i])
        if disable is true
            @opt[i].disable = "true"
            #@opt[i].disable = "disable"
            @opt[i].style.opacity = "0.3"
            @opt[i].style.cursor = "default"
            @showMessage(@message_text[i])
        else
            @opt[i].disable = "false"
            @opt[i].style.opacity = "1.0"
            @opt[i].style.cursor = "pointer"
            @hideMessage()
        return disable
    
    normal_state:(i)->
        @check_disable_state(i)
        @opt_img[i].src = @img_url_normal[i]

    click_state:(i)->
        if @check_disable_state(i) then return
        @opt_img[i].src = @img_url_click[i]

    hover_state:(i)->
        if @check_disable_state(i) then return
        #choose_num = i
        if select_state_confirm then @select_state(i)
        for tmp,j in @opt_img
            if j == i then tmp.src = @img_url_hover[i]
            else tmp.src = @img_url_normal[j]
   
    select_state:(i)->
        if @check_disable_state(i) then return
        select_state_confirm = true
        choose_num = i
        for tmp,j in @opt
            if j == i
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


class ComboBox extends Widget
    constructor: (@id, @on_click_cb) ->
        super
        @current_img = create_img("current_img", "", @element)
        
        @menu = new MenuChoose("#{@id}_menuchoose")
        @menu.set_callback(@on_click_cb)

    insert: (id, title, img_normal,img_hover,img_click)->
        @menu.insert(id, title, img_normal,img_hover,img_click)
    
    frame_build:->
        @menu.frame_build()
    
    showMessage:(msg)->
        @menu.showMessage(msg)


    insert_noimg: (id, title)->
        @menu.insert_noimg(id, title)
    
    do_click: (e)->
        e.stopPropagation()
        echo "current_img do_click:#{@id}"
        if is_greeter
            try
                if @menu.id is "power_menuchoose"
                    $("#desktop_menuchoose")?.style.display = "none"
                else if @menu.id is "desktop_menuchoose"
                    #if _current_user?.is_logined then return
                    $("#power_menuchoose")?.style.display = "none"
            catch e
                echo "#{e}"
        if !@menu.animation_end then return
        @menu.toggle()
    
    hide:->
        @element.style.display = "none"

    show:->
        @element.style.display = "block"
    
    is_hide:->
        if @element.style.display = "none" then return true
        else return false

    get_current: ->
        menu_current_id = localStorage.getItem("menu_current_id")
        @menu.current = menu_current_id
        return @menu.current

    currentTextShow: ->
        @current_text = create_element("div","current_text",@element) if not @current_text?
        
        menu_current_id = localStorage.getItem("menu_current_id")
        @current_text.textContent = menu_current_id
        @current_text.style.display = "block"
        
        XInit = -30
        XMove = 15
        @current_text.style.opacity = "0.0"
        @current_text.style.right = XInit
        t = 100
        mouseenter = =>
            menu_current_id = localStorage.getItem("menu_current_id")
            @current_text.textContent = menu_current_id
            jQuery(@current_text).animate(
                {opacity:'1.0';right:XMove;},t
            )
        mouseleave = =>
            jQuery(@current_text).animate(
                {opacity:'0.0';right:XInit;},t
            )
        jQuery(@element).hover(mouseenter,mouseleave)


    set_current: (current)->
        current = current.toLowerCase()
        @menu.current = current
        @current_text?.textContent = current

        localStorage.setItem("menu_current_id",current)
        return current

