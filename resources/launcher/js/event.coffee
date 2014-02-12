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
    return
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
                update_items(category_infos[CATEGORY_ID.ALL])
                grid_load_category(selected_category_id)

                DCore.Launcher.save_config('sort_method', sort_method)
            when 2
                grid_load_category(selected_category_id)
                _show_hidden_icons(not is_show_hidden_icons)
        DCore.Launcher.force_show(false)
    ).showMenu(e.clientX, e.clientY)




keydown_callback = (e) ->
    e.stopPropagation()
    if e.ctrlKey and e.shiftKey and e.which == KEYCODE.TAB
        e.preventDefault()
        selected_up()
    else if e.ctrlKey
        e.preventDefault()
        switch e.which
            when KEYCODE.P
                selected_up()
            when KEYCODE.F
                selected_next()
            when KEYCODE.B
                selected_prev()
            when KEYCODE.N, KEYCODE.TAB
                selected_down()
            when KEYCODE.ENTER, KEYCODE.SPACE
                s_box?.focus()
    else if String.fromCharCode(e.which).match(/\w/) or e.which == KEYCODE.BACKSPACE
        s_box?.focus()
    else
        switch e.which
            when KEYCODE.ESC
                e.preventDefault()
                e.stopPropagation()
                exit_launcher()
                # if s_box?.value == ""
                #     exit_launcher()
                # else
                #     s_box?.focus()
                #     clean_search_bar()
            when KEYCODE.ENTER
                e.preventDefault()
                if item_selected
                    item_selected.do_click()
                else
                    get_first_shown()?.do_click()
            when KEYCODE.UP_ARROW
                e.preventDefault()
                selected_up()
            when KEYCODE.DOWN_ARROW
                e.preventDefault()
                selected_down()
            when KEYCODE.LEFT_ARROW
                e.preventDefault()
                selected_prev()
            when KEYCODE.RIGHT_ARROW
                e.preventDefault()
                selected_next()
            when KEYCODE.TAB
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
        if e.which != KEYCODE.ESC and e.which != KEYCODE.BACKSPACE and e.which != KEYCODE.ENTER and e.whicn != KEYCODE.SPACE
            s_box?.value += String.fromCharCode(e.which)
    )
