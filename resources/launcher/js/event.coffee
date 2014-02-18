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


forbidenDefault = (e)->
    e.stopPropagation()
    e.preventDefault()


click_callback = (e)->
    e.stopPropagation()
    if e.target != $("#category")
        exit_launcher()


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
    else
        switch e.which
            when KEYCODE.BACKSPACE
                e.stopPropagation()
                e.preventDefault()
                v = searchBar.value()
                if searchBar.cancel().value(v.substr(0, v.length - 1))
                    searchBar.show()
                    searchBar.search()
                else
                    searchBar.hide()
                    switcher.show()
                    $("#grid").style.display = 'block'
                    $("#searchResult").style.display = 'none'
                    switcher.hideCategory()
            when KEYCODE.ESC
                e.preventDefault()
                e.stopPropagation()
                if searchBar.empty()
                    exit_launcher()
                else
                    searchBar.hide()
                    searchBar.clean()
                    switcher.show()
                    $("#grid").style.display = 'block'
                    $("#searchResult").style.display = 'none'
                    switcher.hideCategory()
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

keypress_callback = (e) ->
    e.preventDefault()
    e.stopPropagation()
    if e.which != KEYCODE.ESC and e.which != KEYCODE.BACKSPACE and e.which != KEYCODE.ENTER and e.whicn != KEYCODE.SPACE
        switcher.hide()
        searchBar.show()
        searchBar.value(searchBar.value() + String.fromCharCode(e.which))
        searchBar.search()

bind_events = ->
    _b.addEventListener("contextmenu", forbidenDefault)
    _b.addEventListener("click", click_callback)
    # this does not work on keypress
    _b.addEventListener("keydown", keydown_callback)
    _b.addEventListener('keypress', keypress_callback)
