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

UNINSTALL_MESSAGE=
    SUCCESSFUL: _("You have uninstalled \"%1\" successfully")
    FAILED: _("\"%1\" failed to be uninstalled")


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
    @notifyId: 0
    constructor: (@appid, @appName, @icon, handler)->
        @uninstalling_apps = {}
        try
            @daemon = get_dbus("session", LAUNCHER_DAEMON, "GetPackageName")
        catch e
            console.log(e)
            @daemon = null
        @uninstallSignalHandler = (info)=>
            console.log(info)
            handler?(@, info)
            if info[0][0] == UNINSTALL_STATUS.SUCCESS || info[0][0] == UNINSTALL_STATUS.FAILED
                @disconnect()

    disconnect: =>
        console.log("disconnect UpdateSignal")
        try
            @daemon?.dis_connect("UpdateSignal", @uninstallSignalHandler)
            @daemon?.dis_connect("PackageNameGet", @packageNameHandler)
        catch e
            console.error e

    uninstallReport: (status, msg)->
        if status == UNINSTALL_STATUS.FAILED
            message = "failed"
        else if status == UNINSTALL_STATUS.SUCCESS
            message = "successfully"

        console.log "uninstall #{message}, #{msg}"
        try
            notification = get_dbus("session", NOTIFICATIONS, "Notify")
            console.log("#{@appid} sets icon: #{@icon} to notify icon")
            id = notification.Notify_sync(@appName, @notifyId, @icon, "", msg, [], {}, 0)
            @notifyId += 1
            console.warn("notify id: #{id}")
            Uninstaller.IdMap[id] = @icon
            notification.connect("NotificationClosed", remove_backup_app_icon)
        catch e
            console.error e
        if Object.keys(@uninstalling_apps).length == 0
            console.log 'uninstall: disconnect signal'
            # @softwareManager = null

    packageNameHandler:(id, package_name)=>
        console.log "package_name: ##{package_name}#, #{package_name.length}"
        item = @uninstalling_apps[id]
        if !package_name
            console.error("get packages failed")
            if item.status
                item.status = SOFTWARE_STATE.IDLE
                item.show()
            delete @uninstalling_apps[item.id]
            @uninstallReport("", UNINSTALL_MESSAGE.FAILED.args(item.id))
            console.log("get packages failed")
            @disconnect()
            return

        item.package_name = package_name
        console.log("uninstall")
        @daemon.Uninstall(package_name, item.purge)

    uninstall: (opt) =>
        console.log "uninstall #{opt.item.path}, #{opt.purge}"
        item = opt.item
        item.purge = opt.purge
        @uninstalling_apps[item.id] = item

        if Object.keys(@uninstalling_apps).length == 1 and @daemon
            console.log 'uninstall: connect signal'
            @daemon?.connect("UpdateSignal", @uninstallSignalHandler)
            @daemon?.connect("PackageNameGet", @packageNameHandler)

        console.log("get package name")
        @daemon?.GetPackageName(item.id, item.path)
