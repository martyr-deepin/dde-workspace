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
    constructor: (@appId, @appName, @icon, @successHandler, @failedHandler)->
        @uninstalling_apps = {}
        try
            @daemon = get_dbus("session", LAUNCHER_DAEMON, "RequestUninstall")
        catch e
            console.log(e)
            @daemon = null

    disconnect: =>
        console.log("disconnect UpdateSignal")
        try
            @daemon?.dis_connect("UninstallFailed", @uninstallFailedHandler)
            @daemon?.dis_connect("UninstallSuccess", @uninstallSuccessHandler)
        catch e
            console.error e

    uninstallSuccessHandler:(appId)=>
        if appId != @appId
            return
        @successHandler(appId)
        @uninstallReport(UNINSTALL_STATUS.SUCCESS, UNINSTALL_MESSAGE.SUCCESSFUL.args(appId))
        @disconnect()

    uninstallFailedHandler:(appId, reason)=>
        if appId != @appId
            return
        console.log("#{appId} uninstall failed: #{reason}")
        @failedHandler(appId, reason)
        @uninstallReport(UNINSTALL_STATUS.FAILED, UNINSTALL_MESSAGE.FAILED.args(appId))
        @disconnect()

    uninstallReport: (status, msg)->
        if status == UNINSTALL_STATUS.FAILED
            message = "failed"
        else if status == UNINSTALL_STATUS.SUCCESS
            message = "successfully"

        console.log "uninstall #{message}, #{msg}"
        try
            notification = get_dbus("session", NOTIFICATIONS, "Notify")
            console.log("#{@appId} sets icon: #{@icon} to notify icon")
            id = notification.Notify_sync(@appName, @notifyId, @icon, "", msg, [], {}, 0)
            @notifyId += 1
            # console.warn("notify id: #{id}")
            Uninstaller.IdMap[id] = @icon
            notification.connect("NotificationClosed", remove_backup_app_icon)
        catch e
            console.error e

    uninstall: (purge=true) =>
        console.log("uninstall #{@appId}")
        @daemon.connect("UninstallFailed", @uninstallFailedHandler)
        @daemon.connect("UninstallSuccess", @uninstallSuccessHandler)
        @daemon.RequestUninstall(@appId, purge)
