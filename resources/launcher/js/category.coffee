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


class Category
    @PREFIX:"ci"
    constructor:(@id, @name, @items)->
        @element = create_element(tag:"div", class:"category", id:"#{Category.PREFIX}#{@id}", catId:"#{@id}")

        @header = create_element(tag:"header", class:"categoryHeader", @element)
        @nameNode = create_element(tag:"h4", id:"cat#{@id}", class:"categoryName", @header)
        @nameNode.appendChild(document.createTextNode(@name))
        @decoration = create_element(tag:"div", class:"categoryNameDecoration", @header)
        create_element(tag:"div", class:"blackLine", @decoration)
        create_element(tag:"div", class:"whiteLine", @decoration)

        @grid = create_element(tag:"div", class:"grid", @element)

        frag = document.createDocumentFragment()
        for id in @items
            frag.appendChild(Widget.look_up(id).element)
            # if @id == CATEGORY_ID.FAVOR
            #     # prefix "fa_"
            #     frag.appendChild(applications[id.substr(3)].favorElement)
            # else
            #     frag.appendChild(applications[id].element)
        @grid.appendChild(frag)

    setNameDecoration: ->
        MARGIN_TO_NAME = 10
        width = "#{@header.clientWidth - @nameNode.clientWidth - MARGIN_TO_NAME}px"
        @decoration.style.width = width
        @decoration.firstChild.style.width = width
        @decoration.lastChild.style.width = width
        @

    isShown: ->
        @element.style.display != "none"

    hide: ->
        if @element.style.display != 'none'
            @element.style.display = 'none'
        @

    show:->
        if @element.style.display != 'block'
            @element.style.display = 'block'
        @

    hideHeader:->
        if @header.style.display != 'none'
            @header.style.display = 'none'
            @grid.style.marginTop = "10px"
        @

    showHeader:->
        if @header.style.display != '-webkit-box'
            @header.style.display = '-webkit-box'
            @grid.style.marginTop = "40px"
        @

    some: (fn)->
        @items.some(fn)

    every:(fn)->
        @items.every(fn)

    addItem: (id)->
        if (item = Widget.look_up(id))? && @items.indexOf(id) == -1
            @items.push(id)
            @grid.appendChild(item.element)
            @sort()

    removeItem:(id)->
        if (item = Widget.look_up(id))?
            @grid.removeChild(item.element)
        if @items.indexOf(id) != -1
            @items.remove(id)

    sort:->
        # TODO: sort by name

    firstItem:->
        el = @grid.firstElementChild
        if el.style.display != 'none'
            return Widget.look_up(el.getAttribute("appid"))
        while (el = el.nextElementSibling)?
            if el.style.display != 'none'
                return Widget.look_up(el.getAttribute("appid"))
        null

    lastItem:->
        el = @grid.lastElementChild
        if el.style.display != 'none'
            return Widget.look_up(el.getAttribute("appid"))
        while (el = el.previousElementSibling)?
            if el.style.display != 'none'
                return Widget.look_up(el.getAttribute("appid"))
        null
