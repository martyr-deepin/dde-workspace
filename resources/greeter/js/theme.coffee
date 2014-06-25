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

THEME_PATH = "greeter-theme"

setTheme = (theme)->
    _b = document.body
    _b.style.height = screen.height
    _b.style.width = screen.width
    echo "setTheme:#{theme}"
    path = "#{THEME_PATH}/#{theme}"
    theme_iframe = create_element("iframe","theme_iframe",_b)
    theme_iframe.src = "#{path}/#{theme}.html"
    theme_iframe.style.position = "absolute"
    theme_iframe.style.zIndex = 1
    theme_iframe.style.width = "100%"
    theme_iframe.style.height = "100%"
    theme_iframe.style.margin = 0
    theme_iframe.style.border = 0
    theme_iframe.style.overflow = "hidden"
    theme_iframe.style.background = "transparent"
    return
    switch theme
        when THEME.sky
            inject_js("#{path}/sky.js")
        when THEME.light
            inject_js("#{path}/light.js")
        when THEME.rain
            inject_js("#{path}/rain.js")

theme = DCore[APP_NAME].get_theme()
setTheme(theme)
