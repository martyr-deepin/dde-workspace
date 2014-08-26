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


class LauncherLaunch extends Page
    get_launchericon_pos_interval = null
    constructor:(@id)->
        super
        enableZoneDetect(true)
        @dock = new Dock()
        @launcher = new Launcher()
        @message = _("\"Application Launcher\" can be started by sliding the mouse to the upper left corner or clicking on the launcher.")
        @show_message(@message)
        @corner_leftup = new Pointer("corner_leftup",@element)
        @corner_leftup.create_pointer(AREA_TYPE.corner,POS_TYPE.leftup)
        @corner_leftup.set_area_pos(0,0,"fixed",POS_TYPE.leftup)
        @corner_leftup.show_animation()
        @circle = new Pointer("launcher_circle",@element)
        @circle.create_pointer(AREA_TYPE.circle,POS_TYPE.rightdown,=>
            @launcher?.show()
        )
        @circle.enable_area_icon("#{@img_src}/start-here.png",48,48)
        get_launchericon_pos_interval = setInterval(=>
            @pos = @dock.get_launchericon_pos()
            @circle_x = @pos.x0 - @circle.pointer_width + ICON_MARGIN_H
            @circle_y = @pos.y0 - @circle.pointer_height - ICON_MARGIN_V_BOTTOM / 2
            @circle.set_area_pos(@circle_x,@circle_y,"fixed",POS_TYPE.leftup)
        ,100)
        @circle.show_animation()

        @launcher.show_signal(@show_signal_cb)

    show_signal_cb:=>
        enableZoneDetect(false)
        @element.style.display = "none"
        setTimeout(=>
            @launcher.show_signal_disconnect()
            clearInterval(get_launchericon_pos_interval)
            guide?.switch_page(@,"LauncherCollect")
        ,t_min_switch_page)

class LauncherCollect extends Page
    constructor:(@id)->
        super
        @rect = new Rect("collectApp",@element)
        @rect.create_rect(COLLECT_WIDTH,COLLECT_HEIGHT)
        @rect.set_pos(COLLECT_LEFT,COLLECT_TOP)
        @rect.show_animation(=>
            setTimeout(=>
                guide?.switch_page(@,"LauncherAllApps")
            ,t_mid_switch_page)
        )
        @message = _("What shown in the first screen of \"launcher\" are the applications collected.")
        @show_message(@message)
        @msg_tips.style.marginTop = "150px"

class LauncherAllApps extends Page
    constructor:(@id)->
        super

        @pointer = new Pointer("ClickToAllApps",@element)
        @pointer.create_pointer(AREA_TYPE.circle,POS_TYPE.leftup, (e)=>
            simulate_click(CLICK_TYPE.leftclick,@,"LauncherScroll")
        )
        @pointer.enable_area_icon("#{@img_src}/category_normal.png",64,64)
        @pointer.set_area_pos(CATE_LEFT - 2,CATE_LEFT - 2)
        @pointer.show_animation()
        @message = _("Please click on the \"All Applications\" icon, you will see all applications.")
        @show_message(@message)

class LauncherScroll extends Page
    constructor:(@id)->
        super
        @scrollup = false
        @scrolldown = false
        inject_css(@element,"css/launcherscroll.css")
        new Launcher()?.show() if DEBUG
        @message = _("All programs can be located by scrolling the mouse up and down.\nYou can also click on the left classification navigation to locate")
        @show_message(@message)
        @scroll_create()
        @rect_pointer_create()

    scroll_create: ->
        @scroll = create_element("div","scroll",@element)
        @scroll.style.position = "absolute"
        @scroll.style.top = "37%"
        @scroll.style.right = "200px"
        @scroll_down = create_img("scroll_down","#{@img_src}/pointer_down.png",@scroll)
        @scroll_up = create_img("scroll_up","#{@img_src}/pointer_up.png",@scroll)
        width = height = 64
        @scroll.style.width = width
        @scroll.style.height = height * 2 + 50
        @scroll_down.style.width = @scroll_up.style.width = width
        @scroll_down.style.height = @scroll_up.style.height = height
        @scroll_up.style.position = "absolute"
        @scroll_up.style.left = 0
        @scroll_up.style.bottom = 0
        @scroll_up.style.display = "none"
        move_animation(@scroll_up,0 + height,0,"top","absolute")
        move_animation(@scroll_down, 0,0 - height,"bottom","absolute")

        @element.addEventListener("mousewheel", (e)=>
            if @scrollup or @scrolldown
                return
            if e.wheelDelta >= 120
                @scrollup = true
                simulate_click(CLICK_TYPE.scrollup)
                @switch_page()
            else if e.wheelDelta <= -120
                @scrolldown = true
                simulate_click(CLICK_TYPE.scrolldown)
                @switch_page()
        )

        @noscroll = create_element("div","noscroll",@element)
        @noscroll.innerText = _("Skip the step without scroll")
        @noscroll.addEventListener("click",(e) =>
            e.stopPropagation()
            @switch_page()
        )

    rect_pointer_create: ->
        @rect = new Rect("collectApp",@element)
        @rect.create_rect(CATE_WIDTH,CATE_HEIGHT)
        rect_top = (primary_info.height  - @rect.height) / 2
        @rect.set_pos(CATE_LEFT,rect_top - CATE_TOP_DELTA)
        @pointer = new Pointer("category",@element)
        @pointer.create_pointer(AREA_TYPE.circle,POS_TYPE.leftup,=>
            simulate_click(CLICK_TYPE.leftclick,@,"LauncherSearch")
        )
        @pointer.enable_area_icon("#{@img_src}/graphics100.png",36,36)
        pointer_top = (primary_info.height  - @pointer.pointer_height) / 2
        @pointer.set_area_pos(CATE_LEFT,pointer_top - CATE_TOP_DELTA)
        @pointer.show_animation()


    switch_page: ->
        setTimeout(=>
            guide?.switch_page(@,"LauncherSearch")
        ,t_mid_switch_page)

