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
THEME =
    static:"static"
    sky:"sky"
    light:"light"
    rain:"rain"

setTheme = (theme)->
    _b = document.body
    _b.style.height = window.innerHeight
    _b.style.width = window.innerWidth
    switch theme
        when THEME.static
            _b.style.backgroundImage = "url(/usr/share/backgrounds/default_background.jpg)"
        when THEME.sky
            _b.style.backgroundImage = "url(theme/img/sky.jpg)"
            inject_js("theme/js/sky.js")
        when THEME.light
            inject_js("theme/js/light.js")
        when THEME.rain
            _b.style.backgroundImage = "url(theme/img/rain.jpg)"
            inject_js("theme/js/rain.js")

#theme = DCore[APP_NAME].get_theme()
theme = THEME.sky
setTheme(theme)
