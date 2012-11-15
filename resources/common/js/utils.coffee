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

#disable default body drop event
document.body.ondrop = (e) -> e.preventDefault()
