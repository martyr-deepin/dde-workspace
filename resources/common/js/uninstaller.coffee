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

LAUNCHER_DAEMON="com.deepin.dde.daemon.Launcher"

UNINSTALL_STATUS =
    FAILED: "action-failed"
    SUCCESS: "action-finish"


SOFTWARE_STATE =
    IDLE: 0
    UNINSTALLING: 1
    INSTALLING: 2


remove_backup_app_icon = (id, reason)->
    icon = Uninstaller.IdMap[id]
    if not icon
        return
    console.log("remove backup icon: #{icon}")
    DCore.delete_backup_app_icon(icon)
    delete Uninstaller.IdMap[id]


class Uninstaller
    @IdMap: {}
    constructor: (@appid, @appName, @icon, handler)->
        @uninstalling_apps = {}
        @uninstallSignalHandler = (info)=>
            handler?(@, info)

    uninstallReport: (status, msg)->
        if status == UNINSTALL_STATUS.FAILED
            message = "FAILED"
        else if status == UNINSTALL_STATUS.SUCCESS
            message = "SUCCESSFUL"

        console.log "uninstall #{message}, #{msg}"
        try
            notification = get_dbus("session", NOTIFICATIONS, "Notify")
            id = notification.Notify_sync(@appName, -1, @icon, "Uninstall #{message}", "#{msg}", [], {}, 0)
            Uninstaller.IdMap[id] = @icon
            notification.connect("NotificationClosed", remove_backup_app_icon)
        catch e
            console.log e
        if Object.keys(@uninstalling_apps).length == 0
            console.log 'uninstall: disconnect signal'
            @softwareManager = null


    uninstall: (opt) ->
        console.log "#{opt.item.path}, #{opt.purge}"
        item = opt.item
        @uninstalling_apps[item.id] = item

        if not @softwareManager
            try
                @softwareManager = get_dbus("system", SOFTWARE_MANAGER, "uninstall_pkg")
            catch e
                console.log e
                try
                    notification = get_dbus("session", NOTIFICATIONS, "Notify")
                    id = notification.Notify_sync(@appName, -1, @icon, _("Uninstall failed"), _("Cannot find Deepin Software Center."), [], {}, 0)
                    Uninstaller.IdMap[id] = @icon
                    notification.connect("NotificationClosed", remove_backup_app_icon)
                catch e
                    console.log e
                if item.status
                    item.status = SOFTWARE_STATE.IDLE
                    item.show()
                delete @uninstalling_apps[item.id]
                return

        if Object.keys(@uninstalling_apps).length == 1
            console.log 'uninstall: connect signal'
            @softwareManager.connect("update_signal", @uninstallSignalHandler)

        daemon = get_dbus("session", LAUNCHER_DAEMON, "GetPackageNames_sync")
        package_name = @softwareManager.get_pkg_name_from_path_sync(item.path)
        if package_name.length == 0
            if item.status
                item.status = SOFTWARE_STATE.IDLE
                item.show()
            delete @uninstalling_apps[item.id]
            uninstallReport(UNINSTALL_STATUS.FAILED, "get packages failed")
            console.log("get packages failed")
        opt.item.package_name = package_name
        console.log "package_name: #{package_name}"
        @softwareManager.uninstall_pkg(package_name, opt.purge)

