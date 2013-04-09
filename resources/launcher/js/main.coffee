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


DCore.signal_connect('workarea_changed', (alloc)->
    height = alloc.height
    document.body.style.maxHeight = "#{height}px"
    $('#grid').style.maxHeight = "#{height-60}px"
)
DCore.signal_connect("lost_focus", (info)->
    if s_dock.LauncherShouldExit_sync(info.xid)
        DCore.Launcher.exit_gui()
)
DCore.Launcher.notify_workarea_size()


document.body.addEventListener("click", (e)->
    e.stopPropagation()
    if e.target != $("#category")
        DCore.Launcher.exit_gui()
)

document.body.addEventListener("contextmenu", (e)->
    # forbid context meun
    e.preventDefault()
)


document.body.addEventListener("keypress", do ->
    _last_val = ''
    (e) ->
        if e.ctrlKey
            switch e.which
                when 112 #p
                    selected_up()
                when 102 #f
                    selected_next()
                when 98 #b
                    selected_prev()
                when 110 #n
                    selected_down()
                else
                    s_box.value += String.fromCharCode(e.which)
        else
            switch e.which
                when ESC_KEY
                    if s_box.value == ""
                        DCore.Launcher.exit_gui()
                    else
                        _last_val = s_box.value
                        s_box.value = ""
                        update_items(category_infos[ALL_APPLICATION_CATEGORY_ID])
                        grid_load_category(selected_category_id)
                    return  # to avoid to invoke search function
                when BACKSPACE_KEY
                    _last_val = s_box.value
                    s_box.value = s_box.value.substr(0, s_box.value.length-1)
                    if s_box.value == ""
                        if _last_val != s_box.value
                            do_search()
                            grid_load_category(selected_category_id)
                        return  # to avoid to invoke search function
                when ENTER_KEY
                    if item_selected
                        item_selected.do_click()
                    else
                        get_first_shown()?.do_click()
                else
                    s_box.value += String.fromCharCode(e.which)
            search()
)


applications = {}
init_all_applications = ->
    # get all applications and sort them by name
    _all_items = DCore.Launcher.get_items_by_category(ALL_APPLICATION_CATEGORY_ID)
    _all_items.sort((lhs, rhs) ->
        lhs_name = DCore.DEntry.get_name(lhs)
        rhs_name = DCore.DEntry.get_name(rhs)

        if lhs_name > rhs_name
            1
        else if lhs_name == rhs_name
            0
        else
            -1
    )
    for core in _all_items
        id = DCore.DEntry.get_id(core)
        applications[id] = new Item(id, core)

init_search_box()
init_all_applications()
init_category_list()
init_grid()
