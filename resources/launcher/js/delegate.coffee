#Copyright (c) 2011 ~ 2013 Deepin, Inc.
#              2013 ~ 2013 Li Liqiang
#
#Author:      Li Liqiang <liliqiang@linuxdeepin.com>
#Maintainer:  Li Liqiang <liliqiang@linuxdeepin.com>
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


DEvent = (e)->
    target = e.target
    parent = target.parentNode
    element = null
    id = null
    # console.log target.tagName
    # target is hoverBoxOutter
    if target.tagName == "IMG"
        p = parent.parentNode
        id = p.dataset.appid
        element = p
    else if target.tagName == "DIV"
        if target.classList.contains("Item")
            # id = target.dataset.appid
            # element = target.firstElementChild
        else if parent.classList.contains("Item")
            id = parent.firstElementChild.dataset.appid
            element = target
        else if target.classList.contains("hoverBox")
            id = parent.dataset.appid
            element = parent
        else if target.classList.contains("item_name")
            id = parent.parentNode.dataset.appid
            element = parent.parentNode

    id: id, target: element, originalEvent: e


delegateFactory = (fn)->
    (e)->
        event = DEvent(e)
        if event.id? && (item = Widget.look_up(event.id))?
            fn(event, item)

clickDelegate = delegateFactory((e, item)->
    item.on_click(e)
)

menuDelegate = delegateFactory((e, item)->
    item.on_rightclick(e)
)

mouseOutDelegate = delegateFactory((e, item)->
    item.on_mouseout(e)
)

mouseOverDelegate = delegateFactory((e, item)->
    item.on_mouseover(e)
)

dragStartDelegate = delegateFactory((e, item)->
    item.on_dragstart(e)
)

dragEndDelegate = delegateFactory((e, item)->
    item.on_dragend(e)
)

_c.addEventListener("contextmenu", menuDelegate)
_c.addEventListener("click", clickDelegate)
_c.addEventListener("mouseout", mouseOutDelegate)
_c.addEventListener("mouseover", mouseOverDelegate)
_c.addEventListener("dragstart", dragStartDelegate)
_c.addEventListener("dragend", dragEndDelegate)
