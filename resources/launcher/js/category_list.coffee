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
        @favor = null
        @container = $("#grid")

        frag = document.createDocumentFragment()
        favors = daemon.GetFavors_sync()
        @favor = new Category(CATEGORY_ID.FAVOR, "favor", favors.map((e)->"#{e[0]}"))
        @favor.show().hideHeader()
        frag.appendChild(@favor.element)
        # infos.unshift([CATEGORY_ID.FAVOR, "favor", favors])

        for info in infos
            id = info[0]
            name = info[1]
            items = info[2]
            @categories[id] = new Category(id, name, items)
            frag.appendChild(@categories[id].element)
            if items.length == 0
                @categories[id].hide()

        @categories[CATEGORY_ID.FAVOR] = @favor
        @blank = create_element(tag:'div', id:'blank', frag)
        $("#grid").appendChild(frag)

        @favor.setNameDecoration()
        for info in infos
            id = info[0]
            @categories[id].setNameDecoration()

    updateBlankHeight:->
        containerHeight = $("#container").clientHeight
        c = @container.lastElementChild
        while (c = c.previousElementSibling)
            if c.style.display != 'none'
                lastHeight = c.clientHeight
        @blank.style.height = containerHeight - lastHeight - 20
        @

    showBlank: ->
        if @blank.style.display != 'block'
            @blank.style.display = 'block'

    hideEmptyCategories:->
        # TODO:
        for own id, item of @categories
            all_is_hidden = item.every((el) ->
                i = Widget.look_up(el)
                if i?
                    return i.displayMode == "hidden"
                else
                    return true
            )
            if all_is_hidden and not Item.display_temp
                item.hide()
                # hide category bar
                $("##{CategoryItem.PREFIX}#{id}").style.display = "none"
        @

    showNonemptyCategories:->
        # TODO
        minId = 100
        for own id, category of @categories
            not_all_is_hidden = category.some((el) ->
                Widget.look_up(el).displayMode != "hidden"
            )
            if not_all_is_hidden or Item.display_temp
                if id < minId
                    minId = id
                category.show()
                category.showHeader()
                category.setNameDecoration()
                # show category bar
                $("##{CategoryItem.PREFIX}#{id}").style.display = "block"
            else
                category.hide()
                $("##{CategoryItem.PREFIX}#{id}").style.display = "none"
        categoryBar.focusCategory(minId)
        @

    showFavorOnly:->
        for own k, v of @categories
            v.hide()

        @favor.show().hideHeader()
        @blank.style.display = 'none'

    addItem: (id, categories)->
        if !Array.isArray(categories)
            categories = [categories]
        for cat_id in categories
            @categories[cat_id].addItem(id)

    removeItem:(id, categories)->
        if typeof categories == 'undefined'
            echo 'remove from all categories'
            for own cid, item of @categories
                echo "remove from category##{cid}"
                item.removeItem(id)
            return

        if !Array.isArray(categories)
            categories = [categories]
        for cat_id in categories
            try
                @categories[cat_id].removeItem(id)
            catch e
                echo "CategoryList.removeItem: #{e}"

    category:(id)->
        return @categories[id] if @categories[id]?
        null

    firstCategory:->
        return @favor if @favor.isShown()
        echo "the first category is not favor"
        for id in [CATEGORY_ID.INTERNET..CATEGORY_ID.UTILITIES]
            if @categories[id].isShown()
                return @categories[id]
        return null

    lastCategory:->
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

        if @favor.isShown()
            return @favor

        return null