class LauncherSearch extends Page
    constructor:(@id)->
        super
        new Launcher()?.show() if DEBUG
        @message = _("Use the keyboard to search for applications\nTry the \"deepin\" keyword to see which applications are shown")
        @tips = _("tips: Please directly enter the word \"deepin\"")
        @show_message(@message)
        @show_tips(@tips)

        @fcitx = new Fcitx()
        @fcitx?.setCurrentIM("fcitx-keyboard-us")
        deepin_keysym = [68,69,69,80,73,78]
        setTimeout(=>
            simulate_input(deepin_keysym,@,"LauncherMenu")
        ,20)

class LauncherMenu extends Page
    APP_NAME_1 = "deepin-movie"
    APP_NAME_2 = "deepin-music-player"
    constructor:(@id)->
        super
        @launcher = new Launcher()
        @message = _("Use the right mouse button to send two icons to the desktop")
        @tips = _("tips: You can add it to startup items or uninstall it")
        @show_message(@message)
        @show_tips(@tips)
        @signal()
        @src_app_create_menu()

    src_app_create_menu: ->
        app_list = []
        launcher_daemon = new LauncherDaemon()
        app_list = launcher_daemon?.search("deepin")
        app1_index = i + 1 for app,i in app_list when app is APP_NAME_1
        app2_index = i + 1 for app,i in app_list when app is APP_NAME_2
        app1_pos = launcher_daemon.app_x_y(app1_index)
        app2_pos = launcher_daemon.app_x_y(app2_index)
        @menu_create(app1_pos.x,app1_pos.y,=>
            src1 = "/usr/share/applications/#{APP_NAME_1}.desktop"
            DCore.Guide.copy_file_to_desktop(src1)
            @menu_create(app2_pos.x,app2_pos.y,=>
                src2 = "/usr/share/applications/#{APP_NAME_2}.desktop"
                DCore.Guide.copy_file_to_desktop(src2)
                @switch_page()
            )
        )

    menu_create: (x,y,cb) ->
        @menu =[
            {type:MENU.option,text:_("_Open")},
            {type:MENU.cutline,text:""},
            {type:MENU.option,text:_("Remove from _favorites")},
            {type:MENU.selected,text:_("Send to d_esktop")},
            {type:MENU.option,text:_("Send to do_ck")},
            {type:MENU.cutline,text:""},
            {type:MENU.option,text:_("_Add to autostart")},
            {type:MENU.option,text:_("_Uninstall")}
        ]
        @contextmenu = new ContextMenu("launcher_contextmenu",@element)
        @contextmenu.menu_create(@menu)
        @contextmenu.set_pos(x,y)
        @contextmenu.selected_click(=>
            @element.removeChild(@contextmenu.element)
            cb?()
        )

    signal: ->
        @launcher?.hide_signal(=>
            @launcher?.show()
        )

    switch_page: ->
        setTimeout(=>
            @launcher?.hide_signal_disconnect()
            @launcher?.hide()
            #DCore.Guide.spawn_command_sync("/usr/lib/deepin-daemon/desktop-toggle",true)
            guide?.switch_page(@,"DesktopRichDir")
        ,t_min_switch_page)
