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

class DesktopRichDir extends Page
    constructor:(@id)->
        super
        
        @message = _("让我们把其他两个图标重合到第一个图标上\n生成\“应用程序组\”")
        @show_message(@message)
        
        @corner_leftup = new Pointer("circle_richdir",@element)
        @corner_leftup.create_pointer(AREA_TYPE.circle,POS_TYPE.leftup)
        @corner_leftup.set_area_pos(18,13,"fixed",POS_TYPE.leftup)
        

