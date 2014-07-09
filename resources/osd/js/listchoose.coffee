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
        @list = []

        @Listul = []
        @li = []
        @li_span = []
        @isFromList = false
        @currentIndex = 0

        @show()

    hide:->
        @element.style.display = "none"

    show:->
        @element.style.display = "-webkit-box"

    setParent:(parent = document.body)->
        parent.appendChild(@element)

    setPosition:(left,bottom,position = "absolute")->
        #@element.style.position = position
        @element.style.left = left
        @element.style.bottom = bottom

    setSize:(@whole_w,@whole_h)->
        @element.style.width = @whole_w
        @element.style.height = @whole_h

    ListAllBuild:(@list,@current) ->
        echo "ListAllBuild @current: #{@current}"
        if !(@current in @list)
            echo "#{@current} isnt in #{@list.toString()} ,and then return"
            return
        @Listul = create_element("ul","Listul",@element)
        for each,i in @list
            @li[i] = create_element("li","li",@Listul)
            @li[i].setAttribute("id",each)
            @li_span[i] = create_element("span","li_span",@li[i])
            @li_span[i].textContent = each
            @currentIndex = i if each is @current

        echo "@currentIndex:#{@currentIndex} is @current :#{@current}"
        @setBackground(@currentIndex)

    get_current_index: ->
        @currentIndex = i for each,i in @list when each is @current
        return @currentIndex

    setBackground: (index)=>
        return if not @li[0]?
        echo "setBackground:#{index}"
        @show()
        @currentIndex = @checkIndex(index)
        for li,i in @li
            if i == @currentIndex
                li.style.border = "rgba(255,255,255,0.5) 2px solid"
                li.style.backgroundColor = "rgb(0,0,0)"
                #li.focus()
            else
                li.style.border = "rgba(255,255,255,0.0) 2px solid"
                li.style.backgroundColor = null
                #li.blur()
    
    checkIndex:(index)->
        max = @list.length - 1
        if index > max then index = 0
        else if index < 0 then index = max
        return index

    chooseOption: =>
        setFocus(true)
        document.body.style.maxLength = "180px"
        clearTimeout(timeout_osdHide)
        @prevIndex = @currentIndex
        @currentIndex++
        @currentIndex = @checkIndex(@currentIndex)
        @current = @list[@currentIndex]
        echo "ChooseIndex from #{@prevIndex} to #{@currentIndex}"
        osdShow()
        @setBackground(@currentIndex)
        @isFromList = true
        @element.focus()

        @element.removeEventListener("keyup",@keyup)
        @element.addEventListener("keyup",@keyup)
        return @current

    keyup: (e) =>
        echo "keyup:#{e.which}"
        if e.which == @keyup_code and @isFromList is true
            @isFromList = false
            setFocus(false)
            clearTimeout(timeout_osdHide)
            document.body.style.maxLength = "160px"
            osdHide()
            @keyup_cb?()

    setKeyupListener:(@keyup_code,@keyup_cb)->

    setClickCb: (cb) ->
        that = @
        for li in @li
            li.addEventListener("click",->
                that.current = this.id
                that.get_current_index()
                setFocus(false)
                clearTimeout(timeout_osdHide)
                document.body.style.maxLength = "160px"
                osdHide()
                cb?()
            )


