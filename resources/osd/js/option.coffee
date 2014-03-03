#Copyright (c) 2011 ~ 2013 Deepin, Inc.
#              2011 ~ 2013 yilang
#
#Author:      YuanChenglu <yuanchenglu001@gmail.com>
#Maintainer:  YuanChenglu <yuanchenglu001@gmail.com>
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
class Option extends Widget
    constructor:(@id)->
        super
        echo "new Option:#{@id}"
    
    append:(el)->
        el.appendChild(@element)

    hide:->
        @element.style.display = "none"
    
    show:->
        @set_bg(@id)
        @element.style.display = "block"

    set_bg:(imgName)->
        @element.style.backgroundImage = "url(img/#{imgName}.png)"
