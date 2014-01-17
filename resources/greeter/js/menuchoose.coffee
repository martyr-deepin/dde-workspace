#Copyright (c) 2012 ~ 2013 Deepin, Inc.
#              2012 ~ 2013 bluth
#
#encoding: utf-8
#Author:      bluth <\yuanchenglu@linuxdeepin.com>
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
    opt = []
    img_url = []
    opt_img = []
    opt_text = []
    choose_num = -1
    select_state_confirm = false
   
    option = []
    option_text = []
    img_url = []
    frame_click = true

    constructor: (@id)->
        super
        @current = @id
        @element.style.display = "none"


    destory:->
        document.body.removeChild(@element)
    
    show:(x,y)->
        document.body.appendChild(@element)
        @element.style.position = "absolute"
        @element.style.left = x
        @element.style.top = y
        @element.style.display = "block"

    hide:->
        @element.style.display = "none"

    insert: (id, title, img)->
        option.push(id)
        option_text.push(title)
        img_url.push(img)
    
    frame_build:(id,title,img)->
        frame = create_element("div", "frame", @element)
        button = create_element("div","button",frame)
       
        frame.addEventListener("click",->
            frame_click = true
        )
#        document.body.addEventListener("click",=>
            #if !frame_click
                #@destory()
            #frame_click = false
        #)
        
        for tmp ,i in option
            opt[i] = create_element("div","opt",button)
            opt[i].style.backgroundColor = "rgba(255,255,255,0.0)"
            opt[i].style.border = "1px solid rgba(255,255,255,0.0)"
            opt[i].value = i
            opt_img[i] = create_img("opt_img",img_url[i],opt[i])
            opt_text[i] = create_element("div","opt_text",opt[i])
            opt_text[i].textContent = option_text[i]

            that = @
            #hover
            opt[i].addEventListener("mouseover",->
                i = this.value
                choose_num = i
                that.hover_state(i)
            )
            
            #normal
            opt[i].addEventListener("mouseout",->
                i = this.value
                opt_img[i].src = "img/normal/#{option[i]}.png"
            )

            #click
            opt[i].addEventListener("mousedown",->
                i = this.value
                opt_img[i].src = "img/click/#{option[i]}.png"
            )
            opt[i].addEventListener("click",->
                i = this.value
                frame_click = true
                opt_img[i].src = "img/click/#{option[i]}.png"
                that.fade(i)
                @cb(option[i], option_text[i])
            )
    
    set_callback: (@cb)->
     
    show_confirm_message:(i) ->
        @destory()
        confirm_message = _("please input password to 1% your computer",option[i])

        
    switchToConfirmDialog:(i)->
        opt[i].style.backgroundColor = "rgba(255,255,255,0.0)"
        opt[i].style.border = "1px solid rgba(255,255,255,0.0)"
        opt[i].style.borderRadius = null
        time = 0.5
        for el,j in opt
            apply_animation(el,"fade_animation#{j}","#{time}s")
        opt[i].addEventListener("webkitAnimationEnd",=>
            @show_confirm_message(i)
        ,false)
 

    fade:(i)->
        echo "--------------fade:#{option[i]}---------------"
        if is_greeter
            echo "is greeter"
            power_force(option[i])
        else
            if power_can(option[i])
                echo "power_can true ,power_request"
                power_request(option[i])
            else
                echo "power_can false ,switchToConfirmDialog"
                @switchToConfirmDialog(i)

    hover_state:(i)->
        choose_num = i
        if select_state_confirm then @select_state(i)
        for tmp,j in opt_img
            if j == i then tmp.src = "img/hover/#{option[i]}.png"
            else tmp.src = "img/normal/#{option[j]}.png"
   
    select_state:(i)->
        select_state_confirm = true
        choose_num = i
        for tmp,j in opt
            if j == i
                tmp.style.backgroundColor = "rgba(255,255,255,0.1)"
                tmp.style.border = "1px solid rgba(255,255,255,0.15)"
                tmp.style.borderRadius = "4px"
            else
                tmp.style.backgroundColor = "rgba(255,255,255,0.0)"
                tmp.style.border = "1px solid rgba(255,255,255,0.0)"
                tmp.style.borderRadius = null

    
    keydown:(keyCode)->
        switch keyCode
            when LEFT_ARROW
                choose_num--
                if choose_num == -1 then choose_num = 4
                @select_state(choose_num)
            when RIGHT_ARROW
                choose_num++
                if choose_num == 5 then choose_num = 0
                @select_state(choose_num)
            when ENTER_KEY
                i = choose_num
                if 2 <= i <= 4 then @fade(i)
                else if 0 <= i <= 1 then confirm_ok(option[i])
            when ESC_KEY
                destory_all()

