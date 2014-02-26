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


uninstallReport = (status, msg)->
    notification = DCore.DBus.session(NOTIFICATIONS)

    if status == UNINSTALL_STATUS.FAILED
        message = "FAILED"
    else if status == UNINSTALL_STATUS.SUCCESS
        message = "SUCCESSFUL"

    echo "uninstall #{message}, #{msg}"
    icon_launcher = DCore.get_theme_icon("start-here", 48)
    notification.Notify("Deepin Launcher", -1, icon_launcher, "Uninstall #{message}", "#{msg}", [], {}, 0)


uninstall = (opt) ->
    echo "#{opt.item.path}, #{opt.purge}"
    item = opt.item
    packages = daemon.GetPackageNames_sync(item.path)
    if packages.length == 0
        uninstallReport(UNINSTALL_STATUS.FAILED, "get packages failed")
        item.status = SOFTWARE_STATE.IDLE
        item.show()
        delete uninstalling_apps[item.id]
        return
    opt.item.packages = packages
    # echo packages.join()
    softwareManager.uninstall_pkg(packages.join(" "), opt.purge)


update = (status, info, categories)->
    path = info[0]
    name = info[1]
    id = info[2]
    icon = info[3]
    # echo "status: #{status}"
    # echo "path: #{path}"
    # echo "name: #{name}"
    # echo "id: #{id}"
    # echo "icon: #{icon}"
    # echo "categories: #{categories}"

    if status.match(/^deleted$/i)
        if uninstalling_apps[id]
            delete uninstalling_apps[id]

        if (item = Widget.look_up(id))?
            echo 'deleted'
            item.status = SOFTWARE_STATE.UNINSTALLING
            item.hide()
            item.destroy()
            Widget.look_up("se_#{id}")?.destroy()
            Widget.look_up("fa_#{id}")?.destroy()
            delete applications[id]
            categoryList.hideEmptyCategories()
    else if status.match(/^created$/i)
        echo 'added'
        # status = "added"
        info = new ItemInfo(id, name, path, icon)
        applications[id] = info
        item = new Item(id, name, path, icon)
        seItem = new SearchItem("se_#{id}", name, path, icon)
        faItem = new FavorItem("fa_#{id}", name, path, icon)
        info.element = item.element
        info.searchElement = seItem.element
        info.favorElement = faItem.element
        info.register(id, item)
        info.register("se_#{id}", seItem)
        info.register("fa_#{id}", faItem)
        info.notify()
        $("#searchResult").appendChild(info.searchElement)

        categoryList.addItem(id, categories)
        # categoryList.showNonemptyCategories()
        if !switcher.isInSearch()
            if switcher.isShowCategory
                switcher.showCategory()
            else
                categoryList.showFavorOnly()
    else
        echo 'updated'
        applications[id].update(name:name, path:path, basename:get_path_name(path), icon:icon)

    # FIXME:
    # load what should be shown, not forbidden reloading on searching.
    if !searchBar.empty()
        # echo 'search'
        searchBar.search()


daemon.connect("ItemChanged", update)
