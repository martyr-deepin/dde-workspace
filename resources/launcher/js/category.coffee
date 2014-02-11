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


class Category
    constructor:(@id, @name, @items)->
        if @id == -1
            echo @items
        @element = create_element(tag:"div", id:"c#{@id}")

        @header = create_element(tag:"header", class:"categoryHeader", @element)
        @nameNode = create_element(tag:"h4", id:"cat#{@id}", class:"categoryName", @header)
        @nameNode.appendChild(document.createTextNode(@name))
        @decoration = create_element(tag:"div", class:"categoryNameDecoration", @header)
        create_element(tag:"div", class:"blackLine", @decoration)
        create_element(tag:"div", class:"whiteLine", @decoration)

        @grid = create_element(tag:"div", class:"grid", @element)

        frag = document.createDocumentFragment()
        for id in @items
            if @id == -1
                echo applications[id].name
                frag.appendChild(applications[id].favorElement)
            else
                frag.appendChild(applications[id].element)
        @grid.appendChild(frag)

    setNameDecoration: ->
        MARGIN_TO_NAME = 10
        width = "#{@header.clientWidth - @nameNode.clientWidth - MARGIN_TO_NAME}px"
        @decoration.style.width = width
        @decoration.firstChild.style.width = width
        @decoration.lastChild.style.width = width

    hide: ->
        @element.style.display = 'none'

    show:->
        @element.style.display = 'block'
