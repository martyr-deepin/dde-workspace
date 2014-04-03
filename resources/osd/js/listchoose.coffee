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
class ListChoose extends Widget
    constructor:(@id)->
        super
        echo "New ListChoose :#{@id}"
        @Listul = []

    hide:->
        @element.style.display = "none"
    
    show:->
        @element.style.display = "-webkit-box"
    
    setPosition:(parent = document.body,left,bottom,position = "absolute")->
        parent.appendChild(@element)
        @element.style.position = position
        @element.style.left = left
        @element.style.bottom = bottom

    setSize:(@whole_w,@whole_h)->
        @element.style.width = @whole_w
        @element.style.height = @whole_h

    ListAllBuild:(@Listul,@current) ->
        @li = []
        @li_span = []
        @Listul = create_element("ul","Listul",@element)
        for each,i in @Listul
            @li[i] = create_element("li","li",@Listul)
            @li_span[i] = create_element("span","li_span",@li[i])
            @li_span[i].textContent = each
            if each is @current  then @currentIndex = i
        
        @setBackground(@currentIndex)

    setBackground: (index)=>
        # @ListAll(@UserLayoutList,@getCurrent())
        return if not @li[0]

        if index > @Listul.length - 1 then index = @Listul.length - 1
        else if index < 0 then index = 0
        
        for li,i in @li
            if i == Index
                li.style.border = "rgba(255,255,255,0.5) 2px solid"
                li.style.backgroundColor = "rgb(0,0,0)"
            else
                li.style.border = "rgba(255,255,255,0.0) 2px solid"
                li.style.backgroundColor = null

    ChooseIndex: =>
        @prevIndex = @currentIndex
        @currentIndex++

        if @currentIndex > @Listul.length - 1 then @currentIndex = @Listul.length - 1
        else if @currentIndex < 0 then @currentIndex = 0
        
        @current = @Listul[@currentIndex]
        @setBackground(@currentIndex)
        return @currentIndex
