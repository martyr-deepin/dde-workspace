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



class ShutDown extends Widget
    
    constructor: (@id)->
        super
        # alert("shutdown")
        echo "shutdown"
        option = ["lock","suspend","logout","restart","shutdown"]
        
        frame = create_element("div", "frame", @element)
        button = create_element("div","button",frame)
        
        opt = []
        img_url = []
        opt_img = []
        opt_text = []
        
        for tmp ,i in option
            opt[i] = create_element("div","opt",button)
            img_url[i] = "img/normal/#{option[i]}.png"
            opt_img[i] = create_img("opt_img",img_url[i],opt[i])
            opt_text[i] = create_element("div","opt_text",opt[i])
            opt_text[i].textContent = option[i]
        
        message = create_element("div","message",frame)
        message.textContent = "do you want to shutdown your computer?"



shutdown = new ShutDown()
document.body.appendChild(shutdown.element)
