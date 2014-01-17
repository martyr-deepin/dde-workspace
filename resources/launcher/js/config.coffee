#Copyright (c) 2011 ~  Deepin, Inc.
#              2013 ~ Lee Liqiang
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


class Config
    constructor: ->
        @dbus = DCore.DBus.session("com.deepin.dde.launcher")
        for own k of @dbus
            if (match = k.match(/(.*)_sync/))
                echo m = match[1]
                @[m] = ->
                    @dbus[match[0]](arguments)
                # echo k
        @config = @dbus.IsPinned()
        @sort_method = @dbus.GetSortMethod() || DCore.Launcher.sort_method() || DEFAULT_SORT_METHOD

    save: ->
