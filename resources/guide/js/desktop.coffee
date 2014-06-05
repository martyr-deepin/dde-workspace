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
        
        @message = _("让我们把另外一个图标拖动到第一个图标上\n生成\“应用程序组\”")
        @show_message(@message)
        
        @corner_leftup = new Pointer("circle_richdir",@element)
        @corner_leftup.create_pointer(AREA_TYPE.circle,POS_TYPE.leftup)
        @corner_leftup.set_area_pos(18,13,"fixed",POS_TYPE.leftup)
        
class DesktopRichDirCreated extends Page
    constructor:(@id)->
        super
        
        @message = _("很好！您已经学会如何创建一个\“应用程序组\”")
        @tips = _("tips：右键单击应用程序组将提供更多功能")
        @show_message(@message)
        @show_tips(@tips)
        setTimeout(=>
            guide?.switch_page(@,"DesktopCorner")
        ,t_switch_page)
        
class DesktopCorner extends Page
    constructor:(@id)->
        super
        
        #DCore.Guide.launch_zone()
        
        @message = _("鼠标滑动到四个顶角，可触发四个不同的事件")
        @tips = _("tips：请按提示依次触发，点击空白区域可返回")
        @show_message(@message)
        @show_tips(@tips)
        
        @pos = ["leftup","rightup","leftdown","rightdown"]
        @corner = []
        for p,i in @pos
            @corner[i] = new Pointer("corner_#{p}",@element)
            @corner[i].create_pointer(AREA_TYPE.corner,POS_TYPE[p])
            @corner[i].set_area_pos(0,0,"fixed",POS_TYPE[p])

class DesktopZone extends Page
    constructor:(@id)->
        super
        
        @message = _("在桌面上右键调出菜单，点击“桌面热区设置”可以设置刚才使用的热区")
        @tips = _("tips：点击空白区域可返回")
        @show_message(@message)
        @show_tips(@tips)


