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

uninstallFailedHandler = (itemId, reason)->
    item = Widget.look_up(itemId)
    if not item?
        return

    item.status = SOFTWARE_STATE.IDLE
    item.show()
    if launcherSetting.getSortMethod() == SortMethod.Method.ByCategory
        categoryList.showNonemptyCategories()

uninstallSuccessHandler = (itemId)->

update = (status, info, categories)->
    path = info[0]
    name = info[1]
    id = info[2]
    icon = info[3]
    console.log("item #{id} is changed")

    if status.match(/^deleted$/i)
        if (item = Widget.look_up(id))?
            console.log 'deleted'
            item.status = SOFTWARE_STATE.UNINSTALLING
            item.hide()
            if launcherSetting.getSortMethod() == SortMethod.Method.ByCategory
                categoryList.hideEmptyCategories()
            item.destroy()
            delete applications[id]
    else if status.match(/^created$/i)
        console.log 'added'
        autostartList = startManager.AutostartList_sync()
        item = createItem(info, autostartList)
        item.add('search')
        searchResult.append(item.elements.search)

        if switcher.isShowCategory
            categoryList.addItem(id, categories)
            categoryList.sort(categories)
        else
            categoryList.addItem(id)
            categoryList.sort()
        if launcherSetting.getSortMethod() == SortMethod.Method.ByCategory
            categoryList.showNonemptyCategories()
        if !switcher.isInSearch()
            if switcher.isShowCategory
                switcher.switchToCategory()
    else
        console.log 'updated'
        applications[id].update(name:name, path:path, basename:"#{get_path_name(path)}.desktop", icon:icon)

    # FIXME:
    # load what should be shown, not forbidden reloading on searching.
    if !searchBar.empty()
        # console.log 'search'
        searchBar.search()


daemon.connect("ItemChanged", update)
