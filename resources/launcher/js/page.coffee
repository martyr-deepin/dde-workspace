#Copyright (c) 2011 ~  Deepin, Inc.
#              2013 ~ Lee Liqiang
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


# TODO: much more abstract
class Page
    @MaskHint:
        TopOnly: "topOnlyMask"
        BottomOnly: "bottomOnlyMask"
        TopBottom: "topBottomMask"
        None: null
    constructor:(@id)->
        @box = $("##{@id}")
        @box.addEventListener('scroll', @scrollCallback)
        @container = create_element(tag:"div", @box)
        @hint = Page.MaskHint.BottomOnly
        Widget.object_table[@id] = @

    show: ->
        @box.style.display = 'block'
        @

    hide:->
        @box.style.display = "none"
        @

    isShow:->
        @box.style.display == 'block'

    doSetMask:(hint)->
        if @hint == hint
            return
        @box.classList.remove(Page.MaskHint.TopOnly)
        @box.classList.remove(Page.MaskHint.BottomOnly)
        @box.classList.remove(Page.MaskHint.TopBottom)
        @hint = hint
        if hint != Page.MaskHint.None
            @box.classList.add(hint)
        @

    setMask:(hint)->
        @doSetMask(hint)

        if not selector.selectedItem
            return @

        selectedItemRect = selector.selectedItem.getBoundingClientRect()
        containerRect = _c.getBoundingClientRect()
        if selectedItemRect.bottom == containerRect.bottom
            console.log("selected item on the bottom")
            @doSetMask(Page.MaskHint.TopOnly)

        @

    scrollCallback:(e)=>
        if not inView(selector.selectedItem)
            selector.update(null)

        if @box.scrollTop == 0
            @setMask(Page.MaskHint.BottomOnly)
        else if @box.scrollTop + @box.clientHeight == @box.scrollHeight
            @setMask(Page.MaskHint.TopBottom)
        else
            @setMask(Page.MaskHint.TopBottom)

    getBox:->
        @box

    getFirstItem: ->
        @box.firstElementChild.firstElementChild

    getFirstItemInView:->
        el = @getFirstItem()
        if inView(el)
            return el

        while (el = el.nextElementSibling)
            if inView(el)
                break

        el

    getScrollableItem:->
        @box.firstElementChild

    setScrollOffset:(offset)->
        @box.scrollTop = offset
        @

    getScrollOffset:->
        @box.scrollTop

    scrollToView:(offset)->
        @setScrollOffset(@getScrollOffset() - offset)
        @

    resetScrollOffset:->
        @setScrollOffset(0)
        @
