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


targetId = (e)->
    target = e.target
    id = null
    # echo target.tagName
    if target.tagName == "IMG"
        id = target.parentNode.id
    else if target.tagName == "DIV"
        if target.classList.contains("Item")
            id = target.id
        else if target.parentNode.classList.contains("Item")
            id = target.parentNode.id

    id


delegateFactory = (fn)->
    (e)->
        id = targetId(e)
        if id? && (item = Widget.look_up(id))?
            fn(e, id, item)

clickDelegate = delegateFactory((e, id, item)->
        item.on_click(e)
)

menuDelegate = delegateFactory((e, id, item)->
        item.on_rightclick(e)
)

mouseOutDelegate = delegateFactory((e, id, item)->
    item.on_mouseout(e)
)

mouseOverDelegate = delegateFactory((e, id, item)->
    item.on_mouseover(e)
)

dragStartDelegate = delegateFactory((e, id, item)->
    item.on_dragstart(e)
)
