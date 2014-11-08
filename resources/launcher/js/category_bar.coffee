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


class CategoryBar
    constructor: (infos, @displayMode, @sortMethod)->
        @selectedId = null

        @category = $("#categoryBar")
        @indicatorMask = create_element(tag:"div", id: "categoryIndicatorMask", document.body)
        @indicatorImg = create_element(tag:"img", src:"img/category_indicator.png", id:"categoryIndicator", @indicatorMask)
        @category.addEventListener("click", (e) =>
            e.stopPropagation()
            target = e.target
            id = parseInt(target.dataset.catid)
            if !isNaN(id)
                console.log("selected id: #{@selectedId}, click id: #{id}")
                grid.style.webkitMask = ""
                categoryList.scroll(@selectedId, id)
                @focusCategory(id)
        )

        @category_items = {}
        @load(infos)
        @changeDisplayMode(@displayMode)

        if @sortMethod != SortMethod.Method.ByCategory
            @hide()

    load: (infos)->
        for info in infos
            id = info[1]
            name = info[0]
            items = info[2]
            if id == CATEGORY_ID.ALL
                continue
            @category_items[id] = new CategoryItem(id, name, @displayMode)
            if items.length == 0
                @category_items[id].hide()
        frag = document.createDocumentFragment()
        for id in CATEGORY_ORDER
            frag.appendChild(@category_items[id].element)
        @category.appendChild(frag)
        @

    changeDisplayMode:(mode)->
        @category.className = ''
        if mode == CategoryDisplayMode.Mode.Text
            @category.classList.add('textCategoryBar')
            @indicatorMask.classList.remove("hide")
        else
            @indicatorMask.classList.add("hide")
            @category.classList.add('iconCategoryBar')
        for own id, item of @category_items
            item.changeDisplayMode(mode)

    show: ->
        if @sortMethod == SortMethod.Method.ByCategory && @category.style.display != 'block'
            @category.style.display = 'block'
            @indicatorImg.style.display = ''
        @

    hide: ->
        if @category.style.display != 'none'
            @category.style.display = 'none'
            @indicatorImg.style.display = 'none'
        @

    focusCategory: (id) =>
        # console.log "selectedId: #{@selectedId}, id: #{id}"
        if @selectedId != id
            @category_items[@selectedId]?.blur()
            @selectedId = id
            categoryItem = @category_items[id]
            if categoryItem
                categoryItem.focus()
                rect = categoryItem.getBoundingClientRect()
                @indicatorImg.style.top = rect.top - 2000 + rect.height/2

    dark:->
        for own k, v of @category_items
            v.dark()

    normal:->
        for own k, v of @category_items
            v.normal()
