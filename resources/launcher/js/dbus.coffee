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


LAUNCHER_DAEMON="com.deepin.dde.daemon.Launcher"
daemon = DCore.DBus.session(LAUNCHER_DAEMON)


START_MANAGER =
    obj: "com.deepin.SessionManager"
    path: "/com/deepin/StartManager"
    interface: "com.deepin.StartManager"
startManager = DCore.DBus.session_object(
    START_MANAGER.obj,
    START_MANAGER.path,
    START_MANAGER.interface
)
startManager.connect("AutostartChanged", (status, path)->
    echo "autostart changed: #{status}"
    for own k, v of applications
        if v.basename == "#{get_path_name(path)}.desktop"
            item = v
            break

    if status == "deleted"
        echo "deleted"
        item?.setAutostart(false).notify()
    else if status = "modified"
        echo "modified"
        item?.setAutostart(!item.isAutostart).notify()
    else
        echo "add"
        item?.setAutostart(true).notify()
)


SORTWARE_MANAGER = "com.linuxdeepin.softwarecenter"
softwareManager = DCore.DBus.sys(SORTWARE_MANAGER)
softwareManager.connect("update_signal", (info)->
    # echo info
    status = info[0][0]
    package_name = info[0][1][0]
    echo status
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
        uninstallReport(status, "#{message}")
)


GRAPH_API = "com.deepin.api.Graphic"
background = DCore.DBus.session(GRAPH_API)
background.connect("BlurPictChanged", setBackground)


NOTIFICATIONS = "org.freedesktop.Notifications"
