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


document.body.addEventListener("contextmenu", (e) ->
    # forbid context menu
    e.preventDefault()
)
board = $("#board")
board.width = screen.width
board.height = DOCK_HEIGHT
DCore.Dock.draw_board(board)

DCore.signal_connect("dock_color_changed", -> DCore.Dock.draw_board(board))

DCore.signal_connect("tray_icon_area_changed", (info)->
    $("#notifyarea").style.width = "#{info.width}px"
)

_current_active_window = null
get_active_window = ->
    return _current_active_window

DCore.signal_connect("active_window_changed", (info)->
    if (info.app_id)
        active_group?.to_normal_status()
        active_group = Widget.look_up("le_"+info.app_id)
        active_group?.to_active_status(info.id)

        Preview_active_window_changed(info.id)
        _current_active_window = info.id
    else
        active_group?.to_normal_status()
        active_group = null
        Preview_active_window_changed(null)
        _current_active_window = null
)

DCore.signal_connect("launcher_added", (info) ->
    c = Widget.look_up(info.Id)
    if not c
        new Launcher(info.Id, info.Icon, info.Core)
)
DCore.signal_connect("dock_request", (info) ->
    group = Widget.look_up("le_"+info.Id)
    if group
        apply_flash(group.img, 0.3)
    else
        c = Widget.look_up(info.Id)
        if not c
            l = new Launcher(info.Id, info.Icon, info.Core)
            apply_flash(l.img, 1)
        else
            apply_rotate(c.element, 0.3)
)

DCore.signal_connect("launcher_removed", (info) ->
    Widget.look_up(info.Id)?.destroy_with_animation()
)

DCore.signal_connect("task_updated", (info) ->
    leader = Widget.look_up("le_" + info.app_id)

    if not leader
        leader = new ClientGroup("le_"+info.app_id, info.icon, info.app_id, info.exec)
        leader?.try_swap_launcher()

    leader?.update_client(info.id, info.icon, info.title)
)
DCore.signal_connect("dock_hidden", ->
    Preview_close_now()
)

DCore.signal_connect("task_removed", (info) ->
    Widget.look_up("le_"+info.app_id)?.remove_client(info.id)
)

DCore.signal_connect("in_mini_mode", ->
    MAX_SCALE = 0.5
    calc_app_item_size()
)

DCore.signal_connect("in_normal_mode", ->
    MAX_SCALE = 1
    calc_app_item_size()
)

setTimeout(->
    IN_INIT = false
    calc_app_item_size()
    DCore.Dock.change_workarea_height(ITEM_HEIGHT * ICON_SCALE)
, 100)


DCore.Dock.emit_webview_ok()

show_desktop.show(DCore.Dock.get_desktop_status())
DCore.Dock.test()
