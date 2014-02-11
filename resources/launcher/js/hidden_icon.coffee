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
        @hidden_icons = {}

        @update_cache = true
        @hidden_icon_number = 0
        @is_shown = false

        @load()

    load: ->
        if (origin_ids = daemon.LoadHiddenApps_sync())?
            valid_ids = origin_ids.filter((elem) ->
                applications[elem]?
            )
            @save()
            @hidden_icon_number = valid_ids.length
            @update_cache = false
            for id in valid_ids
                # echo applications[id].name
                @hidden_icons[id] = applications[id]

        @

    save: ->
        # echo "save #{Object.keys(@hidden_icons)}"
        # daemon.SaveHiddenApps(Object.keys(@hidden_icons))
        @

    reset: ->
        @hide()

    add: (id, item)->
        @hidden_icons[id] = item
        @update_cache = true
        @

    remove: (id)->
        if delete @hidden_icons[id]
            @update_cache = true
        @

    id_list: ->
        if @update_cache
            @list = Object.keys(@hidden_icons)
            @hidden_icon_numbe = @list.length
            @update_cache = false

        @list

    number: ->
        if @update_cache
            @hidden_icon_number = @id_list().length
        @hidden_icon_number

    show: ->
        @is_shown = true
        if search_bar.empty()
            # show category
            for own id of @hidden_icons
                if id in category_infos[selected_category_id]
                    @hidden_icons[id].display_icon_temp()
        else
            # re-search

    hide: ->
        @is_shown = false
        if search_bar.empty()
            # hide category
            for own id of @hidden_icons
                @hidden_icons[id]?.hide_icon()
        else
            # re-search

    toggle: ->
        if @is_shown
            @hide()
        else
            @show()
        @
