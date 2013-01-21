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
    active_group = Widget.look_up("le_"+info.app_id)
    active_group?.to_active_status(info.id)
)

DCore.signal_connect("launcher_added", (info) ->
    c = Widget.look_up(info.Id)
    if not c
        new Launcher(info.Id, info.Icon, info.Core)
)
DCore.signal_connect("dock_request", (info) ->
    c = Widget.look_up(info.Id)
    if not c
        l = new Launcher(info.Id, info.Icon, info.Core)
        apply_flash(l.img, 1)
    else
        apply_rotate(c.element, 0.3)
        #group = Widget.look_up("le_"+info.Id)
        #if group
            #apply_flash(group.element, 0.3)
        #else
            #echo "not found group...#{info.Id}"
)

DCore.signal_connect("launcher_removed", (info) ->
    Widget.look_up(info.Id)?.destroy()
)

DCore.signal_connect("task_updated", (info) ->
    leader = Widget.look_up("le_" + info.app_id)

    if not leader
        leader = new ClientGroup("le_"+info.app_id, info.icon, info.app_id)

    leader.update_client(info.id, info.icon, info.title)
)

DCore.signal_connect("task_removed", (info) ->
    Widget.look_up("le_"+info.app_id)?.remove_client(info.id)
)

DCore.signal_connect("task_withdraw", (info) ->
    Widget.look_up("le_" + info.app_id).withdraw_child(info.id)
)

DCore.signal_connect("task_normal", (info) ->
    Widget.look_up("le_" + info.app_id).normal_child(info.id)
)

DCore.signal_connect("in_mini_mode", ->
    run_post(calc_app_item_size())
)

DCore.signal_connect("in_normal_mode", ->
    run_post(calc_app_item_size())
)
DCore.Dock.emit_webview_ok()
show_desktop.show(DCore.Dock.get_desktop_status())

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

init_app_item_size = ->
    apps = $s(".AppItem")
    w = apps[0].offsetWidth
    for i in apps
        Widget.look_up(i.id).change_size(w)
setTimeout(init_app_item_size, 100)
setTimeout(init_app_item_size, 1000)
setTimeout(init_app_item_size, 1800)
setTimeout(init_app_item_size, 2800)
setTimeout(init_app_item_size, 4000)
setTimeout(->
    DCore.Dock.require_region(0, 0, screen.width, ITEM_HEIGHT)
    DCore.Dock.change_workarea_height(ITEM_HEIGHT)
    IN_INIT = false
, 200)
