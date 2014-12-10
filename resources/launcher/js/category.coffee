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
        @element = create_element(tag:"div", class:"category", id:"#{Category.PREFIX}#{@id}", 'data-catid':"#{@id}")

        @header = create_element(tag:"header", class:"categoryHeader", @element)
        @nameNode = create_element(tag:"div", id:"cat#{@id}", class:"categoryName", @header)
        @nameNode.appendChild(document.createTextNode(_(@name)))
        @decoration = create_element(tag:"div", class:"categoryNameDecoration", @header)
        create_element(tag:"div", class:"blackLine", @decoration)
        create_element(tag:"div", class:"whiteLine", @decoration)

        @grid = create_element(tag:"div", class:"grid", @element)

        frag = document.createDocumentFragment()
        @sortItem()
        for id in @items
            if (item = Widget.look_up(id))?
                el = item.add(@id, frag)
                frag.appendChild(el)

        @grid.appendChild(frag)

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
            @grid.style.marginTop = "15px"
        @

    showHeader:->
        if @header.style.display != '-webkit-box'
            @header.style.display = '-webkit-box'
            @grid.style.marginTop = "20px"
        @

    some: (fn)->
        @items.some(fn)

    every:(fn)->
        @items.every(fn)

    number: ->
        count = 0
        c = @grid.children
        for i in [0...c.length]
            if c[i].style.display != "none"
                count += 1

        count

    addItem: (id)->
        item = Widget.look_up(id)
        # console.log item
        # console.log @items.indexOf(id)
        if item? && @items.indexOf(id) == -1
            console.log "add to category##{@id}"
            @items.push(id)
            el = item.add(@id)
            @grid.appendChild(el)
            return el
        null

    removeItem:(id)->
        if (item = Widget.look_up(id))?
            console.log "remove from category##{@id}"
            item.remove(@id)

        @items.remove(id)

    sortItem:->
        @items.sort(sortByNameCompare)

    sort:->
        @sortItem()
        for id in @items
            try
                item = Widget.look_up(id)
                element = item.getElement(@id)
                target = @grid.removeChild(element)
                @grid.appendChild(target, @grid.firstChild)
            catch e
                console.error(e)

    firstItem:->
        el = @grid.firstElementChild
        return null if not el
        if el.style.display != 'none'
            return el
        while (el = el.nextElementSibling)?
            if el.style.display != 'none'
                return el
        null

    firstItemInView:->
        el = @firstItem()
        if !el
            console.log("get first item failed")
            return el

        appid = el.dataset.appid
        if inView(el)
            return el

        while !!(el = el.nextElementSibling)
            if inView(el)
                return el

        console.log("no item in view")
        null

    lastItem:->
        el = @grid.lastElementChild
        if el.style.display != 'none'
            return el
            # return Widget.look_up(el.dataset.appid)
        while (el = el.previousElementSibling)?
            if el.style.display != 'none'
                return el
                # return Widget.look_up(el.dataset.appid)
        null
