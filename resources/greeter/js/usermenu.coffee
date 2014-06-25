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
    constructor: (@userinfo_all,@parent) ->
        super
        echo "new UserMenu"
        @img_before = null
        @user_session = []
        @current_img_src = null
        @parent.appendChild(@element)
        
    hide:->
        @element.style.display = "none"
        @ComboBox?.hide()

    show:->
        @element.style.display = "block"
        @ComboBox?.show()
    
    menuHide:->
        @ComboBox?.menu.hide()
    
    menuShow:->
        @ComboBox?.menu.show()
    
    menuChoose_click_cb : (id, title)=>
        echo "menuChoose_click_cb:current:#{id}"
        @current = @ComboBox.set_current(id)

    new_user_menu: ->
        echo "new_user_menu"
        if @userinfo_all.length < 2 then return
        
        @ComboBox = new ComboBox("user", @menuChoose_click_cb)
        #@ComboBox.hide()
        for user in @userinfo_all
            uid = user.id
            username = user.username
            usericon = user.usericon
            if username is _("Guest") then usericon = "/var/lib/AccountsService/icons/guest_96.png"
            @ComboBox.insert(uid, username, usericon,usericon,usericon)
        @ComboBox.frame_build(1)
        @element.appendChild(@ComboBox.element)
        @ComboBox.current_img.src = "images/userswitch/acount_switch_hover.png"
        

    keydown_listener:(e)->
        @ComboBox?.menu.keydown(e)

