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
    constructor:(@setting)->
        @isShowCategory = @setting.getSortMethod() == SortMethod.Method.ByCategory
        @switcher = create_element(tag:'div', id:'switcher', document.body)
        @switcher.addEventListener("click", (e)->
            e.stopPropagation()
            e.preventDefault()
        )
        @menu = new SettingMenu(@, @setting)
        @menu.setSelected(@setting.getSortMethod(), @setting.getCategoryDisplayMode())
        @switcher.appendChild(@menu.element)
        @page = 'Category'
        @isHovered = false
        @changeSetting(@setting.getSortMethod(), @setting.getCategoryDisplayMode())
        @timeoutId = null
        @bgShadow = create_element(tag:"img", id: "shadow", src:SWITCHER_SHADOW, document.body)
        @switcher.addEventListener("mouseover", (e)=>
            clearTimeout(@timeoutId)
            @switcher.classList.add("switcher_hover")
            @showShadow()
            categoryBar.dark()
        )
        @switcher.addEventListener("mouseout", (e)=>
            @timeoutId = setTimeout(=>
                @switcher.classList.remove("switcher_hover")
                @hideShadow()
                categoryBar.normal()
            , 500)
        )

    showShadow:=>
        if @bgShadow.style.opacity != '1'
            @bgShadow.style.opacity = '1'

    hideShadow:=>
        if @bgShadow.style.opacity != '0'
            @bgShadow.style.opacity = '0'

    changeSetting:(sortMethod, categoryDisplayMode)->
        @switcher.className = ""
        switch sortMethod
            when SortMethod.Method.ByName
                console.log("by name")
                break
            when SortMethod.Method.ByCategory
                console.log("by category")
                if categoryDisplayMode == CategoryDisplayMode.Mode.Text
                    @switcher.classList.add('setting1')
                else
                    @switcher.classList.add('setting1')
            when SortMethod.Method.ByTimeInstalled
                console.log("by time installed")
                @switcher.classList.add('setting2')
            when SortMethod.Method.ByFrequency
                console.log("by frequency")
                @switcher.classList.add('setting3')

    on_click:(e)=>
        e.stopPropagation()
        e.preventDefault()

    isInSearch:->
        @switcher.style.visibility == 'hidden'

    isCategory:->
        @page == "Category"

    switchToCategory:=>
        @hideMenu()
        @show()
        searchBar.hide().clean()
        selector.container(categoryList)
        categoryList.show()
        categoryList.getBox().offsetTop
        @isShowCategory = @setting.getSortMethod() == SortMethod.Method.ByCategory
        if @isShowCategory
            categoryBar.show()
            categoryBar.focusCategory(categoryList.firstCategory()?.id)
            categoryList
                .showNonemptyCategories()
                .updateBlankHeight()
                .showBlank()
        searchResult?.hide().resetScrollOffset().setMask(Page.MaskHint.BottomOnly)
        Item.updateHorizontalMargin()
        @page = "Category"

    switchToSearch:=>
        @hide()
        categoryBar.hide()
        categoryList.hide()
            .resetScrollOffset()
            .setMask(Page.MaskHint.BottomOnly)
        searchBar.show()
        @page = "Search"
        @isShowCategory = false
        selector.container(searchResult)

    hideMenu:->
        @switcher.dispatchEvent(new Event("mouseout"))

    hide:->
        @hideMenu()
        @switcher.style.visibility = 'hidden'

    show:->
        @switcher.style.visibility = 'visible'

    normal:->

    bright:->

    notify:->
