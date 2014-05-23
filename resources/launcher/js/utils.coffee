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


reset = ->
    searchBar.hide()
    searchBar.clean()
    selector.clean()
    searchResult?.hide()
    switcher.switchToFavor()
    gridOffset = 0
    grid.firstElementChild.style.webkitTransform = "translateY(0px)"

    if selector.selectedItem
        item = selector.selectedItem
        item.style.border = "1px rgba(255, 255, 255, 0.0) solid"
        item.style.background = ""
        item.style.borderRadius = ""

    if Item.hoverItem
        item = Item.hoverItem
        item.classList.remove("item_hovered")


exit_launcher = ->
    DCore.Launcher.force_show(false)
    DCore.Launcher.exit_gui()


setBackground = (uid, path)->
    callback = (path)->
        console.log "set background to #{path}"
        localStorage.setItem("bg", path)
        _b.style.backgroundImage = "url(#{path})"

    path = path || uid
    img = new Image()
    img.src = path
    if img.complete
        callback(path)
    else
        img.onload = ->
            callback(path)
            img.onload = null


createItem = (core, autostartList)->
    path = core[0]
    name = core[1]
    id = core[2]
    icon = core[3]

    basename = get_path_name(path) + ".desktop"
    item = new Item(id, name, path, icon)
    applications[id] = item
    autostart = autostartList.filter((el)-> el.match("#{basename}$"))
    if autostart.length != 0
        autostartList.remove(autostart[0])
        item.add_to_autostart()

    item
