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

_global_menu_container = create_element("div", "", document.body)
_global_menu_container.id = "global_menu_container"
_global_menu_container.addEventListener("click", (e)->
    _global_menu_container.style.display = "none"
    _global_menu_container.removeChild(_global_menu_container.children[0])
)

class Menu extends Widget
    constructor: (@id) ->
        super
        @current = @id
        @items = {}

    insert: (@id, @title, @img)->
        _id = @id
        _title = @title
        item = create_element("div", "menuitem", @element)
        item.addEventListener("click", (e)=>
            @cb(_id, _title)
        )
        create_img("menuimg", @img, item)
        title = create_element("div", "menutitle", item)
        title.innerText = @title

        _img = @img
        @items[_id] = [_title, _img]
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

        @items[_id] = [_title]
        @current = @id

    set_callback: (@cb)->

    show: (x, y)->
        @try_append()

        @element.style.left = x
        @element.style.top = y

    try_append: ->
        if not @element.parent
            _global_menu_container.appendChild(@element)
            _global_menu_container.style.display = "block"

    get_allocation: ->
        @try_append()

        width = @element.clientWidth
        height = @element.clientHeight

        "width":width
        "height":height

class ComboBox extends Widget
    constructor: (@id, @on_click_cb) ->
        super
        @show_item = create_element("div", "ShowItem", @element)
        @current_img = create_img("", "", @show_item)
        @switch = create_element("div", "Switcher", @element)
        @menu = new Menu(@id+"_menu")
        @menu.set_callback(@on_click_cb)

    insert: (id, title, img)->
        @current_img.src = img
        @menu.insert(id, title, img)

    insert_noimg: (id, title)->
        @menu.insert_noimg(id, title)

    do_click: (e)->
        if e.target == @switch
            p = get_page_xy(e.target, 0, 0)
            alloc = @menu.get_allocation()
            # x = p.x - alloc.width/2
            x = p.x - alloc.width + @switch.offsetWidth
            y = p.y - alloc.height

            @menu.show(x, y)

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
        @current_img.src = find[1]
        find[0]


DCore.signal_connect("status", (msg) ->
    echo msg.status
    #status_div = create_element("div", " ", $("#Debug"))
    #status_div.innerText = "status:" + msg.status
)

de_menu_cb = (id, title)->
    id = de_menu.set_current(id)
    DCore.Greeter.set_selected_session(id)

de_menu = new ComboBox("desktop", de_menu_cb)

power_dict = {}
power_menu_cb = (id, title)->
    power_dict[title]()

power_menu = new ComboBox("power", power_menu_cb)
