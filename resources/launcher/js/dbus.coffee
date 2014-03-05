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
daemon = get_dbus("session", LAUNCHER_DAEMON)
if daemon == null
    DCore.Launcher.quit()


START_MANAGER =
    name: "com.deepin.SessionManager"
    path: "/com/deepin/StartManager"
    interface: "com.deepin.StartManager"

startManager = get_dbus("session", START_MANAGER)
if startManager == null
    DCore.Launcher.quit()

startManager.connect("AutostartChanged", (status, path)->
    echo "autostart changed: #{status}"
    for own k, v of applications
        if v.basename == "#{get_path_name(path)}.desktop"
            item = v
            break

    if status == "deleted"
        echo "deleted"
        item.remove_from_autostart()
    else
        echo "add"
        item.add_to_autostart()
)
