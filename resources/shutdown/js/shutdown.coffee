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

document.body.style.height = window.screen.availHeight
document.body.style.width = window.screen.availWidth

option = ["lock","suspend","logout","restart","shutdown"]
message_init = "choose one"
message_text = [
    "do you want to lock your computer?",
    "do you want to suspend your computer?",
    "do you want to logout your computer?",
    "do you want to restart your computer?",
    "do you want to shutdown your computer?"
]


class ShutDown extends Widget
    constructor: (@id)->
        super
        echo "shutdown"


    frame_build:->
        frame = create_element("div", "frame", @element)
        button = create_element("div","button",frame)
        message = create_element("div","message",frame)
        message.textContent = message_init
        
        opt = []
        img_url = []
        opt_img = []
        opt_text = []
        
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
                message.textContent = message_text[i]
            )
            
            #normal
            opt[i].addEventListener("mouseout",->
                i = this.value
                opt_img[this.value].src = "img/normal/#{option[i]}.png"
                message.textContent = message_init
            )

            #click
            opt[i].addEventListener("mousedown",->
                i = this.value
                #echo "#{i}:mousedown"
                opt_img[this.value].src = "img/click/#{option[i]}.png"
                message.textContent = message_text[i]
            )
            opt[i].addEventListener("click",->
                i = this.value
                #echo "#{i}:click"
                opt_img[this.value].src = "img/click/#{option[i]}.png"
                message.textContent = message_text[i]
                that.fade_animal()
                
                confirmdialog = new ConfirmDialog(i)
                confirmdialog.frame_build()
                confirmdialog.show_animal()
            )
    
    fade_animal:->
        echo "fade_animal"
        document.body.removeChild(@element)



class ConfirmDialog extends Widget
    constructor: (i)->
        super
        @i = i
        echo "ConfirmDialog:#{option[i]}"

    frame_build:->
        i = @i
        frame_confirm = create_element("div", "frame_confirm", @element)
        
        left = create_element("div","left",frame_confirm)
        img_url = []
        img_url[i] = "img/normal/#{option[i]}.png"
        img_confirm = create_img("img_confirm",img_url[i],left)
        text_img = create_element("div","text_img",left)
        text_img.textContent = option[i]
        
        right = create_element("div","right",frame_confirm)
        message_confirm = create_element("div","message_confirm",right)
        message_confirm.textContent = message_text[i]

        button_confirm = create_element("div","button_confirm",right)
        
        button_cancel = create_element("button","button_cancel",button_confirm)
        button_cancel.type = "button"
        button_cancel.textContent = "cancel"
        button_cancel.name = "cancel"
        button_cancel.value = "cancel"

        button_ok = create_element("button","button_ok",button_confirm)
        button_ok.type = "button"
        button_ok.textContent = option[i]
        button_ok.name = option[i]
        button_ok.value = option[i]

        button_cancel.addEventListener("click",->
            echo "cancel"
        )
        button_ok.addEventListener("click",->
            echo "#{button_ok.textContent}"
        )

    show_animal:->
        echo "show_animal"
        document.body.appendChild(@element)



shutdown = new ShutDown()
shutdown.frame_build()
document.body.appendChild(shutdown.element)
