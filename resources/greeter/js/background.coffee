#Copyright (c) 2011 ~ 2014 Deepin, Inc.
#              2011 ~ 2014 bluth
#
#encoding: utf-8
#Author:      bluth <yuanchenglu@linuxdeepin.com>
#Maintainer:  bluth <yuanchenglu@linuxdeepin.com>
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
setBodyWallpaper = (wallpaper)->
    echo "setBodyWallpaper:#{wallpaper}"
    _b = document.body
    
    _b.style.height = window.innerHeight
    _b.style.width = window.innerWidth
    switch wallpaper
        when "sky_move"
            _b.style.backgroundImage = "url(js/skyThree/sky.png)"
            inject_js("js/skyThree/sky.js")
        when "sky_static"
            _b.style.backgroundImage = "url(js/skyThree/sky.png)"
        when "default"
            _b.style.backgroundImage = "url(/usr/share/backgrounds/default_background.jpg)"
        else
            inject_js("js/skyThree/Three.js")
            inject_js("js/skyThree/sky.js")
