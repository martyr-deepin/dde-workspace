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

sessions = DCore.Greeter.get_sessions()
for session in sessions
    id = session
    icon = DCore.Greeter.get_session_icon(session)
    icon_path ="images/#{icon}"
    de_menu.insert(id, session, icon_path)

default_session = DCore.Greeter.get_default_session()
    
$("#bottom_buttons").appendChild(de_menu.element)
de_menu.set_current(default_session)
