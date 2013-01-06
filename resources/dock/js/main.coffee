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


board.width = screen.width
board.height = DOCK_HEIGHT
DCore.Dock.draw_board(board)

DCore.signal_connect("dock_color_changed", -> DCore.Dock.draw_board(board))


DCore.signal_connect("active_window_changed", (info)->
    active_group?.to_normal_status()
    active_group = Widget.look_up("le_"+info.clss)
    active_group?.to_active_status(info.id)
)

DCore.signal_connect("launcher_added", (info) ->
    c = Widget.look_up(info.Id)
    if c
        echo "have..#{info.Id}"
    else
        new Launcher(info.Id, info.Icon, info.Core)
)

DCore.signal_connect("launcher_removed", (info) ->
    Widget.look_up(info.Id)?.destroy()
)

DCore.signal_connect("task_updated", (info) ->
    leader = Widget.look_up("le_" + info.clss)

    if not leader
        leader = new ClientGroup("le_"+info.clss, info.icon, info.app_id)

    rgb = "rgb(#{info.r}, #{info.g}, #{info.b})"
    leader.update_client(info.id, info.icon, rgb, info.title)
)

DCore.signal_connect("task_removed", (info) ->
    Widget.look_up("le_"+info.clss)?.remove_client(info.id)
)

DCore.signal_connect("task_withdraw", (info) ->
    Widget.look_up("le_" + info.clss).withdraw_child(info.id)
)

DCore.signal_connect("task_normal", (info) ->
    Widget.look_up("le_" + info.clss).normal_child(info.id)
)

DCore.signal_connect("in_mini_mode", ->
    run_post(calc_app_item_size())
)

DCore.signal_connect("in_normal_mode", ->
    run_post(calc_app_item_size())
)

DCore.Dock.emit_webview_ok()

setTimeout(calc_app_item_size, 100)
setTimeout(calc_app_item_size, 1000)
setTimeout(calc_app_item_size, 1800)
setTimeout(calc_app_item_size, 2800)
setTimeout(calc_app_item_size, 4000)

format_two_bit = (s) ->
    if s < 10
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
c.innerText = get_time_str()
setInterval( ->
    c.innerText = get_time_str()
    return true
, 1000
)
