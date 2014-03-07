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
        @o = x: 32, y:32
        @animationCanvas = null
        # @animationCanvas = create_element(
        #     tag:"canvas",
        #     class:"switcher_board",
        #     width: 64,
        #     height: 64,
        #     document.body
        # )
        # @ctx = @animationCanvas.getContext("2d")
        # info = lineWidth: 2, alpha:5, radius: 17
        # @drawCircle(info)
        @isShowCategory = false
        @switcher = create_element(tag:'div', id:'switcher', document.body)
        @switcherHover = create_element(tag:'div', id:"switcher_hover", document.body)
        @showCategory()
        @page = 'Favor'
        @isHovered = false
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
            echo 'drop'
            e.preventDefault()
            e.stopPropagation()
            if @isFavor()
                return
            id = e.dataTransfer.getData("text/plain")
            favor.add(id)
            @addedToFavor = true
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
        selector.container($("#grid"))
        $("#grid").style.display = 'block'
        favor.hide()
        @isShowCategory = true
        if @isHovered
            @showFavorHover()
        else
            @showFavor()
        categoryBar.show()
        categoryList.showNonemptyCategories().updateBlankHeight().showBlank()
        categoryBar.focusCategory(categoryList.firstCategory()?.id)
        Item.updateHorizontalMargin()
        searchResult?.hide()
        @page = "Category"

    switchToFavor:=>
        searchBar.hide().clean()
        selector.container(favor.element)
        @isShowCategory = false
        categoryBar.hide()
        favor.show()
        $("#grid").style.display = 'none'
        if @isHovered
            @showCategoryHover()
        else
            @showCategory()
        # container.style.marginLeft = "110px"
        # Item.updateHorizontalMargin()
        searchResult?.hide()
        @page = "Favor"

    switchToSearch:=>
        $("#grid").style.display = 'none'
        categoryBar.hide()
        favor.hide()
        if @isHovered
            @showFavorHover()
        else
            @showFavor()
        searchBar.show()
        @page = "Search"

    hide:->
        @switcher.style.visibility = 'hidden'

    show:->
        @switcher.style.visibility = 'visible'
        selector.container(favor.element)

    normal:->
        if @page == "Category"
            @showFavor()

    bright:->
        @showFavorGlow()

    separate:->
        if @animationCanvas == null
            @animationCanvas = create_element(
                tag:"canvas",
                class:"switcher_board",
                width: 64,
                height: 64,
                document.body
            )

            @ctx = @animationCanvas.getContext("2d")
        info1 = lineWidth: 2, alpha:5, radius: 17
        info2 = lineWidth: 2, alpha:5, radius: 17
        @animationTimer = setInterval(=>
            @doSeparate([info1, info2])
        , 90)

    doSeparate:(infos)=>
        @ctx.clearRect(0, 0, @animationCanvas.width, @animationCanvas.height)

        info1 = infos[0]
        info2 = infos[1]

        if info2.radius < 20
            # echo 'draw first'
            if info1.radius == 19
                info1.lineWidth = 1

            @drawCircle(info1)
            info1.radius += 1
            info1.alpha -= 1

        if info1.radius > 20
            # echo 'draw second'
            if info2.radius == 19
                info2.lineWidth = 1

            @drawCircle(info1)
            info2.radius += 1
            info2.alpha -= 1

        if info2.radius > 22
            # echo 'stop'
            clearInterval(@animationTimer)
            @ctx.clearRect(0,0,@animationCanvas.width,@animationCanvas.height)

    drawCircle:(info)->
        @ctx.beginPath()
        @ctx.arc(@o.x, @o.y, info.radius, 0, 2 * Math.PI)
        @ctx.lineWidth = info.lineWidth
        @ctx.strokeStyle = 'rgba(255,255,255,0.'+info.alpha+')'
        @ctx.stroke()
