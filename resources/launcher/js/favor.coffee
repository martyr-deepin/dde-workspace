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


class FavorPage
    constructor: ->
        # key: id of app
        # value: a list of category id to which key belongs
        @favors = {}

        @element = $("#favor")

        @updateCache = true
        @favorNumber = 0
        @isShown = false

        @load()
        Item.updateHorizontalMargin()

    load: ->
        if (originIds = daemon.GetFavors_sync())?
            validIds = originIds.filter((elem) ->
                id = elem[0]
                applications[id]?
            )
            @favors = {}
            @favorNumber = validIds.length
            @updateCache = false
            frag = document.createDocumentFragment()
            for i in validIds
                @doAdded(i[0], i[1], i[2])
                # el = categoryList.favor.addItem(i[0])
                # el?.setAttribute("index", i[1])
                # el?.setAttribute("fixed", i[2])

            if originIds.length != validIds.length
                @save()

        @

    save: ->
        apps = []
        # TODO
        container = favor.element
        for i in [0...container.children.length]
            el = container.children[i]
            # echo "save favor: "
            echo el
            apps.push([el.getAttribute('appid'), i, false])
        echo 'save favor list'
        # echo apps
        daemon.SaveFavors_sync(apps)

    reset: ->
        @

    doAdded: (id, index, fixed=false)->
        index = @element.childElementCount if not index?
        item = Widget.look_up(id)
        echo "add #{item.name} to favor"
        el = item.add('favor', @element)
        el.setAttribute("index", index)
        el.setAttribute("fixed", fixed)
        # echo el
        @favors[id] = item
        @updateCache = true
        true

    add: (id, index, fixed)->
        if @doAdded(id, index, fixed)
            @save()
        @

    doRemove:(id)->
        if delete @favors[id]
            Widget.look_up(id).remove('favor')
            @updateCache = true
            return true
        false

    remove: (id)->
        if @doRemove(id)
            @save()
        @

    update: ->
            @list = Object.keys(@favors)
            @hiddenIconNumbe = @list.length
            @updateCache = false

    idList: ->
        if @updateCache
            @update()

        @list

    number: ->
        if @updateCache
            @update()
        @favorNumber

    contains: (id)->
        @favors.hasOwnProperty(id)

    hide:->
        if @element.style.display != 'none'
            @element.style.display = 'none'

    show:->
        if @element.style.display != 'block'
            @element.style.display = 'block'
