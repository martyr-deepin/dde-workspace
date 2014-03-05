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


class HiddenIcons
    constructor: ->
        # key: id of app
        # value: a list of category id to which key belongs
        @hiddenIcons = {}

        @updateCache = true
        @hiddenIconNumber = 0
        @isShown = false

        @load()

    load: ->
        if (originIds = daemon.LoadHiddenApps_sync())?
            validIds = originIds.filter((elem) ->
                applications[elem]?
            )
            @hiddenIcons = {}
            @hiddenIconNumber = validIds.length
            @updateCache = false
            for id in validIds
                # echo applications[id].name
                @hiddenIcons[id] = applications[id]

            if originIds.length != validIds.length
                echo 'save'
                @save()

        @

    save: ->
        keys = Object.keys(@hiddenIcons)
        # echo "save #{keys}, is array: #{Array.isArray(keys)}, is string: #{typeof keys[0] == 'string'}"
        daemon.SaveHiddenApps_sync(keys)
        @

    reset: ->
        @hide()

    add: (id, item)->
        @hiddenIcons[id] = item
        @updateCache = true
        @

    remove: (id)->
        if delete @hiddenIcons[id]
            @updateCache = true
        @

    update: ->
        @list = Object.keys(@hiddenIcons)
        @hiddenIconNumbe = @list.length
        @updateCache = false

    idList: ->
        if @updateCache
            @update()

        @list

    number: ->
        if @updateCache
            @update()
        @hiddenIconNumber

    show: ->
        # TODO:
        @isShown = true
        if searchBar.empty()
            # show category
            for own id of @hiddenIcons
                if id in categoryInfos[selectedCategoryId]
                    @hiddenIcons[id].displayIconTemp()
        else
            # re-search

    hide: ->
        # TODO:
        @isShown = false
        if searchBar.empty()
            # hide category
            for own id of @hiddenIcons
                @hiddenIcons[id]?.hide_icon()
        else
            # re-search

        @

    toggle: ->
        if @isShown
            @hide()
        else
            @show()
        @

    contains: (id)->
        @hiddenIcons.hasOwnProperty(id)
