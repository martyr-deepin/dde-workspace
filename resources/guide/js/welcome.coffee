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

class Welcome extends Widget
    constructor:(@id)->
        super
        
        echo "welcome #{@id}"
        
        inject_css(@element,"css/welcome.css")
        DEFAULT_BG = "/usr/share/backgrounds/default_background.jpg"
        @element.style.backgroundImage = "url(#{DEFAULT_BG})"
        
        @logo = create_element("div","logo",@element)
        @logo_img = create_img("logo_img","",@logo)
        @img_src_before = "img/"
        @logo_img.src = "#{@img_src_before}/deepin_logo_w.png"
        @welcome_text = create_element("div","welcome_text",@logo)
        @welcome_text.textContent = _("Welcome to use Deepin Operating System")
        
        @readying = create_element("div","readying",@element)
        @readying.innerText = _("Ready to prepare for operation ...")
    
        set_pos_center(@logo,0.7)
        @readying.style.width = "260px"
        @readying.style.left = @logo.style.left
        @readying.style.bottom = "4.5em"

        setTimeout(=>
            guide?.switch_page(@,"Start")
        ,t_switch_page)
