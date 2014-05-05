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

class UserMenu extends Widget
    constructor: (parent_el) ->
        super
        @parent = parent_el
        @img_before = null
        @user_session = []
        @current_img_src = null
        if not @parent? then @parent = document.body
        @parent.appendChild(@element)
        @accounts = new Accounts(APP_NAME)
        
    hide:->
        @element.style.display = "none"
        @ComboBox?.hide()

    show:->
        @element.style.display = "block"
        @ComboBox?.show()

    menuChoose_click_cb : (current, title)=>
        @current = @ComboBox.set_current(current)


    new_user_menu: ->
        echo "new_user_menu"
        
        @ComboBox = new ComboBox("user", @menuChoose_click_cb)
        @ComboBox.hide()
        @users_id = @accounts.users_id
        if @users_id.length < 2 then return
        for uid in @users_id
            if not @accounts.is_disable_user(uid)
                username = @accounts.users_id_dbus[uid].UserName
                usericon = @accounts.users_id_dbus[uid].IconFile
                @ComboBox.insert(uid, username, usericon,usericon,usericon)
        @ComboBox.frame_build()
        @element.appendChild(@ComboBox.element)
        

    keydown_listener:(e)->
        @ComboBox.menu.keydown(e)

