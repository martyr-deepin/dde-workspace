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

class DockMode extends Widget
    constructor:(@id,@mode,parent)->
        super
        echo "new DockMode(#{@id},#{@mode})"
        parent.appendChild(@element)
        dock = create_element("div","dock_#{@mode}",@element)
        switch @mode
            when "mac"
                @icon_count = 12
                @applet_count = 0
                left = create_element("div","left",dock)
                center = create_element("div","center",dock)
                for i in [1...@icon_count]
                    create_img("dock_icon_#{i}","img/dock/#{i}.png",center)
                right = create_element("div","right",dock)
            when "win7", "xp"
                @icon_count = 8
                @applet_count = 3
                left = create_element("div","left",dock)
                for i in [1...@icon_count]
                    icon = create_img("","img/dock/#{i}.png",left)
                right = create_element("div","right",dock)
                time = create_element("div","time",right)
                d = new Date()
                time.innerText = @check_time(d.getHours()) + ":" + @check_time(d.getMinutes())
                for applet in ["sound","net","input"]
                    create_img(applet,"img/dock/#{applet}.png",right)

    check_time: (t) ->
        if t < 10
            return "0" + t
        t

    destory: ->
        @element.parentElement?.removeChild(@element)
        delete Widget.object_table[@id]

class DockMenu extends Page
    constructor:(@id)->
        super
        inject_css(@element,"css/dock.css")
        @dock = new Dock()
        @message = _("Right-click on the blank area of dock, you can switch three modes and the display status")
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
            {type:MENU.option,text:_("_Auto hide")},
            {type:MENU.option,text:_("_Smart hide")},
            {type:MENU.cutline,text:""},
            {type:MENU.option,text:_("Notification area settings")}
        ]
        @contextmenu = new ContextMenu("dock_contextmenu",@element)
        @contextmenu.menu_create(menu)
        @contextmenu.set_pos(x,y,"fixed",POS_TYPE.leftdown)
        t_move = 1500
        @dockMode = new DockMode("dockMode","mac",@element)
        @contextmenu.set_selected(1,t_move * 1,=>
            @dockMode.destory()
            @dockMode = new DockMode("dockMode","win7",@element)
        )
        @contextmenu.set_selected(2,t_move * 2,=>
            @dockMode.destory()
            @dockMode = new DockMode("dockMode","xp",@element)
            @switch_page()
        )

    switch_page: ->
        setTimeout(=>
            @dock?.show()
            DCore.Guide.cursor_show()
            guide?.switch_page(@,"LauncherLaunch")
        ,t_mid_switch_page)
