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

class Pointer extends Widget
    constructor:(@id,parent)->
        super
        
        echo "new Pointer #{@id}"
        @img_src = "img"
        parent?.appendChild(@element)
    
    create_pointer: (@area_type,@pos_type) ->
        echo "create_pointer @pos_type:#{@pos_type},@area_type:#{@area_type}"
        @pointer_img = create_img("pointer_img","",@element)
        @area_img = create_img("area_img","",@element)

        @pointer_img.src = "#{@img_src}/pointer_#{@pos_type}.png"
        if @area_type isnt AREA_TYPE.corner
            @area_img.src = "#{@img_src}/#{@area_type}.png"
        else
            @area_img.src = "#{@img_src}/#{@area_type}_#{@pos_type}.png"

        @area_width = 64
        @area_height = 64
        @pointer_width = 64
        @pointer_height = 64
        
        @pointer_img.style.width = @pointer_width
        @pointer_img.style.height = @pointer_height
        @area_img.style.width = @area_width
        @area_img.style.height = @area_height
        @element.style.width = @area_width + @pointer_width
        @element.style.height = @area_height + @pointer_height
        @pointer_img.style.background = "rgba(0,10,120,0.3)"
        @area_img.style.background = "rgba(120,125,120,0.3)"
        @element.style.background = "rgba(0,125,120,0.3)"

        set_pos(@area_img,0,0,"absolute",@pos_type)
        set_pos(@pointer_img,@area_width,@area_height,"absolute",@pos_type)


    set_area_pos : (x,y,position_type = "fixed",type = POS_TYPE.leftup) ->
        set_pos(@element,x,y,position_type,type)



