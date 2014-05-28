#Copyright (c) 2011 ~ 2012 Deepin, Inc.
#              2011 ~ 2012 yilang
#
#Author:      LongWei <yilang2007lw@gmail.com>
#Maintainer:  LongWei <yilang2007lw@gmail.com>
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
        
        inject_css(@element,"css/welcome.css")
        
        @logo = create_element("div","logo",@element)
        @logo_img = create_img("logo_img","",@logo)
        @img_src_before = "img/"
        @logo_img.src = "#{@img_src_before}/deepin_logo_w.png"
        @welcome_text = create_element("div","welcome_text",@logo)
        @welcome_text.textContent = _("Welcome to use Deepin OS")

        @readying = create_element("div","readying",@element)
        @readying.innerText = _("Preparing for use...")
    
        set_pos_center(@logo,0.7)
        @readying.style.width = "260px"
        @readying.style.left = @logo.style.left
        @readying.style.bottom = "4.5em"

