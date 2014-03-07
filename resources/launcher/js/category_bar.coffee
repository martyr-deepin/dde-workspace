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


class CategoryItem
    @PREFIX: "cbi"
    constructor: (@id, @name)->
        @element = create_element(
            tag:'div',
            class:'category_item_base category_item',
            id: "#{CategoryItem.PREFIX}#{@id}",
            catId: "#{@id}"
        )
        create_element(
            tag:'div',
            class:"category_item_base category_item_bottom",
            parent: @element
        )
        @element.style.backgroundImage = "url(img/category/#{name}100.png)"
        @isFocus = false

    categoryId: ->
        parseInt(@element.getAttribute("catId"))

    show:->
        @element.style.display = "block"
        @

    hide:->
        @element.style.display = "none"
        @

    focus: ->
        @isFocus = true
        @element.style.webkitMask = "-webkit-linear-gradient(top, rgba(0,0,0,1), rgba(0,0,0,1))"

    blur: ->
        @isFocus = false
        @element.style.webkitMask = ""

    dark: ->
        @element.style.webkitMask = "-webkit-linear-gradient(top, rgba(0,0,0,0.3), rgba(0,0,0,0.1))"

    normal:->
        if @isFocus
            @focus()
        else
            @blur()


class CategoryBar
    constructor: (infos)->
        @selectedId = null

        @category = $("#category")
        @category.addEventListener("click", (e) =>
            e.stopPropagation()
            target = e.target
            id = parseInt(target.getAttribute("catId"))
            if !isNaN(id)
                categoryList.cancelScroll()
                categoryList.scroll(@selectedId, id)
        )

        @category_items = {}
        @load(infos)

        @update_scroll_bar()

    load: (infos)->
        frag = document.createDocumentFragment()
        for info in infos
            id = info[0]
            name = info[1]
            items = info[2]
            @category_items[id] = new CategoryItem(id, name)
            frag.appendChild(@category_items[id].element)
            if items.length == 0
                @category_items[id].hide()
        @category.appendChild(frag)
        @

    show: ->
        if @category.style.display != 'block'
            @category.style.display = 'block'
        @

    hide: ->
        if @category.style.display != 'none'
            @category.style.display = 'none'
        @

    update_scroll_bar: ->
        warp = @category.parentNode
        # top/bottom margin
        categories_height = @category.children.length * (@category.lastElementChild.clientHeight + 2*CATEGORY_BAR_ITEM_MARGIN)
        warp_height = window.screen.height - SEARCH_BAR_HEIGHT - GRID_MARGIN_BOTTOM  # height of search bar
        if categories_height > warp_height
            warp.style.overflowY = "scroll"
            warp.style.marginBottom = "#{GRID_MARGIN_BOTTOM}px"
        @

    focusCategory: (id) =>
        # echo "selectedId: #{@selectedId}, id: #{id}"
        if @selectedId != id
            @category_items[@selectedId]?.blur()
            @category_items[id]?.focus()
            @selectedId = id

    dark:->
        for own k, v of @category_items
            v.dark()

    normal:->
        for own k, v of @category_items
            v.normal()
