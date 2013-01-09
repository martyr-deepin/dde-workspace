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

basename = (path)->
    path.replace(/\\/g,'/').replace(/.*\//,)
    
s_box = $('#s_box')

item_selected = null

update_selected = (el)->
    item_selected?.setAttribute("class", "item")
    item_selected = el
    item_selected?.setAttribute("class", "item item_selected")

selected_next = ->
    if not item_selected
        item_selected = $(".item")
        update_selected(item_selected)
        return
    n = item_selected.nextElementSibling
    if n
        update_selected(n)
selected_prev = ->
    if not item_selected
        item_selected = $(".item")
        update_selected(item_selected)
        return
    n = item_selected.previousElementSibling
    if n
        update_selected(n)

selected_down = ->
    if not item_selected
        item_selected = $(".item")
        update_selected(item_selected)
        return
    n = item_selected
    for i in [0..get_item_row_count()-1]
        if n
            n = n.nextElementSibling
    if n
        update_selected(n)
    grid.scrollTop += SCROLL_STEP_LEN

selected_up = ->
    if not item_selected
        item_selected = $(".item")
        update_selected(item_selected)
        return
    n = item_selected
    for i in [0..get_item_row_count()-1]
        if n
            n = n.previousElementSibling
    if n
        update_selected(n)
    grid.scrollTop -= SCROLL_STEP_LEN


get_item_row_count = ->
    count = 0
    items = $s('.item')
    first_value = items[0].offsetTop
    for i in items
        if i.offsetTop != first_value
            break
        else
            count++
    return count

search = ->
    ret = []
    key = s_box.value.toLowerCase()

    for k,v of applications
        if key == ""
            ret.push(k)
        else if DCore.Launcher.is_contain_key(v.core, key)
            ret.push(k)
    grid_show_items(ret)
    return ret

$("#search").addEventListener('click', (e)->
    if e.target == s_box
        e.stopPropagation()
)

s_box.addEventListener('input', s_box.blur())

document.body.onkeydown = (e)->
    switch e.which
        when 39 #f
            selected_next()
        when 37 #b
            selected_prev()
        when 40 #n
            selected_down()
        when 38 #p
            selected_up()

document.body.onkeypress = (e) ->
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
            when 27
                if s_box.value == ""
                    DCore.Launcher.exit_gui()
                else
                    s_box.value = ""
            when 8
                s_box.value = s_box.value.substr(0, s_box.value.length-1)
            when 13
                if item_selected
                    Widget.look_up(item_selected.id).do_click()
                else
                    Widget.look_up($(".item").id)?.do_click()
            else
                s_box.value += String.fromCharCode(e.which)
        search()

DCore.signal_connect("im_commit", (info)->
    s_box.value += info.Content
    search()
)

cursor = create_element("span", "cursor", document.body)
cursor.innerText = "|"
