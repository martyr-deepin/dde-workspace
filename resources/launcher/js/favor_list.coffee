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


class FavorList
    constructor: ->
        # key: id of app
        # value: a list of category id to which key belongs
        @favors = {}

        @updateCache = true
        @favorNumber = 0
        @isShown = false

        @load()

    load: ->
        if (originIds = daemon.GetFavors_sync())?
            validIds = originIds.filter((elem) ->
                applications[elem]?
            )
            @favors = {}
            @favorNumber = validIds.length
            @updateCache = false
            for id in validIds
                # echo applications[id].name
                @favors[id] = applications[id]
                @favors[id].isFavor = true

            echo "originIds: ##{originIds.length}#, typeof: #{typeof originIds.length}"
            echo "validIds: ##{originIds.length}#, typeof: #{typeof validIds.length}"
            echo "#{originIds.length != validIds.length}"
            if parseInt(originIds.length) != parseInt(validIds.length)
                echo "originIds: ##{originIds.length}#"
                echo "validIds: ##{originIds.length}#"
                echo 'save'
                @save()

        @

    save: ->
        apps = []
        # TODO
        container = categoryList.favor.grid
        for i in [0...container.children.length]
            el = container.children[i]
            echo "save favor: "
            echo el
            apps.push([el.getAttribute('appid'), i, false])
        try
            daemon.SaveFavors_sync(apps)
        @

    reset: ->
        @

    add: (id)->
        item = Widget.look_up(id)
        item.add("favor")
        categoryList.showNonemptyCategories()
        @favors[id] = item
        @updateCache = true
        @save()
        @

    remove: (id)->
        if delete @favors[id]
            item = Widget.look_up(id)
            item.remove('favor')
            @updateCache = true
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
