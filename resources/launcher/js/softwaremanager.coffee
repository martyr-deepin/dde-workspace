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


uninstallSignalHandler = (clss, info)->
    # console.log info
    status = info[0][0]
    package_name = info[0][1][0]
    console.log "uninstall report ##{status}#"
    if status == UNINSTALL_STATUS.FAILED
        message = "uninstall #{package_name} #{info[0][1][3]}"
        for own id, item of clss.uninstalling_apps
            if item.packages.indexOf(package_name) != -1
                item.status = SOFTWARE_STATE.IDLE
                item.show()
                categoryList.showNonemptyCategories()
                delete clss.uninstalling_apps[item.id]
                break
    else if status == UNINSTALL_STATUS.SUCCESS
        message = "uninstall #{package_name} success"
        for own id, item of clss.uninstalling_apps
            console.log(item.packages)
            if item.packages.indexOf(package_name) != -1
                delete clss.uninstalling_apps[item.id]
    console.log "uninstall: #{message}"
    if message
        console.log "uninstall report #{status}"
        clss.uninstallReport(status, message)


update = (status, info, categories)->
    path = info[0]
    name = info[1]
    id = info[2]
    icon = info[3]
    # console.log "status: #{status}"
    # console.log "path: #{path}"
    # console.log "name: #{name}"
    # console.log "id: #{id}"
    # console.log "icon: #{icon}"
    # console.log "categories: #{categories}"

    if status.match(/^deleted$/i)
        if uninstalling_apps[id]
            console.log("delete uninstall_apps")
            delete uninstalling_apps[id]

        if (item = Widget.look_up(id))?
            console.log 'deleted'
            item.status = SOFTWARE_STATE.UNINSTALLING
            item.hide()
            categoryList.hideEmptyCategories()
            item.destroy()
            delete applications[id]
    else if status.match(/^created$/i)
        console.log 'added'
        autostartList = startManager.AutostartList_sync()
        item = createItem(info, autostartList)
        item.add('search')
        $("#searchResult").appendChild(item.elements.search)

        categoryList.addItem(id, categories)
        categoryList.showNonemptyCategories()
        if !switcher.isInSearch()
            if switcher.isShowCategory
                switcher.switchToCategory()
            else
                switcher.switchToFavor()
    else
        console.log 'updated'
        applications[id].update(name:name, path:path, basename:"#{get_path_name(path)}.desktop", icon:icon)

    # FIXME:
    # load what should be shown, not forbidden reloading on searching.
    if !searchBar.empty()
        # console.log 'search'
        searchBar.search()


daemon.connect("ItemChanged", update)
