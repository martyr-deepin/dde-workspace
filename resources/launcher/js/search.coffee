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
    n = item_selected.nextElementSibling
    if n
        update_selected(n)
selected_prev = ->
    n = item_selected.previousElementSibling
    if n
        update_selected(n)

search = ->
    ret = []
    key = s_box.value.toLowerCase()

    for k of applications
        if key == ""
            ret.push(k)
        else if basename(k).toLowerCase().indexOf(key) >= 0
            ret.push(k)
    grid_show_items(ret)
    return ret

s_box.addEventListener('input', s_box.blur())

document.body.onkeydown = (e)->
    switch e.which
        when 39 #f
            selected_next()
        when 37 #b
            selected_prev()

document.body.onkeypress = (e) ->
    if e.ctrlKey
        switch e.which
            when 102 #f
                selected_next()
            when 98 #b
                selected_prev()
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
                item_selected?.click_cb()
                #$('#grid').children[0].click_cb()
            else
                s_box.value += String.fromCharCode(e.which)
        search()
