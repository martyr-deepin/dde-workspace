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
    constructor: (@id, @name, @displayMode)->
        @element = create_element(
            tag:"div",
            id: "#{CategoryItem.PREFIX}#{@id}",
            "data-catid": "#{@id}"
        )
        @iconNode = create_element(
            tag:'div',
            class:'category_item_base category_item',
            'data-catid': "#{@id}",
        )
        create_element(
            tag:'div',
            class:"category_item_base category_item_board category-mask",
            'data-catid': "#{@id}",
            @iconNode
        )
        @iconNode.style.backgroundImage = "url(img/category/#{@name}100.png)"

        @nameNode = create_element(tag:"div", class:"category_text", 'data-catid': "#{@id}")
        @nameNode.textContent = _(@name)

        @element.appendChild(@iconNode)
        @element.appendChild(@nameNode)

        @isFocus = false

    categoryId: ->
        parseInt(@element.dataset.catid)

    changeDisplayMode:(mode)->
        @normal()
        @displayMode = mode
        switch @displayMode
            when CategoryDisplayMode.Mode.Icon
                @iconNode.style.display = ''
                @nameNode.style.display = 'none'
            when CategoryDisplayMode.Mode.Text
                @iconNode.style.display = 'none'
                @nameNode.style.display = ''

    show:->
        if @element.style.display != 'block'
            console.log(element)
            @element.style.display = "block"
        @

    hide:->
        if @element.style.display == "none"
            @element.style.display = "none"
        @

    focus: ->
        @isFocus = true
        @removeDark()
        @addFocus()

    blur: ->
        @isFocus = false
        @removeFocus()
        @removeDark()

    dark: ->
        @removeFocus()
        @addDark()

    removeDark:->
        @iconNode.classList.remove("category_item_dark")
        @nameNode.classList.remove("category_text_dark")
        @iconNode.classList.remove("category_item_focus_dark")
        @nameNode.classList.remove("category_text_focus_dark")

    addDark:->
        if @isFocus
            @iconNode.classList.add("category_item_focus_dark")
            @nameNode.classList.add("category_text_focus_dark")
        else
            @iconNode.classList.add("category_item_dark")
            @nameNode.classList.add("category_text_dark")

    removeFocus:->
        @iconNode.classList.remove("category_item_focus")
        @nameNode.classList.remove("category_text_focus")

    addFocus:->
        @iconNode.classList.add("category_item_focus")
        @nameNode.classList.add("category_text_focus")

    normal:->
        if @isFocus
            @focus()
        else
            @blur()

    getBoundingClientRect:->
        @element.getBoundingClientRect()
