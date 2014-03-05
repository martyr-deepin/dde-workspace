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


setBackground = (uid, path)->
    callback = (path)->
        echo "set background to #{path}"
        localStorage.setItem("bg", path)
        _b.style.backgroundImage = "url(#{path})"

    path = path || uid
    img = new Image()
    img.src = path
    if img.complete
        callback(path)
    else
        img.onload = ->
            callback(path)
            img.onload = null


GRAPH_API = "com.deepin.api.Graphic"
background = DCore.DBus.session(GRAPH_API)
background.connect("BlurPictChanged", setBackground)
daemon.connect("BackgroundChanged", setBackground)
