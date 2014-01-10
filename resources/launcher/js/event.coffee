#Copyright (c) 2011 ~  Deepin, Inc.
#              2013 ~ Lee Liqiang
#
#Author:      Lee Liqiang <liliqiang@linuxdeepin.com>
#Maintainer:  Lee Liqiang <liliqiang@linuxdeepin.com>
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
contextmenu_callback = (e)->
    e.preventDefault()
    menu = new Menu(
        DEEPIN_MENU_TYPE.NORMAL,
        new MenuItem(1, SORT_MESSAGE[sort_method])
    )
    hidden_icons_ids = _get_hidden_icons_ids()
    if hidden_icons_ids.length
        menu.append(new MenuItem(2, HIDDEN_ICONS_MESSAGE[is_show_hidden_icons]))

    DCore.Launcher.force_show(true)
    menu.dbus.connect("MenuUnregistered", -> DCore.Launcher.force_show(false))
    menu.addListener((id) ->
        id = parseInt(id)
        switch id
            when 1
                if sort_method == "rate"
                    sort_method = "name"
                else if sort_method == "name"
                    sort_method = "rate"

                sort_category_info(sort_methods[sort_method])
                update_items(category_infos[ALL_APPLICATION_CATEGORY_ID])
                grid_load_category(selected_category_id)

                DCore.Launcher.save_config('sort_method', sort_method)
            when 2
                grid_load_category(selected_category_id)
                _show_hidden_icons(not is_show_hidden_icons)
        DCore.Launcher.force_show(false)
    ).showMenu(e.clientX, e.clientY)




keydown_callback = (e) ->
    e.stopPropagation()
    if e.ctrlKey and e.shiftKey and e.which == TAB_KEY
        e.preventDefault()
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
            when ENTER_KEY, SPACE_KEY
                s_box.focus()
    else if String.fromCharCode(e.which).match(/\w/) or e.which == BACKSPACE_KEY
        s_box.focus()
    else
        switch e.which
            when ESC_KEY
                e.preventDefault()
                e.stopPropagation()
                if s_box.value == ""
                    exit_launcher()
                else
                    s_box.focus()
                    clean_search_bar()
            when ENTER_KEY
                e.preventDefault()
                if item_selected
                    item_selected.do_click()
                else
                    get_first_shown()?.do_click()
            when UP_ARROW
                e.preventDefault()
                selected_up()
            when DOWN_ARROW
                e.preventDefault()
                selected_down()
            when LEFT_ARROW
                e.preventDefault()
                selected_prev()
            when RIGHT_ARROW
                e.preventDefault()
                selected_next()
            when TAB_KEY
                e.preventDefault()
                if e.shiftKey
                    selected_prev()
                else
                    selected_next()

bind_events = ->
    _b.addEventListener("contextmenu", contextmenu_callback)
    # this does not work on keypress
    _b.addEventListener("keydown", keydown_callback)
    _b.addEventListener("click", (e)->
        e.stopPropagation()
        if e.target != $("#category")
            exit_launcher()
    )
    _b.addEventListener('keypress', (e) ->
        e.preventDefault()
        e.stopPropagation()
        if e.which != ESC_KEY and e.which != BACKSPACE_KEY and e.which != ENTER_KEY and e.whicn != SPACE_KEY
            s_box.value += String.fromCharCode(e.which)
    )
