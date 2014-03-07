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


NOTIFICATIONS = "org.freedesktop.Notifications"

SOFTWARE_MANAGER = "com.linuxdeepin.softwarecenter"


uninstallReport = (status, msg)->
    if status == UNINSTALL_STATUS.FAILED
        message = "FAILED"
    else if status == UNINSTALL_STATUS.SUCCESS
        message = "SUCCESSFUL"

    echo "uninstall #{message}, #{msg}"
    icon_launcher = DCore.get_theme_icon("start-here", 48)
    try
        notification = get_dbus("session", NOTIFICATIONS)
        notification.Notify("Deepin Launcher", -1, icon_launcher, "Uninstall #{message}", "#{msg}", [], {}, 0)
    catch e
        echo e
    if Object.keys(uninstalling_apps).length == 0
        echo 'uninstall: disconnect signal'
        softwareManager.dis_connect("update_signal", uninstallSignalHandler)


uninstallSignalHandler = (info)->
    # echo info
    status = info[0][0]
    package_name = info[0][1][0]
    # echo status
    if status == UNINSTALL_STATUS.FAILED
        message = info[0][1][3]
        for own id, item of uninstalling_apps
            if item.packages.indexOf(package_name) != -1
                item.status = SOFTWARE_STATE.IDLE
                item.show()
                delete uninstalling_apps[item.id]
                break
    else if status == UNINSTALL_STATUS.SUCCESS
        message = "success"
        for own id, item of uninstalling_apps
            if item.packages.indexOf(packages) != -1
                delete uninstalling_apps[item.id]
    if message
        uninstallReport(status, message)


uninstall = (opt) ->
    echo "#{opt.item.path}, #{opt.purge}"
    item = opt.item

    if not softwareManager?
        try
            softwareManager = get_dbus("system", SOFTWARE_MANAGER)
        catch e
            echo e
            try
                notification = get_dbus("session", NOTIFICATIONS)
                notification.Notify("Deepin Launcher", -1, icon_launcher, _("Uninstall failed"), _("Deepin Software Center is Not Found"), [], {}, 0)
            catch e
                echo e
            item.status = SOFTWARE_STATE.IDLE
            item.show()
            delete uninstalling_apps[item.id]
            return

    if Object.keys(uninstalling_apps).length == 1
        echo 'uninstall: connect signal'
        softwareManager.connect("update_signal", uninstallSignalHandler)

    packages = daemon.GetPackageNames_sync(item.path)
    if packages.length == 0
        item.status = SOFTWARE_STATE.IDLE
        item.show()
        delete uninstalling_apps[item.id]
        uninstallReport(UNINSTALL_STATUS.FAILED, "get packages failed")
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
            delete applications[id]
            categoryList.hideEmptyCategories()
    else if status.match(/^created$/i)
        echo 'added'
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
        echo 'updated'
        applications[id].update(name:name, path:path, basename:"#{get_path_name(path)}.desktop", icon:icon)

    # FIXME:
    # load what should be shown, not forbidden reloading on searching.
    if !searchBar.empty()
        # echo 'search'
        searchBar.search()


daemon.connect("ItemChanged", update)
