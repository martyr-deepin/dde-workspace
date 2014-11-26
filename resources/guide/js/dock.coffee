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

class DockMenu extends Page
    constructor:(@id)->
        super
        inject_css(@element,"css/dock.css")
        @dock = new Dock()
        @message = _("Three modes and the display status can be switched by right-click on the blank area of dock")
        @show_message(@message)

        DCore.Guide.cursor_hide()
        @dock.hide()
        @menu_create(screen.width / 2, 10)

    menu_create: (x,y) ->
        menu =[
            {type:MENU.selected,text:_("_Fashion mode")},
            {type:MENU.option,text:_("_Efficient mode")},
            {type:MENU.option,text:_("_Classic mode")},
            {type:MENU.cutline,text:""},
            {type:MENU.option,text:_("Keep _showing")},
            {type:MENU.option,text:_("Keep _hidden")},
            {type:MENU.option,text:_("_Smart hide")},
            {type:MENU.cutline,text:""},
            {type:MENU.option,text:_("Notification area settings")}
        ]
        @contextmenu = new ContextMenu("dock_contextmenu",@element)
        @contextmenu.menu_create(menu)
        @contextmenu.set_pos(x,y,"fixed",POS_TYPE.leftdown)
        t_move = 1500
        @dockMode = new DockMode("dockModeMac",DisplayMode.Fashion,@element)
        @contextmenu.set_selected(1,t_move * 1,=>
            @dockMode.destory()
            @dockMode = new DockMode("dockModeWin7",DisplayMode.Efficient,@element)
        )
        @contextmenu.set_selected(2,t_move * 2,=>
            @dockMode.destory()
            @dockMode = new DockMode("dockModeXp",DisplayMode.Classic,@element)
            @switch_page()
        )

    switch_page: ->
        setTimeout(=>
            @dock?.show()
            DCore.Guide.cursor_show()
            guide?.switch_page(@,"LauncherLaunch")
        ,t_mid_switch_page)
