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
        @toFavor = create_img(src:'img/favor_normal.png', class:"tipImage", title:'favor', alt:'favor', @switcher)
        @toFavorHover = create_img(src: "img/favor_hover.png", class:"tipImage", title:'favor', alt:'favor', @switcher)
        @toFavorGlow = create_img(src: "img/favor_glow.png", class:"tipImage", title:'favor', alt:'favor', @switcher)
        @toCategory = create_img(src:'img/category_normal.png', class:"tipImage", title:'all', alt:'all', @switcher)
        @toCategory.style.display = 'block'
        @toCategoryHover = create_img(src:'img/category_hover.png', class:"tipImage",title:'all', alt:'all', @switcher)
        @page = 'Favor'
        # TODO: mouse event is lost
        @switcher.addEventListener('click', @on_click)
        @switcher.addEventListener("mouseover", (e)=>
            switch @page
                when "Search", "Category"
                    @toFavor.style.display = 'none'
                    @toFavorHover.style.display = 'block'
                when "Favor"
                    @toCategory.style.display = 'none'
                    @toCategoryHover.style.display = 'block'
        )
        @switcher.addEventListener("mouseout", (e)=>
            switch @page
                when "Search", "Category"
                    @toFavor.style.display = 'block'
                    @toFavorHover.style.display = 'none'
                when "Favor"
                    @toCategory.style.display = 'block'
                    @toCategoryHover.style.display = 'none'
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
            favor.add(id)
        )

    on_click:(e)=>
        e.stopPropagation()
        e.preventDefault()
        if @isShowCategory
            @switchToFavor()
        else
            @switchToCategory()

    isInSearch:->
        @switcher.style.visibility == 'hidden'

    isFavor:->
        @page == "Favor"

    isCategory:->
        @page == "Category"

    switchToCategory:=>
        searchBar.clean().hide()
        selector.container($("#grid"))
        $("#grid").style.display = 'block'
        favor.hide()
        @isShowCategory = true
        categoryBar.show()
        if @toFavor.style.display != 'block'
            @toFavor.style.display = 'block'
        if @toFavorHover.style.display != 'none'
            @toFavorHover.style.display = 'none'
        if @toCategory.style.display != 'none'
            @toCategory.style.display = 'none'
        if @toCategoryHover.style.display != 'none'
            @toCategoryHover.style.display = 'none'
        # container.style.marginLeft = "#{categoryBar.category.clientWidth + 10}px"
        # e = new Event("mouseover")
        # @switcher.dispatchEvent(e)
        categoryList.showNonemptyCategories().updateBlankHeight().showBlank()
        Item.updateHorizontalMargin()
        searchResult?.hide()
        @page = "Category"

    switchToFavor:=>
        searchBar.clean()
        selector.container(favor.element)
        @isShowCategory = false
        categoryBar.hide()
        favor.show()
        $("#grid").style.display = 'none'
        if @toFavor.style.display != 'none'
            @toFavor.style.display = 'none'
        if @toFavorHover.style.display != 'none'
            @toFavorHover.style.display = 'none'
        if @toCategory != 'block'
            @toCategory.style.display = 'block'
        # e = new Event("mouseover")
        # @switcher.dispatchEvent(e)
        # container.style.marginLeft = "110px"
        # Item.updateHorizontalMargin()
        searchResult?.hide()
        @page = "Favor"

    switchToSearch:=>
        $("#grid").style.display = 'none'
        # if @isShowCategory
        #     @switchToFavor()
        categoryBar.hide()
        favor.hide()
        if @toFavor.style.display != 'block'
            @toFavor.style.display = 'block'
        if @toCategory.style.display != 'none'
            @toCategory.style.display = 'none'
        if @toCategoryHover.style.display != 'none'
            @toCategoryHover.style.display = 'none'
        searchBar.show()
        @page = "Search"

    hide:->
        @switcher.style.visibility = 'hidden'

    show:->
        @switcher.style.visibility = 'visible'
        selector.container(favor.element)

    normal:->
        if @page == "Category"
            @toFavor.style.display = 'block'
            @toFavorGlow.style.display = 'none'

    bright:->
        @toFavor.style.display = 'none'
        @toFavorGlow.style.display = 'block'
