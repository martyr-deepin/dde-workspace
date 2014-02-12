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
        @switcher = create_element(tag:'div', id:'switcher', $("#container"))
        @favor = create_img(src:'img/favor.png', title: 'favor', alt:'favor', @switcher)
        @category = create_img(src:'img/category.png', title: 'all', alt:'all', @switcher)
        @switcher.addEventListener('click', (e)=>
            e.stopPropagation()
            e.preventDefault()
            if @isShowCategory
                @hideCategory()
            else
                @showCategory()
        )

    showCategory:->
        @isShowCategory = true
        categoryBar.show()
        categoryList.showNonemtpyCategory().updateBlankHeight().showBlank()
        @favor.style.display = 'inline'
        @category.style.display = 'none'

    hideCategory:->
        @isShowCategory = false
        categoryBar.hide()
        categoryList.showFavorOnly()
        @favor.style.display = 'none'
        @category.style.display = 'inline'
