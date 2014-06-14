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

class Version extends Widget
    constructor:->
        super
        @element.style.display = "-webkit-box"
        
        img_src_before = "images/"
        logo_img = create_img("version_img","",@element)
        logo_img.src = "#{img_src_before}/logo.png"
        
        ver = create_element("div","ver",@element)
        ver.style.display = "block"
        ver.style.marginLeft = "0.4em"
        ver.style.top = 0
        ver.textContent = "RC"
        ver.style.fontFamily = "Arial"
        ver.style.fontSize = "1em"
        ver.style.color = "rgba(255,255,255,0.9)"
