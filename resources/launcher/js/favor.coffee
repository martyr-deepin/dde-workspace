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

        @load()
        Item.updateHorizontalMargin()

    load: ->
        if (origins = daemon.GetFavors_sync())?
            valids = origins.filter((elem) ->
                id = elem[0]
                applications[id]?
            )
            @favors = {}
            @favorNumber = valids.length
            @updateCache = false
            frag = document.createDocumentFragment()
            valids.sort((lhs, rhs)->
                parseInt(lhs[1]) - parseInt(rhs[1])
            )
            for i in valids
                @doAdd(i[0], i[1], i[2])

            if origins.length != valids.length
                @save()

        @

    save: ->
        apps = []
        # TODO
        container = @element
        for i in [0...container.children.length]
            el = container.children[i]
            # console.log "save favor: "
            # console.log el
            apps.push([el.dataset.appid, i, false])
        console.log 'save favor list'
        # console.log apps
        daemon.SaveFavors_sync(apps)

    reset: ->
        @

    doAdd: (id, index, fixed=false)->
        index = @element.childElementCount if not index?
        item = Widget.look_up(id)
        # console.log "add #{item.name} to favor"
        el = item.add('favor', @element)
        el.dataset.index = index
        el.dataset.fixed = fixed
        # console.log el
        @favors[id] = item
        @updateCache = true
        Item.updateHorizontalMargin()
        true

    add: (id, index, fixed)->
        if @doAdd(id, index, fixed)
            @save()
            return true
        false

    doRemove:(id)->
        if delete @favors[id]
            Widget.look_up(id).remove('favor')
            @updateCache = true
            return true
        false

    remove: (id)->
        if @doRemove(id)
            @save()
            return true
        false

    update: ->
            @list = Object.keys(@favors)
            @favorNumber = @list.length
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
