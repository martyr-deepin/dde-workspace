#Copyright (c) 2011 ~ 2012 Deepin, Inc.
#              2011 ~ 2012 snyh
#
#Author:      snyh <snyh@snyh.org>
#Maintainer:  snyh <snyh@snyh.org>
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

show = false
$("#icon_desktop").addEventListener('click', (e) ->
    show = !show
    DCore.Dock.show_desktop(show)
)
$("#icon_desktop").addEventListener('mouseover', (e) ->
    Preview_container.remove_all()
)

$("#icon_launcher").addEventListener('click', (e) ->
    DCore.run_command("launcher")
)
$("#icon_launcher").addEventListener('mouseover', (e) ->
    Preview_container.remove_all()
)

format_two_bit = (s) ->
    if s < 9
        return "0#{s}"
    else
        return s

get_time_str = ->
    today = new Date()
    hours = today.getHours()
    if hours > 12
        m = _("PM")
        hours = hours - 12
    else
        m = _("AM")
    hours = format_two_bit hours
    min = format_two_bit today.getMinutes()
    sec = format_two_bit today.getSeconds()
    return "#{hours}:#{min}"

c = $("#clock")
setInterval( ->
    c.innerText = get_time_str()
    return true
, 1000
)

board.width = 1440
board.height = 30
DCore.Dock.draw_board(board)
