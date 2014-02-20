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
START_MANAGER =
    obj: "com.deepin.SessionManager"
    path: "/com/deepin/StartManager"
    interface: "com.deepin.StartManager"

SORTWARE_MANAGER = "com.linuxdeepin.softwarecenter"

daemon = DCore.DBus.session(LAUNCHER_DAEMON)
startManager = DCore.DBus.session_object(
    START_MANAGER.obj,
    START_MANAGER.path,
    START_MANAGER.interface
)
startManager.connect("AutostartChanged", (status, path)->
    echo 'autostart changed'
    item = null
    for own k, v of hiddenIcons.hiddenIcons
        if v.basename == get_path_name(path)
            item = v
            break
    if item?
        if status == "added"
            item.add_to_autostart()
        else if status == "deleted"
            item.remove_from_autostart()
)

softwareManager = DCore.DBus.sys(SORTWARE_MANAGER)
softwareManager.connect("update_signal", (info)->
    echo "test"
    status = info[0][0]
    if status == UNINSTALL_STATUS.FALIED
        message = info[1][3]
        # item.status = SOFTWARE_STATE.IDLE
        # item.show()
        # delete uninstalling_apps[info.id]
    else if status == UNINSTALL_STATUS.SUCCESS
        message = "success"
        # delete uninstalling_apps[info.id]
)
