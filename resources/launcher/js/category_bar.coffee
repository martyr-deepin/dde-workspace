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
    constructor: (@id, name)->
        @element = create_element('div', 'category_name', null)
        @element.setAttribute('id', @id)
        @element.innerText = name

        @info = DCore.Launcher.get_items_by_category(@id)
        @sort()

    show:->
        @element.style.display = "block"

    hide:->
        @element.style.display = "none"

    focus: ->
        @element.classList.add("category_selected")
        # TODO
        # grid.load(@selected_id)

    blur: ->
        @element.classList.remove("category_selected")
        # TODO
        # grid.load(@selected_id)

    sort: ->
        # echo "#{config.sort_method}"
        SORT_METHOD[config.sort_method](@info)


class CategoryBar
    constructor:->
        @select_timer = -1
        @selected_id = ALL_APPLICATION_CATEGORY_ID

        @category = $("#category")
        @category.addEventListener("click", (e) ->
            e.stopPropagation()
        )

        @category.addEventListener("mouseover", (e)=>
            target = e.target
            id = parseInt(target.id)
            if !isNaN(id)
                @select_timer = setTimeout(=>
                    @category_items[@selected_id].blur()
                    @category_items[id].focus()
                    @selected_id = id
                )
        )

        @category.addEventListener("mouseout", (e)=>
            target = e.target
            if !isNaN(target.id) and @select_timer != 0
                clearTimeout(@select_timer)
                @select_timer = 0
        )

        @category_items = {}
        @load()

        # TODO
        # assgin
        # if (@is_pinned = DCore.Launcher.is_pinned())
        #     @show()
        #     @pin()
        # else
        #     # those are not needed.
        #     @unpin()
        #     @hide()
        # set animation effect

        @update_scroll_bar()

    load: ->
        frag = document.createDocumentFragment()
        for info in DCore.Launcher.get_categories()
            id = parseInt(info.ID)
            @category_items[id] = new CategoryItem(id, info.Name)
            frag.appendChild(@category_items[id].element)
        @category.appendChild(frag)
        @

    addItem: (id, name)->
        id = parsetInt(id, 10)
        if @category_items[id]?
            echo "category ##{id}# is existed"
            return @

        indicator = @category.lastChild
        for own _id, item of @category_items
            if _id != CATEGORY_ID.ALL and _id != CATEGORY_ID.OTHER and _id == id
                indicator = item.element
        @category_items[id] = new CategoryItem(id, name)
        @category.insertBefore(@category_items[id].element, indicator)
        @

    removeItem: (id)->
        if not @category_items[id]?
            echo "category ##{id} doesn't exist"
            return @

        @category_items[id].hide()
        target = @category_items[id].element
        target.parentNode.removeChild(target)
        @

    hide_empty_category:->
        for own id, item of @category_items
            all_is_hidden = item.info.every((el) ->
                applications[el].display_mode == "hidden"
            )
            if all_is_hidden and not Item.display_temp
                item.hide()
                if @selected_id == id
                    @selected_id = CATEGORY_ID.ALL
                grid_load_category(@selected_id)
        @

    show_nonempty_category:->
        for own id, item of @category_items
            not_all_is_hidden = item.some((el) ->
                applications[el].display_mode != "hidden"
            )
            if not_all_is_hidden or Item.display_temp
                item.show()
        @

    show: ->
        @

    hide: ->
        @

    pin: =>
        if not @is_pinned
            DCore.Launcher.pin(true)
            @is_pinned = true
        @

    unpin: =>
        if @is_pinned
            DCore.Launcher.pin(false)
            @is_pinned = false
        @

    update_scroll_bar: ->
        warp = @category.parentNode
        # add 20px for margin
        categories_height = @category.children.length * (@category.lastElementChild.clientHeight + 20)
        warp_height = window.screen.height - 100  # height of search bar
        if categories_height > warp_height
            warp.style.overflowY = "scroll"
            warp.style.marginBottom = "#{GRID_MARGIN_BOTTOM}px"
        @
