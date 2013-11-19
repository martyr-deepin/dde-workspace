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
	detext = null
	de_menu = null
	sessions = {}
	parent = null
	constructor: (parent_el) ->
        super
        parent = parent_el
        detext = create_element("div", "Detext", parent)
		detext.innerText = _("Session")

	get_sessions:->
		sessions = DCore.Greeter.get_sessions()

	new_desktop_menu:->

		get_sessions = @get_sessions()
		de_menu_cb = (id, title)->
		    id = de_menu.set_current(id)

		de_menu = new ComboBox("desktop", de_menu_cb)
		#de_menu.show_item.style.background = "rgba(255,255,255, 0.3)"

		for session in sessions
		    id = session
		    name = DCore.Greeter.get_session_name(id)
		    icon = DCore.Greeter.get_session_icon(session)
		    icon_path = "images/#{icon}"
		    de_menu.insert(id, name, icon_path)

		default_session = DCore.Greeter.get_default_session()
		    
		parent.appendChild(de_menu.element)
		de_menu.set_current(default_session)
		#DCore.Greeter.set_selected_session(default_session)
