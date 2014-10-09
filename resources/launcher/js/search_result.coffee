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


class SearchResult extends Page
    inited: false
    constructor: ->
        console.log 'create search result'
        clearTimeout(searchTimer)
        searchTimer = null
        super("searchResult")

        frag = document.createDocumentFragment()
        for own k, v of applications
            el = v.add('search', frag)
            el.style.display = 'none'
        @container.appendChild(frag)
        SearchResult.inited = true
        console.log 'create search result done'

    append: (child)->
        @container.appendChild(child)

    update:(resultList)->
        for i in [0...@container.children.length]
            if @container.children[i].style.display != 'none'
                @container.children[i].style.display = 'none'

        if resultList.length == 0
            console.log 'search: get nothing'
            return

        for i in [resultList.length-1..0]
            if (item = Widget.look_up("#{resultList[i]}"))? and not uninstalling_apps[item.id]
                # console.log "search Item id: #{searchResult.result[i]}"
                target = item.elements.search
                @container.removeChild(target)
                @container.insertBefore(target, @container.firstChild)
                item.show()

        if !@isShow()
            console.log 'show result'
            @show()
            Item.updateHorizontalMargin()
