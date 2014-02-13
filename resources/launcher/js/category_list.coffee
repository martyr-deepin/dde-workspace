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
        @favor = null

        frag = document.createDocumentFragment()
        favors = daemon.GetFavors_sync()
        @favor = new Category(CATEGORY_ID.FAVOR, "favor", favors.map((e)->e[0]))
        @favor.show().hideHeader()
        frag.appendChild(@favor.element)
        # infos.unshift([CATEGORY_ID.FAVOR, "favor", favors])

        for info in infos
            id = info[0]
            name = info[1]
            items = info[2]
            @categories[id] = new Category(id, name, items)
            frag.appendChild(@categories[id].element)
            if items.length == 0
                @categories[id].hide()

        @categories[CATEGORY_ID.FAVOR] = @favor
        @blank = create_element(tag:'div', id:'blank', frag)
        $("#grid").appendChild(frag)

        @favor.setNameDecoration()
        for info in infos
            id = info[0]
            @categories[id].setNameDecoration()

    updateBlankHeight:->
        containerHeight = $("#container").clientHeight
        otherHeight = @categories[CATEGORY_ID.OTHER].element.clientHeight
        @blank.style.height = containerHeight - otherHeight - 40
        @

    showBlank: ->
        if @blank.style.display != 'block'
            @blank.style.display = 'block'

    hideEmptyCategory:->
        for own id, item of @categories
            all_is_hidden = item.every((el) ->
                applications[el].display_mode == "hidden"
            )
            if all_is_hidden and not Item.display_temp
                item.hide()
                $("##{CategoryItem.PREFIX}#{item.id}").style.display = "none"
                # if @selected_id == id
                #     @selected_id = CATEGORY_ID.ALL
                # grid_load_category(@selected_id)
        @

    showNonemtpyCategory:->
        if @favor.element.style.display == 'none'
            @favor.element.style.display = 'block'
        @favor.showHeader().setNameDecoration()
        for own id, category of @categories
            not_all_is_hidden = category.some((el) ->
                applications[el].display_mode != "hidden"
            )
            if not_all_is_hidden or Item.display_temp
                category.show()
                category.setNameDecoration()
                $("##{CategoryItem.PREFIX}#{category.id}").style.display = "block"
        @

    showFavorOnly:->
        for own k, v of @categories
                v.hide()

        @favor.show().hideHeader()
        @blank.style.display = 'none'
