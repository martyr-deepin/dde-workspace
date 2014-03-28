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

class Bar extends Widget
    constructor:(@id)->
        super
 
    show:->
        @element.style.display = "block"

    hide:->
        @element.style.display = "none"

    setPosition:(parent,position,left,top)->
        parent.appendChild(@element)
        @element.style.position = position
        @element.style.left = left
        @element.style.top = top

    setSize:(w,h)->
        @element.style.width = w
        @element.style.height = h

    setColor:(color)->
        @color = color
        @progress.style.background = @color if @progress
        
    setValue:(val)->
        @val = val

    setAccuracy:(acc)->
        @acc = acc

    setSpeed:(speed)->
        @speed = speed

    showProgress:(barNum = false)->
        @barNum = barNum

    elCreate:->
        @progress = create_element("strong","progress",@element)
        @progress.style.width = "1%"
        @program.style.height = "100%"
        @progress.style.float = "left"
        @color = "#FFF" if not @color?
        @progress.style.background = @color
        @progress.style.textAlign = "center"
    
    go:->
        @program.innerHTML = @program.style.width if @barNum
        



