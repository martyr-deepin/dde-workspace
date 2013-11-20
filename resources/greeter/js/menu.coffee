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
        @items = {}
        @element.style.display = "none"

    insert: (@id, @title, @img)->
        _id = @id
        _title = @title
        _img = @img
        menuimg = create_img("menuimg", @img, @element)
        menuimg.addEventListener("click", (e)=>
            @cb(_id, _title)
        )

        @items[_id] = [_id, _title, _img]
        @current = @id

    insert_noimg: (@id, @title)->
        _id = @id
        _title = @title
        item = create_element("div", "menuitem", @element)
        item.addEventListener("click", (e)=>
            @cb(_id, _title)
        )
        title = create_element("div", "menutitle", item)
        title.innerText = @title

        @items[_id] = [_id, _title]
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
    
    show: (left, bottom)->
        #echo "show"
        document.body.appendChild(@element) if not parent?
        @element.style.left = left
        @element.style.bottom = bottom
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
        @menu = new Menu(@id+"_menu")
        @menu.set_callback(@on_click_cb)

    insert: (id, title, img)->
        #@current_img.src = img
        @menu.insert(id, title, img)

    insert_noimg: (id, title)->
        @menu.insert_noimg(id, title)

    do_mouseover: (e)->
        #echo "box over"
        p = get_page_xy(@current_img, 0, 0)
        left = p.x
        bottom = document.body.clientHeight - p.y
        @menu.show(left, bottom)
    
    do_mouseout: (e)->
        #echo "box out"
        @menu.hide()
    
    get_current: ->
        return @menu.current

    get_useable_current : ->
        ret = @menu.items[@menu.current]
        if not ret?
            for key, val of @menu.items
                ret = val
                break
        return ret

    set_current: (id)->
        find = @menu.items[id]
        if not find?
            find = @get_useable_current()
        @menu.current = find[0]
        @current_img.src = find[2]
        find[0]

