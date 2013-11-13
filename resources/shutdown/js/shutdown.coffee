#Copyright (c) 2011 ~ 2012 Deepin, Inc.
#              2011 ~ 2012 snyh
#
#Author:      Cole <phcourage@gmail.com>
#Maintainer:  Cole <phcourage@gmail.com>
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

frame_click = false
option = ["lock","suspend","logout","restart","shutdown"]
timeId = null

destory_all = ->
    clearInterval(timeId) if timeId
    DCore.Shutdown.quit()

document.body.addEventListener("click",->
    if !frame_click
        echo "right click body"
        destory_all()
    frame_click = false
    )

class ShutDown extends Widget
    opt = []
    img_url = []
    opt_img = []
    opt_text = []
    
    constructor: (@id)->
        super
        echo "shutdown"

    destory:->
        document.body.removeChild(@element)

    frame_build:->
        frame = create_element("div", "frame", @element)
        button = create_element("div","button",frame)
       
        frame.addEventListener("click",->
            frame_click = true
        )

        
        for tmp ,i in option
            opt[i] = create_element("div","opt",button)
            opt[i].value = i
            img_url[i] = "img/normal/#{option[i]}.png"
            opt_img[i] = create_img("opt_img",img_url[i],opt[i])
            opt_text[i] = create_element("div","opt_text",opt[i])
            opt_text[i].textContent = option[i]

            that = @
            #hover
            opt[i].addEventListener("mouseover",->
                i = this.value
                opt_img[this.value].src = "img/hover/#{option[i]}.png"
            )
            
            #normal
            opt[i].addEventListener("mouseout",->
                i = this.value
                opt_img[this.value].src = "img/normal/#{option[i]}.png"
            )

            #click
            opt[i].addEventListener("mousedown",->
                i = this.value
                #echo "#{i}:mousedown"
                opt_img[this.value].src = "img/click/#{option[i]}.png"
            )
            opt[i].addEventListener("click",->
                i = this.value
                frame_click = true
                #echo "#{i}:click"
                opt_img[this.value].src = "img/click/#{option[i]}.png"
                if 2 <= i <= 4 then that.fade(i)
                else
                     echo "option[i]:click to #{option[i]}."
                
            )
    
    timefunc:(i) ->
        #echo "timefunc"
        @destory()
        confirmdialog = new ConfirmDialog(i)
        confirmdialog.frame_build()
        document.body.appendChild(confirmdialog.element)
        confirmdialog.interval(60)
        confirmdialog.key()

    fade:(i)->
        time = 0.5
        for el,j in opt
            apply_animation(el,"fade_animation#{j}","#{time}s")
        opt[i].addEventListener("webkitAnimationEnd",=>
            @timefunc(i)
        ,false)
    
    key:->
        @element.addEventListener("keydown", (e)=>
            if e.which == LEFT_ARROW
                echo "prev"

            else if e.which == RIGHT_ARROW
                echo "next"

            else if e.which == ENTER_KEY
                echo "enter"

            else if e.which == ESC_KEY
                #echo "esc"
                destory_all()
        )


class ConfirmDialog extends Widget
    message_text = [
        "System will auto lock ",
        "System will auto suspend ",
        "System will auto logout ",
        "System will auto restart ",
        "System will auto shutdown "
    ]
    timeId = null

    constructor: (i)->
        super
        if i < 2 or i > 4 then return
        @i = i
        #echo "ConfirmDialog:#{option[i]}"
   
    destory:->
        document.body.removeChild(@element)


    frame_build:->
        i = @i
        frame_confirm = create_element("div", "frame_confirm", @element)
        frame_confirm.addEventListener("click",->
            frame_click = true
        )
        
        left = create_element("div","left",frame_confirm)
        img_url = "img/normal/#{option[i]}.png"
        @img_confirm = create_img("img_confirm",img_url,left)
        text_img = create_element("div","text_img",left)
        text_img.textContent = option[i]
        
        right = create_element("div","right",frame_confirm)
        @message_confirm = create_element("div","message_confirm",right)
        @message_confirm.textContent = message_text[i] + "in 60 seconds."

        button_confirm = create_element("div","button_confirm",right)
        
        button_cancel = create_element("div","button_cancel",button_confirm)
        button_cancel.type = "button"
        button_cancel.textContent = "cancel"
        button_cancel.name = "cancel"
        button_cancel.value = "cancel"

        button_ok = create_element("div","button_ok",button_confirm)
        button_ok.type = "button"
        button_ok.textContent = option[i]
        button_ok.name = option[i]
        button_ok.value = option[i]

        button_cancel.addEventListener("click",->
            clearInterval(timeId) if timeId
            destory_all()
        )
        button_ok.addEventListener("click",->
            destory_all()
            switch button_ok.textContent
                when "logout" then echo "logout"
                when "restart" then echo "restart"
                when "shutdown" then echo "shutdown"
                else return
        )

        apply_animation(right,"show_confirm","0.3s")
        right.addEventListener("webkitAnimationEnd",=>
            right.style.opacity = "1.0"
        ,false)
    
    interval:(time)->
        i = @i
        that = @
        clearInterval(timeId) if timeId
        timeId = setInterval(->
            time--
            that.message_confirm.textContent = message_text[i] + "in #{time} seconds."
            #img_url = "img/interval/#{option[i]}/#{option[i]}#{60 - time}.png"
            #that.img_confirm.src = img_url
            if time == 0
                clearInterval(timeId)
                destory_all()
                switch option[i]
                    when "logout" then echo "logout"
                    when "restart" then echo "restart"
                    when "shutdown" then echo "shutdown"
                    else return
        ,1000)

    key:->
        @element.addEventListener("keydown", (e)=>
            if e.which == LEFT_ARROW
                echo "prev"

            else if e.which == RIGHT_ARROW
                echo "next"

            else if e.which == ENTER_KEY
                echo "enter"

            else if e.which == ESC_KEY
                #echo "esc"
                destory_all()
        )
