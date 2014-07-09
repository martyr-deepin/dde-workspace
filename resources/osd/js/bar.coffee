#Copyright (c) 2011 ~ 2014 Deepin, Inc.
#              2011 ~ 2014 bluth
#
#encoding: utf-8
#Author:      bluth <yuanchenglu@linuxdeepin.com>
#Maintainer:  bluth <yuanchenglu@linuxdeepin.com>
#
#This progress is free software; you can redistribute it and/or modify
#it under the terms of the GNU General Public License as published by
#the Free Software Foundation; either version 3 of the License, or
#(at your option) any later version.
#
#This progress is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.
#
#You should have received a copy of the GNU General Public License
#along with this progress; if not, see <http://www.gnu.org/licenses/>.

class Bar extends Widget
    constructor:(@id)->
        super
        @progressNum = false
        @color = "#FFF"
        @whole_w = 200
        @whole_h = 15

    show:->
        @element.style.display = "block"

    hide:->
        @element.style.display = "none"

    setPosition:(parent = document.body,left,bottom,position = "absolute")->
        parent.appendChild(@element)
        @element.style.position = position
        @element.style.left = left
        @element.style.bottom = bottom

    setSize:(@whole_w,@whole_h)->
        @element.style.width = @whole_w
        @element.style.height = @whole_h
        @element.style.backgroundColor = "rgba(0,0,0,0.95)"

    setColor:(@color)->
        @progress.style.background = @color if @progress

    showProgressNum:(@progressNum)->

    progressCreate:->
        @progress = create_element("strong","progress",@element)
        @progress.style.width = "1%"
        @progress.style.height = "100%"
        @progress.style.float = "left"
        @progress.style.background = @color
        @progress.style.textAlign = "center"
        @progress.style.borderRadius = "3px"

    setProgress:(@val)->
        if @val > 1 then @val = 1
        else if @val < 0 then @val = 0
        @progress.innerHTML = @progress.style.width if @progressNum
        @progress.style.width = "#{@val * 100}%"

