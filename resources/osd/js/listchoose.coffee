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
    LI_SIZE =
        w:180
        h:40
    constructor:(@id)->
        super
        echo "New ListChoose :#{@id}"
        @list = []

        @Listul = []
        @li = []
        @li_span = []
        @isFromList = false
        @currentIndex = 0
        @length = null

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
        @element.style.width = @whole_w if @whole_w
        @boxscroll.style.maxHeight = @whole_h if @whole_h

    boxscroll_remove: ->
        @element.removeChild(@boxscroll) if @boxscroll
        @boxscroll = null

    ListAllBuild:(@list,@current,@max_show = 5) ->
        inject_css(@element,"css/listchoose.css")
        echo "ListAllBuild @current: #{@current}"
        @length = @list.length
        if !(@current in @list)
            echo "#{@current} isnt in #{@list.toString()} ,and then return"
            return

        @boxscroll = create_element("div","boxscroll",@element)
        @boxscroll.setAttribute("id","boxscroll")
        @boxscroll.style.overflowY = "scroll" if @list.length > @max_show
 
        @Listul = create_element("ul","Listul",@boxscroll)
        for each,i in @list
            @li[i] = create_element("li","li",@Listul)
            @li[i].setAttribute("id",each)
            @li[i].style.height = LI_SIZE.h
            @li_span[i] = create_element("span","li_span",@li[i])
            @li_span[i].textContent = each
            @currentIndex = i if each is @current
        @setCurrentCss()

    getCurrentIndex: ->
        return @currentIndex

    unselectCss: (i) =>
        #@li[i].style.backgroundColor = "rgba(0,0,0,0.4)"
        @li_span[i].style.color = "#FFFFFF"

    selectCss: (i) =>
        #@li[i].style.backgroundColor = "rgba(0,0,0,0.6)"
        @li_span[i].style.color = "#01bdff"

    setCurrentCss: ->
        @show()
        echo "setCurrentCss currentIndex:#{@currentIndex}"
        for each,i in @list
            if i is @currentIndex
                @selectCss(@currentIndex)
            else
                @unselectCss(i)

    checkIndex:(index)->
        max = @length - 1
        if index > max then index = 0
        else if index < 0 then index = max
        return index

    chooseOption: =>
        clearTimeout(timeout_osdHide)
        @isFromList = true
        @prevIndex = @currentIndex
        @currentIndex++
        @currentIndex = @checkIndex(@currentIndex)
        osdShow()
        @setCurrentCss()
        @current = @list[@currentIndex]
        return @current

    setKeyupListener:(keyup_code,keyup_cb)->
        document.body.addEventListener("keyup",(e)=>
            echo "keyup:#{e.which};keyup_code_demo:#{keyup_code}"
            if e.which == keyup_code and @isFromList is true
                @isFromList = false
                clearTimeout(timeout_osdHide)
                echo "setKeyupListener keyup_cb"
                keyup_cb?()
        )

    setClickCb: (cb) ->
        that = @
        for li in @li
            li.addEventListener("click",->
                that.current = this.id
                that.currentIndex = i for each,i in that.list when each is that.current
                clearTimeout(timeout_osdHide)
                osdHide()
                cb?()
            )
