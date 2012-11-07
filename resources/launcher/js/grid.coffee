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

applications = {}
category_infos = []

create_item = (info) ->
    el = document.createElement('div')
    el.setAttribute('class', 'item')
    el.id = info.EntryPath
    el.innerHTML = "
    <img draggable=false src=#{info.Icon} />
    <div class=item_name> #{info.Name}</div>
    <div class=item_comment>#{info.Comment}</div>
    "
    el.click_cb = (e) ->
        el.style.cursor = "wait"
        flag = info.Exec.indexOf("%")
        if (flag > 0)
            exec = info.Exec.substr(0, flag)
        else
            exec = info.Exec
        DCore.run_command(exec)
        DCore.Launcher.exit_gui()
    el.addEventListener('click', el.click_cb)
    return el

for info in DCore.Launcher.get_items()
    applications[info.EntryPath] = create_item(info)
# load the Desktop Entry's infomations.

#export function
grid_show_items = (items) ->
    grid.innerHTML = ""
    for i in items
        grid.appendChild(applications[i])

grid = $('#grid')
grid_load_category = (cat_id) ->
    if cat_id == 0
        grid.innerHTML = ""
        for own key, value of applications
            grid.appendChild(value)
        return

    if category_infos[cat_id]
        info = category_infos[cat_id]
    else
        info = DCore.Launcher.get_items_by_category(cat_id)
        category_infos[cat_id] = info

    grid_show_items(info)
