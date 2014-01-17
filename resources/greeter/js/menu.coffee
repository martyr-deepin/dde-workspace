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
        @menu = new MenuChoose(de_current_id)
        @menu.set_callback(@on_click_cb)

    insert: (id, title, img)->
        @menu.insert(id, title, img)
    
    frame_build:->
        @menu.frame_build()

    insert_noimg: (id, title)->
        @menu.insert_noimg(id, title)

    do_click: (e)->
        if @menu.element.style.display is "none"
            x = document.body.clientWidth * 0.3
            y = document.body.clientHeight * 0.3
            @menu.show(x, y)
        else
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

