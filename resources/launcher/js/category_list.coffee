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


class CategoryList
    constructor:(infos)->
        @categories = {}
        @container = $("#grid")

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
        $("#grid").appendChild(frag)

        for info in infos
            id = info[0]
            @categories[id].setNameDecoration()

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
            if category.number() != 0
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

    doListScroll:=>
        if @direction == "up"
            if @currentOffset >= @finalOffset
                @finishScroll()
                return
        else
            if @currentOffset <= @finalOffset
                @finishScroll()
                return

        $("#grid").scrollTop = @currentOffset - SEARCH_BAR_HEIGHT
        # @currentOffset += @step
        if @direction == "up"
            @currentOffset += @step
        else
            @currentOffset -= @step

        @scrollId = webkitRequestAnimationFrame(@doListScroll)

    fixOffset:(id)->
        console.log "fixOffset"
        children = $("#grid").childNodes
        offset = 0
        for i in [0...children.length]
            if children[i].style.display == 'none'
                continue

            if children[i].getAttribute("catId") == "#{id}"
                @finalOffset = offset
                break

            offset += children[i].clientHeight + CATEGORY_LIST_ITEM_MARGIN

    scroll: (currentId, targetId)->
        @currentOffset = $("##{Category.PREFIX}#{currentId}").offsetTop
        if "#{currentId}" == "#{targetId}"
            @fixOffset(targetId)
        else
            @finalOffset = $("##{Category.PREFIX}#{targetId}").offsetTop
        offset = @finalOffset - @currentOffset
        if Math.abs(offset) > ITEM_HEIGHT*2 then @step = 80 else @step = 40
        # @step = offset / 40
        @direction = if offset > 0 then "up" else "down"
        @doListScroll()

    cancelScroll:->
        if @scrollId
            webkitCancelAnimationFrame(@scrollId)
            @scrollId = null

    finishScroll:->
        @cancelScroll()
        if @currentOffset != @finalOffset
            $("#grid").scrollTop = @finalOffset - SEARCH_BAR_HEIGHT
