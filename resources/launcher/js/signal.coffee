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


DCore.signal_connect('workarea_changed', (alloc)->
    height = alloc.height
    _b.style.maxHeight = "#{height}px"
    $('#container').style.maxHeight = "#{height - CONTAINER_BOTTOM_MARGIN - SEARCH_BAR_HEIGHT}px"
    $('#grid').style.height = "#{height - CONTAINER_BOTTOM_MARGIN - SEARCH_BAR_HEIGHT}px"
    $('#searchResult').style.height = "#{height - CONTAINER_BOTTOM_MARGIN - SEARCH_BAR_HEIGHT}px"
    $("#categoryWrap").style.height = "#{height - CONTAINER_BOTTOM_MARGIN - SEARCH_BAR_HEIGHT - 110}px"
    category_column_adaptive_height()
)


DCore.signal_connect("lost_focus", (info)->
    if s_dock.LauncherShouldExit_sync(info.xid)
        exit_launcher()
)


DCore.signal_connect("exit_launcher", ->
    reset()
)

DCore.signal_connect("launcher_shown",->
    switcher.switchToCategory()
)


DCore.Launcher.notify_workarea_size()

