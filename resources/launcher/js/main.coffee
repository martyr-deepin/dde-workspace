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
        _save_hidden_apps()
        DCore.Launcher.exit_gui()
)
DCore.Launcher.notify_workarea_size()

_get_hidden_icons_ids = ->
    hidden_icons_ids = []
    for own id of hidden_icons
        hidden_icons_ids.push(id)
    return hidden_icons_ids

_save_hidden_apps = ->
    DCore.Launcher.save_hidden_apps(_get_hidden_icons_ids())

_b = document.body

_b.addEventListener("click", (e)->
    e.stopPropagation()
    if e.target != $("#category")
        _save_hidden_apps()
        DCore.Launcher.exit_gui()
)

_b.addEventListener('keypress', (e) ->
    if e.which != ESC_KEY
        s_box.value += String.fromCharCode(e.which)
        search()
)

# this does not work on keypress
_b.addEventListener("keydown", do ->
    _last_val = ''
    (e) ->
        if e.ctrlKey and e.shiftKey and e.which == TAB_KEY
            selected_up()
        else if e.ctrlKey
            e.preventDefault()
            switch e.which
                when P_KEY
                    selected_up()
                when F_KEY
                    selected_next()
                when B_KEY
                    selected_prev()
                when N_KEY, TAB_KEY
                    selected_down()
        else
            switch e.which
                when ESC_KEY
                    e.stopPropagation()
                    if s_box.value == ""
                        _save_hidden_apps()
                        DCore.Launcher.exit_gui()
                    else
                        _last_val = s_box.value
                        s_box.value = ""
                        update_items(category_infos[ALL_APPLICATION_CATEGORY_ID])
                        grid_load_category(selected_category_id)
                when UP_ARROW
                    selected_up()
                when DOWN_ARROW
                    selected_down()
                when LEFT_ARROW
                    selected_prev()
                when RIGHT_ARROW
                    selected_next()
                when TAB_KEY
                    e.preventDefault()
                    if e.shiftKey
                        selected_prev()
                    else
                        selected_next()
                when BACKSPACE_KEY
                    _last_val = s_box.value
                    s_box.value = s_box.value.substr(0, s_box.value.length-1)
                    if s_box.value == ""
                        if _last_val != s_box.value
                            do_search()
                            grid_load_category(selected_category_id)
                        return  # to avoid to invoke search function
                    search()
                when ENTER_KEY
                    if item_selected
                        item_selected.do_click()
                    else
                        get_first_shown()?.do_click()
)

_contextmenu_callback = (msg) ->
    (e) ->
        menu = [[_("_Sort"), [
            [11, _("Sort by _Name")],
            [12, _("Sort by _Rate")]
        ]]]
        hidden_icons_ids = _get_hidden_icons_ids()
        if hidden_icons_ids.length
            menu.push([2, msg])
        _b.contextMenu = build_menu(menu)

is_show_hidden_icons = false

_show_hidden_icons = (is_shown) ->
    if is_shown == is_show_hidden_icons
        return
    is_show_hidden_icons = is_shown

    Item.display_temp = false
    if is_shown
        for own item of hidden_icons
            if item in category_infos[selected_category_id]
                hidden_icons[item].display_icon_temp()
        msg = HIDE_HIDDEN_ICONS
    else
        for own item of hidden_icons
            hidden_icons[item].hide_icon()
        msg = DISPLAY_HIDDEN_ICONS

    _b.addEventListener("contextmenu", _contextmenu_callback(msg))

# key: id of app (md5 basenam of path)
# value: Item class
applications = {}
# key: id of app
# value: a list of category id to which key belongs
hidden_icons = {}

compare_string = (s1, s2) ->
    return 1 if s1 > s2
    return 0 if s1 == s2
    return -1
init_all_applications = ->
    # get all applications and sort them by name
    _all_items = DCore.Launcher.get_items_by_category(ALL_APPLICATION_CATEGORY_ID)

    for core in _all_items
        id = DCore.DEntry.get_id(core)
        applications[id] = new Item(id, core)


get_name_by_id = (id) ->
    DCore.DEntry.get_name(Widget.look_up(id).core)

sort_by_name = (items)->
    items.sort((lhs, rhs)->
        lhs_name = get_name_by_id(lhs)
        rhs_name = get_name_by_id(rhs)
        compare_string(lhs_name, rhs_name)
    )

sort_by_rate = do ->
    rates = null
    (items, update)->
        rates = DCore.get_app_rate() if update
        items.sort((lhs, rhs)->
            if rates[lhs]? and rates[rhs]?
                rates_delta = rates[rhs] - rates[lhs]
                if rates_delta == 0
                    lhs_name = get_name_by_id(lhs)
                    rhs_name = get_name_by_id(rhs)
                    return compare_string(lhs_name, rhs_name)
                else
                    return rates_delta
            else if rates[lhs]? and not rates[rhs]?
                return -1
            else if not rates[lhs]? and rates[rhs]?
                return 1
            else
                lhs_name = get_name_by_id(lhs)
                rhs_name = get_name_by_id(rhs)
                return compare_string(lhs_name, rhs_name)
        )


_init_hidden_icons = ->
    hidden_icon_ids = DCore.Launcher.load_hidden_apps()
    if hidden_icon_ids?
        hidden_icon_ids.filter((elem, index, array) ->
            if not applications[elem]
                array.splice(index, 1)
        )
        DCore.Launcher.save_hidden_apps(hidden_icon_ids)
        for id in hidden_icon_ids
            if applications[id]
                hidden_icons[id] = applications[id]
                hidden_icons[id].hide_icon()

    _b.addEventListener("contextmenu", _contextmenu_callback(DISPLAY_HIDDEN_ICONS))

    _b.addEventListener("itemselected", (e) ->
        switch e.id
            when 11
                if DCore.Launcher.sort_method() != "name"
                    DCore.Launcher.save_config('sort_method', 'name')
                    sort_category_info(sort_by_name)
                    update_items(category_infos[ALL_APPLICATION_CATEGORY_ID])
                    grid_load_category(selected_category_id)
            when 12
                if DCore.Launcher.sort_method() != "rate"
                    DCore.Launcher.save_config('sort_method', 'rate')
                    sort_category_info(sort_by_rate)
                    update_items(category_infos[ALL_APPLICATION_CATEGORY_ID])
                    grid_load_category(selected_category_id)
            when 2
                grid_load_category(selected_category_id)
                _show_hidden_icons(not is_show_hidden_icons)
    )

    return

init_search_box()
init_all_applications()
init_category_list()
init_grid()
_init_hidden_icons()
