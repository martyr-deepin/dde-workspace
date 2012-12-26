#Copyright (c) 2011 ~ 2012 Deepin, Inc.
#              2011 ~ 2012 snyh
#
#Author:      snyh <snyh@snyh.org>
#Maintainer:  snyh <snyh@snyh.org>
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

Storage.prototype.setObject = (key, value) ->
    @setItem(key, JSON.stringify(value))

Storage.prototype.getObject = (key) ->
    JSON.parse(@getItem(key))

echo = (log) ->
    console.log log

assert = (value, msg) ->
    if not value
        throw new Error(msg)

_ = (s)->
    DCore.gettext(s)

Array.prototype.remove = (el)->
    i = this.indexOf(el)
    if i != -1
        this.splice(this.indexOf(el), 1)[0]

build_menu = (info) ->
    m = new DeepinMenu
    for v in info
        if v.length == 0
            i = new DeepinMenuItem(2, 0, 0, 0)
        else if typeof v[0] == "number"
            i = new DeepinMenuItem(0, v[0], v[1], null)
        else
            sm = build_menu(v[1])
            i = new DeepinMenuItem(1, 0, v[0], sm)
        m.appendItem(i)
    return m

get_page_xy = (el, x, y) ->
    p = webkitConvertPointFromNodeToPage(el, new WebKitPoint(x, y))

find_drag_target = (el)->
    p = el
    if p.draggable
        return p
    while p = el.parentNode
        if p.draggable
            return p
    return null

swap_element = (c1, c2) ->
    tmp = document.createElement('div')
    c1.parentNode.insertBefore(tmp, c1)
    c2.parentNode.insertBefore(c1, c2)
    tmp.parentNode.insertBefore(c2, tmp)
    tmp.parentNode.removeChild(tmp)

#disable default body drop event
document.body.ondrop = (e) -> e.preventDefault()

run_post = (f, self)->
    f2 = f.bind(self or this)
    setTimeout(f2, 0)

create_element = (type, clss, parent)->
    el = document.createElement(type)
    el.setAttribute("class", clss)
    if parent
        parent.appendChild(el)
    return el

create_img = (clss, src, parent)->
    el = create_element('img', clss, parent)
    el.src = src
    el.draggable = false
    return el

