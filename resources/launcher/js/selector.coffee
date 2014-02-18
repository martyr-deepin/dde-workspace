#Copyright (c) 2011 ~ 2013 Deepin, Inc.
#              2013 ~ 2013 Li Liqiang
#
#Author:      Li Liqiang <liliqiang@linuxdeepin.com>
#Maintainer:  Li Liqiang <liliqiang@linuxdeepin.com>
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


item_selected = null


class Selector
    constructor:->
        @box = null
        @selectedItem = null

    rowNumber:->
        Math.floor(@box.clientWidth / ITEM_WIDTH)

    update:(el)->
        @selectedItem?.unselect()
        @selectedItem = el
        @selectedItem?.select()

    firstShown:->
        if @box && (item = Widget.look_up(@box.firstElementChild.id))?
            if item.is_shown()
                return item
            else
                item.next_shown()
        null

    initSelectedItem:->
        selectedItem = @firstShown()
        @update(selectedItem)
        selectedItem?.scroll_to_view(@box)

    right:->
        if @selectedItem == null
            @initSelectedItem()
            return
        if (n = @selectedItem.next_shown())?
            n.scroll_to_view(@box)
            @update(n)

    left:->
        if @selectedItem == null
            @initSelectedItem()
            return
        if (n = @selectedItem.prev_shown())?
            n.scroll_to_view(@box)
            @update(n)

    down:->
        if @selectedItem == null
            @initSelectedItem()
            return
        n = @selectedItem
        for i in [0...@rowNumber()]
            if n && (m = n.next_shown())?
                n = m
            else
                break
        if n && not n.sameLine(@selectedItem)
            n.scroll_to_view(@box)
            @update(n)

    up:->
        if @selectedItem == null
            @initSelectedItem()
            return
        n = @selectedItem
        for i in [0...@rowNumber()]
            if n && (m = n.prev_shown())?
                n = m
            else
                break
        if n && not n.sameLine(@selectedItem)
            n.scroll_to_view(@box)
            @update(n)

    container:(el)->
        if el?
            @box = el
            @clear()
            echo "set container to #{el.id}"
        @box

    clear:->
        @update(null)


clean_hover_state = do ->
    hover_timeout_id = null
    ->
        Item.clean_hover_temp = true
        event = new Event("mouseout")
        Widget.look_up(Item.hover_item_id)?.element.dispatchEvent(event)
        clearTimeout(hover_timeout_id)
        hover_timeout_id = setTimeout(->
            Item.clean_hover_temp = false
            event = new Event("mouseover")
            Widget.look_up(Item.hover_item_id)?.element.dispatchEvent(event)
        , 1100)

get_item_row_count = ->
    parseInt(grid.clientWidth / ITEM_WIDTH)

update_selected = (el)->
    item_selected?.unselect()
    item_selected = el
    item_selected?.select()

get_first_shown = ->
    if (first_item = applications[$(".SearchItem").id])?
        if first_item.is_shown()
            first_item
        else
            first_item.next_shown()
    else
        null

selected_next = ->
    clean_hover_state()
    if not item_selected
        item_selected = get_first_shown()
        update_selected(item_selected)
        item_selected?.scroll_to_view()
        return
    n = item_selected.next_shown()
    if n
        n.scroll_to_view()
        update_selected(n)
selected_prev = ->
    clean_hover_state()
    if not item_selected
        item_selected = get_first_shown()
        update_selected(item_selected)
        item_selected?.scroll_to_view()
        return
    n = item_selected.prev_shown()
    if n
        n.scroll_to_view()
        update_selected(n)

selected_down = ->
    clean_hover_state()
    if not item_selected
        item_selected = get_first_shown()
        update_selected(item_selected)
        item_selected?.scroll_to_view()
        return
    n = item_selected
    for i in [0..get_item_row_count()-1]
        if n
            n = n.next_shown()
    if n
        grid.scrollTop += SCROLL_STEP_LEN
        update_selected(n)

selected_up = ->
    clean_hover_state()
    if not item_selected
        item_selected = get_first_shown()
        update_selected(item_selected)
        item_selected?.scroll_to_view()
        return
    n = item_selected
    for i in [0..get_item_row_count()-1]
        if n
            n = n.prev_shown()
    if n
        grid.scrollTop -= SCROLL_STEP_LEN
        update_selected(n)
