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
    constructor:()->
        @searchBar = $("#search")
        @key = $("#searchKey")
        DCore.signal_connect("im_commit", (info)=>
            if @value(@value() + info.Content)
                console.log 'search from im'
                switcher.switchToSearch()
                @search()
        )
        @searchTimer = null

    hide: ->
        if @searchBar.style.visibility != 'hidden'
            @searchBar.style.visibility = 'hidden'
        @

    show: ->
        if @searchBar.style.visibility != 'visible'
            @searchBar.style.visibility = 'visible'
        @

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
            # startTime = new Date()
            console.log "searchKey is : #{@value()}"
            daemon.Search(@value())
        , 100)
