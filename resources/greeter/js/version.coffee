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
        inject_css(_b,"css/version.css")
        img_src_before = "images/"
        logo_img = create_img("version_img","",@element)
        logo_img.src = "#{img_src_before}/logo.png"

        ver = create_element("div","",@element)
        ver_txt = ""
        if is_greeter
            type_default = DCore[APP_NAME].get_deepin_type(null)
            if type_default == "Desktop"#if Desktop type, will not show typ,just beta alpha
                ver.setAttribute("class","VerBeta")
                ver_txt = ""
            else
                ver.setAttribute("class","VerType")
                lang = DCore[APP_NAME].get_lang()
                ver_txt = DCore[APP_NAME].get_deepin_type(lang)
        ver.textContent = ver_txt
