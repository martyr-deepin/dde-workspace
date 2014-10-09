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
        @page = null
        @selectedItem = null # Item

    container:(newPage)->
        el = newPage.getBox()
        if el? && (not @box? || not @box.isSameNode(el))
            @page?.resetScrollOffset()
            @box = el
            @page = newPage
            @clean()
            console.log "set container to #{el.id}"
        @box

    clean:->
        @update(null)

    rowNumber:->
        width = @box.clientWidth - GRID_PADDING * 2
        Math.floor(width / ITEM_WIDTH)

    getItem:->
        item = null
        if @selectedItem
            item = Widget.look_up(@selectedItem.dataset.appid)
        item

    update:(el)->
        # selected style must overwrite the hovered style, so style is set.
        if @selectedItem
            @selectedItem.classList.remove("selected")
        @selectedItem = el
        if @selectedItem
            @selectedItem.classList.add("selected")
            if not switcher.isShowCategory
                return
            categoryEl = @selectedItem.parentNode.parentNode
            categoryBar.focusCategory(categoryEl.dataset.catid)

    firstShown:->
        if @box
            if switcher.isShowCategory
                if (i = categoryList.firstCategory())?
                    return i.firstItem()
            else
                el = @page.getFirstItem()
                if not el
                    return null
                if el.style.display != 'none'
                    return el
                else
                    return @nextShown(el)
        null

    nextShown: (el)->
        while el = el.nextElementSibling
            if el.style.display != 'none'
                break
        el

    previousShown: (el)->
        while el = el.previousElementSibling
            if el.style.display != 'none'
                break
        el

    focusedCategory:(el)->
        cid = parseInt(el.parentNode.parentNode.dataset.catid)
        categoryList.category(cid)

    _scroll_to_view: (offset)->
        target = @page.getScrollbaleItem()
        oldOffset = target.style.webkitTransform.match(/(-?\d+)/)
        oldOffset = +(oldOffset?[0]) || 0
        @page.setScrollOffset(offset + oldOffset)
        # target.style.webkitTransform = "translateY(#{offset + oldOffset}px)"

    scroll_to_view: (el)->
        if not el or @inView(el)
            return

        p = @box
        rect = el.getBoundingClientRect()
        prect = @box.getBoundingClientRect()
        if rect.top < prect.top
            offset = prect.top - rect.top
            @page.scrollToView(offset)
        else if rect.bottom > prect.bottom
            offset = prect.bottom - rect.bottom
            @page.scrollToView(offset)

    inView:(el)->
        p = @box.firstElementChild
        rect = el.getBoundingClientRect()
        prect = p.getBoundingClientRect()
        rect.top >= prect.top && rect.top < prect.bottom && rect.bottom >= prect.bottom

    isSameLine: (lhs, rhs)->
        lhs.getBoundingClientRect().top == rhs.getBoundingClientRect().top

    isLastLine: (e)->
        el = e
        while (el = el.nextElementSibling)?
            if not @isSameLine(e, el)
                return false
        return true

    isFirstLine: (e)->
        el = e
        while (el = el.previousElementSibling)?
            if not @isSameLine(e, el)
                return false
        return true

    indexOnLine: (e)->
        el = e
        i = 0
        while (el = el.previousElementSibling)?
            if !@isSameLine(e, el)
                break
            i += 1
        i

    select: (fn)->
        if @selectedItem == null
            selectedItem = @firstShown()
            # console.log "first shown:"
            # console.log selectedItem
            @update(selectedItem)
            @scroll_to_view(selectedItem)
            return
        fn(@)

    right:->
        # console.log "right"
        @select((o)->
            item = o.selectedItem
            if not (n = o.nextShown(item))? && switcher.isShowCategory
                if (c = categoryList.nextCategory(o.focusedCategory(item).id))?
                    n = c.firstItem()

            if n?
                o.scroll_to_view(n)
                o.update(n)
        )

    left:->
        # console.log "left"
        @select((o)->
            item = o.selectedItem
            if not (n = o.previousShown(item))? && switcher.isShowCategory
                if (c = categoryList.previousCategory(o.focusedCategory(item).id))?
                    n = c.lastItem()

            if n?
                o.scroll_to_view(n)
                o.update(n)
        )

    down:->
        # console.log "down"
        @select((o)->
            item = o.selectedItem
            n = item
            count = o.rowNumber()

            if switcher.isShowCategory && o.isLastLine(item)
                console.log 'get next category'
                if (c = categoryList.nextCategory(o.focusedCategory(item).id))?
                    n = c.firstItem()
                    count = o.indexOnLine(item)

            for i in [0...count]
                if !n? || !(m = o.nextShown(n))?
                    break
                n = m

            if n && not o.isSameLine(n, item)
                o.scroll_to_view(n)
                o.update(n)
        )

    up:->
        # console.log "up"
        @select((o)->
            item = o.selectedItem
            n = item
            count = o.rowNumber()

            if switcher.isShowCategory && o.isFirstLine(item)
                if (c = categoryList.previousCategory(o.focusedCategory(item).id))?
                    count = 0
                    n = c.lastItem()
                    selectedIndex = o.indexOnLine(item)
                    candidateIndex = o.indexOnLine(n)
                    if candidateIndex > selectedIndex
                        count = candidateIndex - selectedIndex

            for i in [0...count]
                if !(n && (m = o.previousShown(n))?)
                    break
                n = m

            if n && not o.isSameLine(n, item)
                o.scroll_to_view(n)
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
