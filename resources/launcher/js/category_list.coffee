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


class CategoryListWithCategory extends Page
    constructor:(infos, @sortMethod)->
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
        @finalOffset = 0
        for info in infos
            id = info[1]
            name = info[0]
            items = info[2]
            if id == CATEGORY_ID.ALL
                continue
            @categories[id] = new Category(id, name, items)
            if items.length == 0
                @categories[id].hide()

        frag = document.createDocumentFragment()
        for id in CATEGORY_ORDER
            frag.appendChild(@categories[id].element)
        @blank = create_element(tag:'div', id:'blank', frag)
        @container.appendChild(frag)
        Item.updateHorizontalMargin()
        @hideEmptyCategories()
        @updateBlankHeight()
        $("#grid").style.overflowY = "hidden"

        appIds = daemon.GetAllNewInstalledApps_sync()
        for id in appIds
            Widget.look_up(id)?.showNewInstallIndicator(id)

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
        if @sortMethod != SortMethod.Method.ByCategory
            return @
        for own id, category of @categories
            categoryItem = $("##{CategoryItem.PREFIX}#{id}")
            if category.number() != 0
                category.show()
                category.showHeader()
                # show category bar
                if categoryItem.style.display != 'block'
                    categoryItem.style.display = "block"
            else
                category.hide()
                if categoryItem.style.display != "none"
                    categoryItem.style.display = "none"
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
                console.error "CategoryList.removeItem: #{e}"

    sort:(categories)->
        for cat_id in categories
            try
                @categories[cat_id].sort()
            catch e
                console.error "CategoryList.removeItem: #{e}"

    category:(id)->
        return @categories[id] if @categories[id]?
        null

    firstCategory:=>
        if @sortMethod != SortMethod.Method.ByCategory
            return null
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

        i = id + 1
        while i <= CATEGORY_ID.UTILITIES
            if @categories[i].isShown()
                return @categories[i]
            i += 1

        if @categories[CATEGORY_ID.OTHER].isShown()
            return @categories[CATEGORY_ID.OTHER]

        return null

    previousCategory:(id)->
        return null if id == CATEGORY_ID.INTERNET

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

    reset:()->
        @resetScrollOffset()
        @box.removeEventListener("mousewheel", @scrollCallback)

    resetScrollOffset:->
        @gridOffset = 0
        @getScrollableItem().style.webkitTransform = ''
        @setMask(Page.MaskHint.BottomOnly)
        @

    scrollCallback:(e)=>
        if not inView(selector.selectedItem)
            selector.update(null)

        scrollable = @getScrollableItem()
        # console.log(scrollable)

        oldOffset = @getScrollOffset()
        # console.log("old offset: #{oldOffset}")
        if oldOffset != 0
            @gridOffset = oldOffset

        @gridOffset += e.wheelDeltaY / 2
        offset = @box.clientHeight - scrollable.clientHeight
        # console.log("new offset: #{@gridOffset}")
        # console.log("box clientHeight: #{@box.clientHeight}, scrollable: #{scrollable.clientHeight}")
        # console.log("gridOffset: #{@gridOffset}, offset: #{offset}")

        if @gridOffset < offset
            @gridOffset = offset
        else if @gridOffset > 0
            @gridOffset = 0

        # console.log("final offset is #{@gridOffset}")
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


class CategoryListWithoutCategory extends Page
    constructor:(infos, @sortMethod)->
        super("grid")

        frag = document.createDocumentFragment()
        for id in infos
            el = Widget.look_up(id).add(@id)
            frag.appendChild(el)
        @container.appendChild(frag)
        Item.updateHorizontalMargin()
        $("#grid").style.overflowY = ""

        appIds = daemon.GetAllNewInstalledApps_sync()
        for id in appIds
            Widget.look_up(id)?.showNewInstallIndicator(id)

    reset:()->
        @resetScrollOffset()

    addItem:(id)->
        item = Widget.look_up(id)
        if item? and not item.getElement(id)
            console.log "add #{item.id} to category##{@id}"
            el = item.add(@id)
            @container.appendChild(el)
            return el
        null

    sort:->
        list = getItemList(launcherSetting.getSortMethod())
        for i in [list.length-1..0]
            if (item = Widget.look_up(list[i]))?
                target = item.getElement(@id)
                @container.removeChild(target)
                @container.insertBefore(target, @container.firstChild)

    removeItem:(id)->
        if (item = Widget.look_up(id))?
            console.log "remove from category##{@id}"
            item.remove(@id)

makeCategoryList = (sortMethod)->
    $("#grid").innerHTML = ""
    list = getItemList(sortMethod)
    switch sortMethod
        when SortMethod.Method.ByName
            console.log("change to sort by name")
            return new CategoryListWithoutCategory(list, sortMethod)
        when SortMethod.Method.ByTimeInstalled
            console.log("change to sort by install time")
            return new CategoryListWithoutCategory(list, sortMethod)
        when SortMethod.Method.ByFrequency
            console.log("change to sort by frequency")
            return new CategoryListWithoutCategory(list, sortMethod)
        when SortMethod.Method.ByCategory
            return new CategoryListWithCategory(list, sortMethod)
