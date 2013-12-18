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
    parent = null
    img_before = null
    
    constructor: (parent_el) ->
        super
        parent = parent_el
        img_before = "images/desktopmenu/"

        #detext = create_element("div", "Detext", parent)
        #detext.innerText = _("Session")
    
    new_desktop_menu: ->
        de_menu_cb = (id, title)->
            id = de_menu.set_current(id)
            #DCore.Greeter.set_selected_session(id)
        de_menu = new ComboBox("desktop", de_menu_cb)
        #de_menu.show_item.style.background = "rgba(255,255,255, 0.3)"
        
        sessions = DCore.Greeter.get_sessions()
        echo sessions
        default_session = DCore.Greeter.get_default_session()
        echo "default_session:#{default_session}"
        if default_session is null then default_session = "deepin"
        for session in sessions
            id = session
            name = DCore.Greeter.get_session_name(id)
            icon = DCore.Greeter.get_session_icon(session)
            icon_path = img_before + "#{icon}"
            echo icon_path
            if session isnt default_session
                de_menu.insert(id, name, icon_path)
        parent.appendChild(de_menu.element) if parent
        #de_menu.set_current(default_session)
        
        de_menu.current_img.src = img_before + "#{default_session}_normal.png"

        de_menu.current_img.addEventListener("mouseover",=>
            echo "mouseover"
            de_menu.current_img.src = img_before + "#{default_session}.png"
            echo de_menu.current_img.src
        )
        de_menu.current_img.addEventListener("mouseout",=>
            echo "mouseout"
            de_menu.current_img.src = img_before + "#{default_session}_normal.png"
        )
        # de_menu.current_img.addEventListener("click", (e) =>
        #     power_dict["#{default_session}"]()
        # )
        de_menu.menu.element.addEventListener("mouseover",=>
            de_menu.current_img.src = img_before + "#{default_session}.png"
        )
