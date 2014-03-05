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


class SearchBar
    constructor:->
        @searchBar = $("#search")
        @key = $("#searchKey")
        DCore.signal_connect("im_commit", (info)=>
            if @value(@value() + info.Content)
                echo 'search from im'
                switcher.switchToSearch()
                @search()
        )
        @searchTimer = null

    hide: ->
        if @searchBar.style.visibility != 'hidden'
            @searchBar.style.visibility = 'hidden'

    show: ->
        if @searchBar.style.visibility != 'visible'
            @searchBar.style.visibility = 'visible'
            selector.container($("#searchResult"))

    value: (t)->
        if t?
            @key.textContent = t
        else
            @key.textContent

    empty: ->
        @value() == ""

    clean:->
        @key.textContent = ""
        @

    cancel: ->
        clearTimeout(@searchTimer)
        @searchTimer = null
        @

    search: ->
        @cancel()
        @searchTimer = setTimeout(=>
            selector.clean()
            if !SearchResult.inited
                searchResult = new SearchResult()
            ids = daemon.Search_sync(@value())
            res = $("#searchResult")
            for i in [0...res.children.length]
                if res.children[i].style.display != 'none'
                    res.children[i].style.display = 'none'

            if ids.length == 0
                echo 'search: get nothing'
                return

            for i in [ids.length-1..0]
                if (item = Widget.look_up("#{ids[i]}"))?
                    # echo "search Item id: #{ids[i]}"
                    target = item.elements.search
                    res.removeChild(target)
                    res.insertBefore(target, res.firstChild)
                    target.style.display = '-webkit-box'

            if !searchResult.isShow()
                echo 'show result'
                searchResult.show()
                Item.updateHorizontalMargin()
        , 100)
