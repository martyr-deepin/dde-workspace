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
            class:'category_name',
            id: "#{CategoryItem.PREFIX}#{@id}",
            catId: "#{@id}"
        )
        @element.innerText = @name

    categoryId: ->
        parseInt(@element.getAttribute("catId"))

    show:->
        @element.style.display = "block"
        @

    hide:->
        @element.style.display = "none"
        @

    focus: ->
        @element.classList.add("category_selected")
        # TODO
        # grid.load(@selected_id)

    blur: ->
        @element.classList.remove("category_selected")
        # TODO
        # grid.load(@selected_id)


class CategoryBar
    constructor: (infos)->
        @select_timer = -1
        @selected_id = CATEGORY_ID.FAVOR

        @category = $("#category")
        @category.addEventListener("click", (e) =>
            e.stopPropagation()
            target = e.target
            id = parseInt(target.getAttribute("catId"))
            if !isNaN(id)
                offset = $("##{Category.PREFIX}#{id}").offsetTop
                # the scrollParent is body, so minus the search bar's height
                $("#grid").scrollTop = offset - SEARCH_BAR_HEIGHT
                # @showCategory(id)
        )

        @category_items = {}
        @load(infos)

        @category_items[@selected_id]?.focus()
        @update_scroll_bar()

    load: (infos)->
        frag = document.createDocumentFragment()
        @category_items[CATEGORY_ID.FAVOR] = new CategoryItem(CATEGORY_ID.FAVOR, "favor")
        frag.appendChild(@category_items[CATEGORY_ID.FAVOR].element)
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
        # add 20px for margin
        categories_height = @category.children.length * (@category.lastElementChild.clientHeight + 20)
        warp_height = window.screen.height - 120  # height of search bar
        if categories_height > warp_height
            warp.style.overflowY = "scroll"
            warp.style.marginBottom = "#{GRID_MARGIN_BOTTOM}px"
        @

    showCategory: (id) =>
        # echo "selected_id: #{@selected_id}, id: #{id}"
        if @selected_id != id
            @category_items[@selected_id]?.blur()
            @category_items[id]?.focus()
            @selected_id = id
