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

class Switcher
    constructor:->
        @isShowCategory = false
        @switcher = create_element(tag:'div', id:'switcher', document.body)
        @toFavor = create_img(src:'img/favor.png', title: 'favor', alt:'favor', @switcher)
        @toCategory = create_img(src:'img/category.png', title: 'all', alt:'all', @switcher)
        @switcher.addEventListener('click', (e)=>
            e.stopPropagation()
            e.preventDefault()
            if @isShowCategory
                @switchToFavor()
            else
                @switchToCategory()
        )

        @switcher.addEventListener("dragover", (e)=>
            e.preventDefault()
        )
        @switcher.addEventListener("drop", (e)=>
            echo 'drop'
            e.preventDefault()
            e.stopPropagation()
            if !@isShowCategory
                return
            id = e.dataTransfer.getData("text/plain")
            favorList.add(id)
        )

    isInSearch:->
        @switcher.style.visibility == 'hidden'

    switchToCategory:=>
        selector.container($("#grid"))
        @isShowCategory = true
        categoryBar.show()
        if @toFavor.style.display != 'inline'
            @toFavor.style.display = 'inline'
        if @toCategory.style.display != 'none'
            @toCategory.style.display = 'none'
        container.style.marginLeft = "#{categoryBar.category.clientWidth + 10}px"
        categoryList.showNonemptyCategories().updateBlankHeight().showBlank()
        Item.updateHorizontalMargin()

    switchToFavor:=>
        selector.container(categoryList.favor.element.lastElementChild)
        @isShowCategory = false
        categoryBar.hide()
        categoryList.showFavorOnly()
        if @toFavor.style.display != 'none'
            @toFavor.style.display = 'none'
        if @toCategory != 'inline'
            @toCategory.style.display = 'inline'
        container.style.marginLeft = "110px"
        # Item.updateHorizontalMargin()

    switchToSearch:=>
        $("#grid").style.display = 'none'
        if @isShowCategory
            @switchToFavor()
        @hide()

    hide:->
        @switcher.style.visibility = 'hidden'

    show:->
        @switcher.style.visibility = 'visible'
        selector.container(categoryList.favor.element.lastElementChild)
