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
            class:"category_item_base category_item_board category-mask",
            @element
        )
        @element.style.backgroundImage = "url(img/category/#{@name}100.png)"
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

        @category = $("#categoryBar")
        @category.addEventListener("click", (e) =>
            e.stopPropagation()
            target = e.target.parentNode
            id = parseInt(target.getAttribute("catId"))
            if !isNaN(id)
                console.log("selected id: #{@selectedId}, click id: #{id}")
                grid.style.webkitMask = ""
                categoryList.scroll(@selectedId, id)
                @focusCategory(id)
        )

        @category_items = {}
        @load(infos)

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

    focusCategory: (id) =>
        # console.log "selectedId: #{@selectedId}, id: #{id}"
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
