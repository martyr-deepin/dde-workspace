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


class Selector
    constructor:->
        @box = null
        @selectedItem = null

    container:(el)->
        if el?
            @box = el
            @clear()
            if el.id
                echo "set container to #{el.tagName}##{el.id}"
            else
                echo "set container to #{el.tagName}.\"#{el.className}\", parentNode: #{el.parentNode.id}"
        @box

    clear:->
        @update(null)

    rowNumber:->
        Math.floor(@box.clientWidth / ITEM_WIDTH)

    update:(el)->
        @selectedItem?.unselect()
        @selectedItem = el
        @selectedItem?.select()

    firstShown:->
        if @box
            if switcher.isShowCategory
                if (i = categoryList.firstCategory())?
                    return i.firstItem()
            else
                if (item = Widget.look_up(@box.firstElementChild.id))?
                    if item.is_shown()
                        return item
                    else
                        return item.next_shown()
        null

    select: (fn)->
        if @selectedItem == null
            selectedItem = @firstShown()
            @update(selectedItem)
            selectedItem?.scroll_to_view(@box)
            return
        fn(@)

    right:->
        @select((o)->
            item = o.selectedItem
            if not (n = item.next_shown())? && switcher.isShowCategory
                if (c = categoryList.nextCategory(item.focusedCategory().id))?
                    n = c.firstItem()

            if n?
                n.scroll_to_view(o.box)
                o.update(n)
        )

    left:->
        @select((o)->
            item = o.selectedItem
            if not (n = o.selectedItem.prev_shown())? && switcher.isShowCategory
                if (c = categoryList.previousCategory(item.focusedCategory().id))?
                    n = c.lastItem()

            if n?
                n.scroll_to_view(o.box)
                o.update(n)
        )

    down:->
        @select((o)->
            item = o.selectedItem
            n = item
            count = o.rowNumber()

            if switcher.isShowCategory && item.isLastLine()
                if (c = categoryList.nextCategory(item.focusedCategory().id))?
                    n = c.firstItem()
                    count = item.indexOnLine()

            for i in [0...count]
                if !n? || !(m = n.next_shown())?
                    break
                n = m

            if n && not n.isSameLine(item)
                n.scroll_to_view(o.box)
                o.update(n)
        )

    up:->
        @select((o)->
            item = o.selectedItem
            n = item
            count = o.rowNumber()

            if switcher.isShowCategory && item.isFirstLine()
                if (c = categoryList.previousCategory(item.focusedCategory().id))?
                    count = 0
                    n = c.lastItem()
                    selectedIndex = item.indexOnLine()
                    candidateIndex = n.indexOnLine()
                    if candidateIndex > selectedIndex
                        count = candidateIndex - selectedIndex

            for i in [0...count]
                if !(n && (m = n.prev_shown())?)
                    break
                n = m

            if n && not n.isSameLine(item)
                n.scroll_to_view(o.box)
                o.update(n)
        )


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
