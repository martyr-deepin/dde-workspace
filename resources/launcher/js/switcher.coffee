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
        @switcherHood = create_element(tag:'div', id:"switcher_hood", document.body)
        @switcherHover = create_element(tag:'div', id:"switcher_hover", class:"notify", document.body)
        @img = create_img(src: 'img/favor_normal.png', id:'notify',class:"switcher_hover notify", document.body)
        @img.addEventListener("webkitAnimationEnd", =>
            @img.style.webkitAnimationName = ''
        )
        @switcherHover.addEventListener("webkitAnimationEnd", =>
            @switcherHover.style.webkitAnimationName = ''
            @switcherHover.style.webkitBoxShadow = ""
        )
        @showCategory()
        @page = 'Favor'
        @isHovered = false
        @switcherHood.addEventListener('click', @on_click)
        @switcherHover.addEventListener('click', @on_click)
        @switcherHover.addEventListener("mouseover", (e)=>
            @isHovered = true
            switch @page
                when "Search", "Category"
                    @showFavorHover()
                when "Favor"
                    @showCategoryHover()
        )
        @switcherHover.addEventListener("mouseout", (e)=>
            @isHovered = false
            switch @page
                when "Search", "Category"
                    @showFavor()
                when "Favor"
                    @showCategory()
        )

        @switcherHover.addEventListener("dragover", (e)=>
            e.preventDefault()
        )
        @switcherHover.addEventListener("drop", (e)=>
            console.log 'drop'
            e.preventDefault()
            e.stopPropagation()
            if @isFavor()
                return
            id = e.dataTransfer.getData("text/plain")
            if favor.add(id)
                @addedToFavor = true
                @notify()
        )

    on_click:(e)=>
        e.stopPropagation()
        e.preventDefault()
        if @page != "Favor"
            @switchToFavor()
        else
            @switchToCategory()

    isInSearch:->
        @switcher.style.visibility == 'hidden'

    isFavor:->
        @page == "Favor"

    isCategory:->
        @page == "Category"

    showCategory:->
        @switcher.style.backgroundPosition = "0 -#{SWITCHER_WIDTH}px"

    showCategoryHover:->
        @switcher.style.backgroundPosition = "-#{SWITCHER_WIDTH}px -#{SWITCHER_WIDTH}px"

    showFavor:->
        @switcher.style.backgroundPosition = ""

    showFavorHover:->
        @switcher.style.backgroundPosition = "-#{SWITCHER_WIDTH}px 0px"

    showFavorGlow:->
        @switcher.style.backgroundPosition = "-#{SWITCHER_WIDTH * 2}px 0px"

    switchToCategory:=>
        searchBar.hide().clean()
        selector.container(categoryList)
        favor.hide().resetScrollOffset().setMask(Page.MaskHint.BottomOnly)
        categoryList.show()
        categoryList.getBox().offsetTop
        @isShowCategory = true
        if @isHovered
            @showFavorHover()
        else
            @showFavor()
        categoryBar.show()
        categoryBar.focusCategory(categoryList.firstCategory()?.id)
        Item.updateHorizontalMargin()
        categoryList
            .showNonemptyCategories()
            .updateBlankHeight()
            .updateNameDecoration()
            .showBlank()
        searchResult?.hide().resetScrollOffset().setMask(Page.MaskHint.BottomOnly)
        @page = "Category"

    switchToFavor:=>
        searchBar.hide().clean()
        selector.container(favor)
        @isShowCategory = false
        categoryBar.hide()
        categoryList.hide()
            .resetScrollOffset()
            .setMask(Page.MaskHint.BottomOnly)
        favor.show()
        if @isHovered
            @showCategoryHover()
        else
            @showCategory()
        Item.updateHorizontalMargin()
        searchResult?.hide()
            .resetScrollOffset()
            .setMask(Page.MaskHint.BottomOnly)
        @page = "Favor"

    switchToSearch:=>
        categoryBar.hide()
        favor.hide()
            .resetScrollOffset()
            .setMask(Page.MaskHint.BottomOnly)
        categoryList.hide()
            .resetScrollOffset()
            .setMask(Page.MaskHint.BottomOnly)
        if @isHovered
            @showFavorHover()
        else
            @showFavor()
        searchBar.show()
        @page = "Search"
        @isShowCategory = false
        selector.container(searchResult)

    hide:->
        @switcher.style.visibility = 'hidden'

    show:->
        @switcher.style.visibility = 'visible'
        selector.container(favor)

    normal:->
        if @page == "Category"
            @showFavor()

    bright:->
        @showFavorGlow()

    notify:->
        @img.style.webkitAnimationName = 'Separate'
        @switcherHover.style.webkitAnimationName = 'Separate'
        @switcherHover.style.webkitBoxShadow = "0 0 2px rgba(255,255,255,0.6)"
