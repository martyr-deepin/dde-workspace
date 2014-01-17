#Copyright (c) 2011 ~ 2012 Deepin, Inc.
#              2011 ~ 2012 yilang
#
#Author:      LongWei <yilang2007lw@gmail.com>
#                     <snyh@snyh.org>
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


class Menu extends Widget
    parent = null
    mouseover = false
    menuimg = {}

    constructor: (@id) ->
        super
        @current = @id
        @items = new Array()
        @element.style.display = "none"

    insert: (@id, @title, @img)->
        _id = @id
        _title = @title
        _img = @img
        menuimg = create_img("menuimg", @img, @element)
#        tooltip = new ToolTip(menuimg,@title)
        #tooltip.element.style.zIndex = 65535
        #left = tooltip.element.style.left
        #top = tooltip.element.style.top
        #echo "-----------#{left},#{top}--------------"
        #tooltip.element.style.left = left + menuimg.clientWidth
        #tooltip.element.style.top = top + menuimg.clientHeight/2
        #echo tooltip.element
        #tooltip.element.style.display = "none"
        #tooltip.element.style.display = "block"

        menuimg.title = @title
        menuimg.addEventListener("click", (e)=>
            @cb(_id, _title)
        )

        @items.push({"id":_id, "title":_title,"img":_img})
        @current = @id

    insert_noimg: (@id, @title)->
        _id = @id
        _title = @title
        item = create_element("div", "menuitem", @element)
        item.addEventListener("click", (e)=>
            echo "----------------"
            @cb(_id, _title)
        )
        title = create_element("div", "menutitle", item)
        title.innerText = @title

        @items.push({"id":_id, "title":_title})
        @current = @id

    set_callback: (@cb)->

    
    append:(el)->
        parent = el
        parent.appendChild(@element)
    
    destory:->
        remove_element(@element)

    do_mouseover: (e)->
        #echo "menu over"
        mouseover = true
        @element.style.display = "block"
    
    do_mouseout: (e)->
        #echo "menu out"
        mouseover = false
        @hide()
    
    show: (x, y)->
        document.body.appendChild(@element) if not parent?
        @element.style.position = "absolute"
        @element.style.left = x
        @element.style.bottom = y
        @element.style.display = "block"

    hide:->
        #echo "hide"
        @element.style.display = "none" if not mouseover
    
    get_size: ->
        @element.style.display = "block"
        width = @element.clientWidth
        height = @element.clientHeight

        "width":width
        "height":height

class ComboBox extends Widget
    constructor: (@id, @on_click_cb) ->
        super
        @current_img = create_img("current_img", "", @element)
        
        de_current_id = localStorage.getItem("de_current_id")
        echo "-------------de_current_id:#{de_current_id}"
        if not de_current_id?
            echo "not de_current_id"
            de_current_id = DCore.Greeter.get_default_session() if is_greeter
            if de_current_id is null then de_current_id = "deepin"
            localStorage.setItem("de_current_id",de_current_id)
        @menu = new Menu(de_current_id)
        @menu.set_callback(@on_click_cb)

    insert: (id, title, img)->
        @menu.insert(id, title, img)

    insert_noimg: (id, title)->
        @menu.insert_noimg(id, title)

    do_mouseover: (e)->
        p = get_page_xy(@current_img, 0, 0)
        x = p.x
        y = document.body.clientHeight - p.y
        @menu.show(x, y)
    
    do_mouseout: (e)->
        @menu.hide()
    
    get_current: ->
        de_current_id = localStorage.getItem("de_current_id")
        @menu.current = de_current_id
        return @menu.current

    set_current: (id)->
        try
            echo "set_current(id) :---------#{id}----------------"
            localStorage.setItem("de_current_id",id)
            @menu.current = id
            echo "------@menu.items:---------------"
            echo @menu.items
            item_set = null
            for item,i in @menu.items
                if id == item.id
                    item_set = item
            echo "----item_set:-----------"
            echo item_set
            @current_img.src = item_set.img
            return item_set.id
        catch error
            echo "set_current(#{id}) error:#{error}"
            localStorage.setItem("de_current_id",id)
            @menu.current = id
            img_before = "images/desktopmenu/"
            @current_img.src = img_before + "unknown.png"
            return id

