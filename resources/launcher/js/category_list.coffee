#Copyright (c) 2011 ~  Deepin, Inc.
#              2013 ~  Lee Liqiang
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


class CategoryList extends Page
    constructor:(infos)->
        @categories = {}
        super("grid")
        @box.removeEventListener("scroll", @scrollCallback)
        @box.addEventListener("mousewheel", @scrollCallback)
        @container.classList.add("pageWrap")
        @container.addEventListener("webkitTransitionEnd", =>
            if not inView(selector.selectedItem)
                selector.update(null)
            @setMask(Page.MaskHint.BottomOnly)
            @container.style.webkitTransition = ''
        )

        @gridOffset = 0
        frag = document.createDocumentFragment()
        for info in infos
            id = info[0]
            name = info[1]
            items = info[2]
            @categories[id] = new Category(id, name, items)
            frag.appendChild(@categories[id].element)
            if items.length == 0
                @categories[id].hide()

        @blank = create_element(tag:'div', id:'blank', frag)
        @container.appendChild(frag)
        @finalOffset = 0

    updateNameDecoration:->
        for id in @categories
            @categories[id].setNameDecoration()

        @

    updateBlankHeight:->
        containerHeight = $("#container").clientHeight
        c = @blank
        while (c = c.previousElementSibling)
            if c.style.display != 'none'
                lastHeight = c.clientHeight
                break
        if containerHeight > lastHeight
            @blank.style.height = containerHeight - lastHeight - CATEGORY_LIST_ITEM_MARGIN
        else
            @blank.style.height = 0
        @

    showBlank: ->
        if @blank.style.display != 'block'
            @blank.style.display = 'block'

    hideEmptyCategories:->
        for own id, category of @categories
            if category.number() == 0
                category.hide()
                $("##{CategoryItem.PREFIX}#{id}").style.display = "none"
        @

    showNonemptyCategories:->
        for own id, category of @categories
            if category.number() != 0
                category.show()
                category.showHeader()
                category.setNameDecoration()
                # show category bar
                $("##{CategoryItem.PREFIX}#{id}").style.display = "block"
            else
                category.hide()
                $("##{CategoryItem.PREFIX}#{id}").style.display = "none"
        @

    addItem: (id, categories)->
        if !Array.isArray(categories)
            categories = [categories]
        for cat_id in categories
            @categories[cat_id].addItem(id)

    removeItem:(id, categories)->
        if typeof categories == 'undefined'
            console.log 'remove from all categories'
            for own cid, item of @categories
                item.removeItem(id)
            return

        if !Array.isArray(categories)
            categories = [categories]
        for cat_id in categories
            try
                @categories[cat_id].removeItem(id)
            catch e
                console.log "CategoryList.removeItem: #{e}"

    category:(id)->
        return @categories[id] if @categories[id]?
        null

    firstCategory:->
        for id in [CATEGORY_ID.INTERNET..CATEGORY_ID.UTILITIES]
            if @categories[id].isShown()
                return @categories[id]

        if @categories[CATEGORY_ID.OTHER].isShown()
            return @categories[CATEGORY_ID.OTHER]
        return null

    firstCategoryInView:->
        c = @firstCategory()
        if !c
            console.log("get first category failed")
            return null

        if inView(c.element)
            return c

        while !!(c = @nextCategory(c.id))
            if inView(c.element)
                return c

        null

    getFirstItemInView:->
        category = @firstCategoryInView()
        if !category
            console.log("no category in view")
            return null

        el = category.firstItemInView()
        return el if el

        # two category is enough
        category = @nextCategory(category.id)
        if not category
            return null

        return category.firstItemInView()

    lastCategory:->
        if @categories[CATEGORY_ID.OTHER].isShown()
            return @categories[CATEGORY_ID.OTHER]
        for id in [CATEGORY_ID.UTILITIES..CATEGORY_ID.INTERNET]
            if @categories[id].isShown()
                return @categories[id]
        return null

    nextCategory:(id)->
        return null if id == CATEGORY_ID.OTHER

        if id == CATEGORY_ID.FAVOR
            id = CATEGORY_ID.INTERNET - 1

        i = id + 1
        while i <= CATEGORY_ID.UTILITIES
            if @categories[i].isShown()
                return @categories[i]
            i += 1

        if @categories[CATEGORY_ID.OTHER].isShown()
            return @categories[CATEGORY_ID.OTHER]

        return null

    previousCategory:(id)->
        return null if id == CATEGORY_ID.FAVOR

        if id == CATEGORY_ID.OTHER
            id = CATEGORY_ID.UTILITIES + 1

        i = id - 1
        while i >= CATEGORY_ID.INTERNET
            if @categories[i].isShown()
                return @categories[i]
            --i

        return null

    fixOffset:(id)->
        console.log "fixOffset"
        children = $("#grid").firstElementChild.childNodes
        offset = 0
        for i in [0...children.length]
            if children[i].style.display == 'none'
                continue

            if children[i].dataset.catid == "#{id}"
                @finalOffset = offset
                break

            offset += children[i].clientHeight + CATEGORY_LIST_ITEM_MARGIN

    scroll: (currentId, targetId)->
        @currentOffset = $("##{Category.PREFIX}#{currentId}").offsetTop
        @fixOffset(targetId)
        offset = @finalOffset - @currentOffset
        console.log("finalOffset: #{@finalOffset}")
        @gridOffset = -@finalOffset
        @container.style.webkitTransition = '-webkit-transform 200ms cubic-bezier(0.28,0.9,0.7,1)'
        @container.style.webkitTransform = "translateY(#{@gridOffset}px)"

    getScrollOffset:->
        target = @getScrollableItem()
        oldOffset = target.style.webkitTransform.match(/(-?\d+)/)
        oldOffset = +(oldOffset?[0]) || 0

    scrollToView:(offset)->
        oldOffset = @getScrollOffset()
        @setScrollOffset(offset + oldOffset)
        @

    setScrollOffset:(offset)->
        @getScrollableItem().style.webkitTransform = "translateY(#{offset}px)"
        @

    resetScrollOffset:->
        @gridOffset = 0
        @getScrollableItem().style.webkitTransform = ''
        @

    scrollCallback:(e)=>
        if not inView(selector.selectedItem)
            selector.update(null)

        scrollable = @getScrollableItem()

        oldOffset = @getScrollOffset()
        if oldOffset != 0
            @gridOffset = oldOffset

        @gridOffset += e.wheelDeltaY / 2
        offset = @box.clientHeight - scrollable.clientHeight

        if @gridOffset < offset
            @gridOffset = offset
        else if @gridOffset > 0
            @gridOffset = 0

        scrollable.style.webkitTransform = "translateY(#{@gridOffset}px)"

        offset = 0
        l = scrollable.childNodes.length
        scrollTop = -@gridOffset
        for i in [0...l]
            if scrollable.childNodes[i].style.display == 'none'
                continue
            candidateId = scrollable.childNodes[i].dataset.catid
            if scrollTop - offset < 0
                # console.log "less #{id} #{$("##{id}").firstChild.firstChild.textContent}"
                @setMask(Page.MaskHint.TopBottom)
                categoryBar.focusCategory(cid)
                break
            else if scrollTop - offset == 0
                cid = scrollable.childNodes[i].dataset.catid
                # console.log "equal #{id} #{$("##{id}").firstChild.firstChild.textContent}"
                if cid == "-2"
                    @setMask(Page.MaskHint.None)
                else
                    @setMask(Page.MaskHint.BottomOnly)
                categoryBar.focusCategory(cid)
                break
            else
                cid = candidateId
                offset += scrollable.childNodes[i].clientHeight + CATEGORY_LIST_ITEM_MARGIN

        return
