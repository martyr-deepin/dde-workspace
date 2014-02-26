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
                @favors[id] = applications[id].observers.item

            if originIds.length != validIds.length
                echo 'save'
                @save()

        @

    save: ->
        keys = Object.keys(@favors)
        # echo "save #{keys}, is array: #{Array.isArray(keys)}, is string: #{typeof keys[0] == 'string'}"
        # daemon.SaveHiddenApps(keys)
        daemon.SaveFavors_sync(keys)
        @

    reset: ->
        @

    add: (id, item)->
        @favors[id] = item
        @updateCache = true
        @

    remove: (id)->
        if delete @favors[id]
            @updateCache = true
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
