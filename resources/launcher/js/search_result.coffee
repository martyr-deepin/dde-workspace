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

$("#searchResult").addEventListener('scroll', (e)->
    if this.scrollTop == 0
        this.style.webkitMaskImage = "-webkit-linear-gradient(top, rgba(0,0,0,1), rgba(0,0,0,1) 90%, rgba(0,0,0,0.3), rgba(0,0,0,0))"
    else if this.scrollBottom == 0
        this.style.webkitMaskImage = "-webkit-linear-gradient(top, rgba(0,0,0,0), rgba(0,0,0,1) 5%"
    else
        this.style.webkitMaskImage = "-webkit-linear-gradient(top, rgba(0,0,0,0), rgba(0,0,0,1) 5%, rgba(0,0,0,1) 90%, rgba(0,0,0,0.3), rgba(0,0,0,0))"
)
