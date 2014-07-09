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

class DesktopMenu extends Widget
    constructor: (parent_el) ->
        super
        @parent = parent_el
        @img_before = "images/desktopmenu/"
        @user_session = []
        @current_img_src = null
        if not @parent? then @parent = document.body
        @parent.appendChild(@element)

    hide:->
        @element.style.display = "none"
        @ComboBox?.hide()

    show:->
        @element.style.display = "block"
        @ComboBox?.show()

    update_current_icon:(@current)->
        @show()
        try
            if @current is null or @current is undefined then @current = "deepin"
            echo "set_current(@current) :----#{@current}----"
            icon = DCore.Greeter.get_session_icon(@current)
            @current_img_src = "images/desktopmenu/current/#{icon}.png"
        catch error
            echo "set_current(#{@current}) error:#{error}"
            @current_img_src = "images/desktopmenu/current/unkown.png"
        finally
            echo @current_img_src
            localStorage.setItem("menu_current_id_desktop",@current)
            @ComboBox.current_img.src = @current_img_src

    menuChoose_click_cb : (id, title)=>
        @current = @ComboBox.set_current(id)
        @update_current_icon(@current)

    new_desktop_menu: ->
        echo "new_desktop_menu"
        @ComboBox = new ComboBox("desktop", @menuChoose_click_cb)
        @sessions = DCore.Greeter.get_sessions()
        if @sessions.length == 0 then return
        for session in @sessions
            #id = session.toLowerCase()
            name = id = session
            #name = DCore.Greeter.get_session_name(session.toLowerCase())
            icon = DCore.Greeter.get_session_icon(session)
            icon_path_normal = @img_before + "#{icon}_normal.png"
            icon_path_hover = @img_before + "#{icon}_hover.png"
            icon_path_press = @img_before + "#{icon}_press.png"
            @ComboBox.insert(id, name, icon_path_normal,icon_path_hover,icon_path_press)
        @ComboBox.frame_build()
        @ComboBox.currentTextShow()
        @element.appendChild(@ComboBox.element)

    keydown_listener:(e)->
        @ComboBox.menu.keydown(e)
