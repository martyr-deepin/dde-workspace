#Copyright (c) 2011 ~ 2012 Deepin, Inc.
#              2011 ~ 2012 yilang
#
#Author:      LongWei <yilang2007lw@gmail.com>
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

de_menu_cb = (id, title)->
    alert("clicked #{id} #{title}")
    
de_menu = new ComboBox("desktop", de_menu_cb)
sessions = DCore.Greeter.get_sessions()
for session in sessions
    de_menu.insert(session, session, "images/deepin.png")

default_session = DCore.Greeter.get_default_session()
echo "default session"
echo default_session    
    
# de_menu.set_current(default_session)
    
$("#bottom_buttons").appendChild(de_menu.element)
