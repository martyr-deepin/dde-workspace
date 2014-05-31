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

class Rect extends Widget
    constructor:(@id,parent)->
        super
        
        echo "Rect #{@id}"
        parent?.appendChild(@element)
        
    create_rect_canvas: (@width,@height) ->
        @myCanvas = create_element("canvas","myCanvas",@element)
        @myCanvas.style.width = @width
        @myCanvas.style.height = @height
        @ctx = @myCanvas.getContext("2d")
        @ctx.strokeStyle = "rgba(0,0,0,1.0)"
        @ctx.lineWidth = 1.5
        @ctx.strokeRect(0,0,@width,@height)
        
    create_rect : (@width,@height) ->
        @rect = create_element("div","rect",@element)
        @rect.style.borderStyle = "dashed"
        @rect.style.borderWidth = "1px"
        @rect.style.borderRadius = "5px"
        @rect.style.width = @width
        @rect.style.height = @height
    
    set_pos : (x,y,position_type = "fixed",type = POS_TYPE.leftup) ->
        set_pos(@element,x,y,position_type,type)
