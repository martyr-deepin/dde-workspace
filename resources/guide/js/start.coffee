#Copyright (c) 2011 ~ 2014 Deepin, Inc.
#              2011 ~ 2014 bluth
#
#encoding: utf-8
#Author:      bluth <yuanchenglu@linuxdeepin.com>
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
        echo "show"
        @element.style.display = "-webkit-box"

    hide: ->
        echo "hide"
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
                that.fade(i)
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





class Start extends Widget
    constructor:(@id)->
        super
        echo "Start #{@id}"
        
        inject_css(@element,"css/start.css")
        @option = ["launcher","desktop","dss"]
        @option_text = [_("New Launcher"),_("New Desktop"),_("New System Settings")]
        @message_text = _("We will guide you to learn how to use some new functions")
        @img_before = "img/"

        @guide_choose_build()

    guide_choose_build : ->
        @guide_choose = create_element("div","guide_choose",@element)
        @menu = new MenuChoose("guide_menu")
        for option,i in @option
            icon_path_normal = @img_before + "#{option}_normal.png"
            icon_path_hover = @img_before + "#{option}_hover.png"
            icon_path_press = @img_before + "#{option}_press.png"
            @menu.insert(option, @option_text[i], icon_path_normal,icon_path_hover,icon_path_press,true,@message_text)
        @menu.frame_build()
        @menu.show()
        @guide_choose.appendChild(@menu.element)
   
        @start_div = create_element("div","start_div",@guide_choose)
        @start_text = create_element("div","start_text",@start_div)
        @start_text.innerText = _("Start")
        @start_img = create_img("start_img","#{@img_before}/start_normal.png",@start_div)
        @start_img.addEventListener("mouseover",=>
            @start_img.src = "#{@img_before}/start_hover.png"
        )
        @start_img.addEventListener("mouseout",=>
            @start_img.src = "#{@img_before}/start_normal.png"
        )
        @start_img.addEventListener("click",(e) =>
            e.stopPropagation()
            @start_img.src = "#{@img_before}/start_press.png"
            #TODO:switch_to_page(launcher_page)
        )
        
        @older = create_element("div","older",@element)
        @older.innerText = _("I am older,exit directly")

        #set_pos_center(@guide_choose,0.6)
