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

class CategoryList
    constructor:(infos)->
        @categories = {}

        frag = document.createDocumentFragment()
        favors = daemon.GetFavors_sync()
        infos.unshift([CATEGORY_ID.FAVOR, "favor", favors])

        for info in infos
            id = info[0]
            name = info[1]
            items = info[2]
            @categories[id] = new Category(id, name, items)
            frag.appendChild(@categories[id].element)
            if items.length == 0 && id != CATEGORY_ID.FAVOR
                @categories[id].hide()

        create_element(tag:'div', id:'blank', frag)
        $("#grid").appendChild(frag)

        for info in infos
            id = info[0]
            @categories[id].setNameDecoration()

        infos.shift()
