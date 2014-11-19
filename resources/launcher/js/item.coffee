#Copyright (c) 2011 ~ 2013 Deepin, Inc.
#              2013 ~ 2013 Li Liqiang
#
#Author:      Li Liqiang <liliqiang@linuxdeepin.com>
#Maintainer:  Li Liqiang <liliqiang@linuxdeepin.com>
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


forceShowTimer = null
dialog = null
s_dock = null
dockedAppmanager = null


class Item extends Widget
    @autostart_flag: null
    @hoverItem: null
    @clean_hover_temp: false
    @dragCanvas: null  # to resize the drag image.
    constructor: (@id, @name, @path, @icon)->
        super
        @element.removeAttribute("id")
        @element.dataset.appid = "#{@id}"
        @hoverBoxOutter = create_element("div", "hoverBoxOutter", @element)
        @hoverBoxOutter.dataset.appid = "#{@id}"
        @hoverBox = create_element("div", "hoverBox", @hoverBoxOutter)
        @basename = get_path_name(@path) + ".desktop"
        @isAutostart = false
        @status = SOFTWARE_STATE.IDLE

        im = get_default_application_icon(ITEM_IMG_SIZE)
        @img = create_img("item_img", im, @hoverBox)
        @load_image(@img)
        itemName = create_element("div", "item_name", @hoverBox)
        itemName.innerText = @name
        @hoverBoxOutter.draggable = true
        # @try_set_title(@element, @name, 80)
        # @element.setAttribute("title", @name)
        @elements = {'element': @element}#search: null

    @updateHorizontalMargin:->
        containerWidth = $("#container").clientWidth - GRID_PADDING * 2
        # console.log "containerWidth:#{containerWidth}"
        Item.itemNumPerLine = Math.floor(containerWidth / ITEM_WIDTH)
        # console.log "itemNumPerLine: #{Item.itemNumPerLine}"
        Item.horizontalMargin =  (containerWidth - Item.itemNumPerLine * ITEM_WIDTH) / 2 / Item.itemNumPerLine
        # console.log "horizontalMargin: #{Item.horizontalMargin}"
        for own id, info of applications
            info.updateProperty((k, v)->
                v.style.marginLeft = "#{Item.horizontalMargin}px"
                v.style.marginRight = "#{Item.horizontalMargin}px"
            )

    try_set_title: (el, text, width)->
        setTimeout(->
            height = calc_text_size(text, width)
            if height > 38
                el.setAttribute('title', text)
        , 200)

    destroy: ->
        delete @elements['element']
        for own k, v of @elements
            if k == 'search'
                @remove(k)
            else
                categoryList.category(k).removeItem(@id)
        delete Widget.object_table[@id]

    add:(pid, parent)->
        # if @elements[pid]
        #     console.log 'exist'
        #     return @elements[pid]

        el = @element.cloneNode(true)
        inner = el.firstElementChild.firstElementChild
        im = inner.firstElementChild
        # img may not be loaded.
        if im.classList.length == 1
            @load_image(im)

        @elements[pid] = el
        if pid != "search"
            if !parent?
                categoryList.addItem(@id, pid)
        parent?.appendChild(el)
        el

    remove:(pid)->
        el = @elements[pid]
        if not el
            return
        delete @elements[pid]
        pNode = el.parentNode
        pNode.removeChild(el)

    getElement:(pid)->
        @elements[pid]

    get_img: ->
        im = DCore.get_theme_icon(@icon, ITEM_IMG_SIZE)
        if im == null
            @icon = get_path_name(@path)

        im = DCore.get_theme_icon(@icon, ITEM_IMG_SIZE)
        if im == null
            im = get_default_application_icon(ITEM_IMG_SIZE)

        im

    update: (info)->
        # TODO: update category infos
        # update it.
        if @name != info?.name
            @name = info.name
            @updateProperty((k, el)=>
                innerBox = el.firstElementChild.firstElementChild
                itemName = @getItemNameDOM(el)
                itemName.innerText = @name
            )

        if @path != info?.path
            @path = info.path

        if @basename != info?.basename
            @basename = info.basename

        if @icon != info?.icon
            @icon = info.icon
            @updateIcon()

        if @isAutostart != info?.isAutostart
            @toggle_autostart()

        if @status != info?.status
            @status = info.status

    updateIcon:=>
        @updateProperty((k, el)=>
            im = @getImgDOM(el)
            @load_image(im)
        )

    getInnerBoxDOM:(el)->
        #  outter hover box  inner hover box
        el.firstElementChild.firstElementChild

    getImgDOM:(el)->
        @getInnerBoxDOM(el).children[0]

    getItemNameDOM:(el)->
        # cannot use lastElementChild here, the lastElementChild may be the
        # autostart flag.
        @getInnerBoxDOM(el).children[1]

    setImageSize: (img)=>
        if img.width == img.height
            # console.log 'set class name to square img'
            img.classList.add('square_img')
        else if img.width > img.height
            img.classList.add('hbar_img')
            new_height = ITEM_IMG_SIZE * img.height / img.width
            grap = (ITEM_IMG_SIZE - Math.floor(new_height)) / 2
            img.style.padding = "#{grap}px 0px"
        else
            img.classList.add('vbar_img')

    load_image: (img)->
        im = @get_img()
        if im == null
            img.classList.add("broken_img")
        # @img.draggable = true
        img.onload = (e) =>
            @setImageSize(img)
        img.onerror = =>
            console.warn("load img(#{img.src}) error")
            im = get_default_application_icon(ITEM_IMG_SIZE)
            img.classList.add("broken_img")
            if img.src != im
                img.src = im
                console.warn("using #{img.src} instead")
        img.src = im

    on_click: (e)->
        target = e?.target
        target?.style.cursor = "wait"
        e = e && e.originalEvent || e
        e?.stopPropagation()
        startManager.Launch(@path)
        Item.hoverItem = target.parentNode
        target?.style.cursor = "auto"
        daemon.RecordRate(@id)
        exit_launcher()

    setCanvas:(dt, width, height, xoffset=0, yoffset=0)->
        if Item.dragCanvas == null
            Item.dragCanvas = create_element(tag: 'canvas', width: ITEM_IMG_SIZE, height: ITEM_IMG_SIZE)
        ctx = Item.dragCanvas.getContext("2d")
        ctx.clearRect(0, 0, Item.dragCanvas.width, Item.dragCanvas.height)
        ctx.drawImage(@img, xoffset, yoffset, width, height)
        # extra 3px for mouse offset
        dt.setDragCanvas(Item.dragCanvas, ITEM_IMG_SIZE/2+3, ITEM_IMG_SIZE/2)

    on_dragstart: (e)=>
        # target is hoverBoxOutter
        target = e.target
        o = e
        e = e.originalEvent || e
        dt = e.dataTransfer

        if @img.width < @img.height
            new_width = ITEM_IMG_SIZE * @img.width / @img.height
            offset = (ITEM_IMG_SIZE - Math.floor(new_width)) / 2
            @setCanvas(dt, new_width, ITEM_IMG_SIZE, offse)
        else if @img.width > @img.height
            @img.classList.add('hbar_img')
            new_height = ITEM_IMG_SIZE * @img.height / @img.width
            offset = (ITEM_IMG_SIZE - Math.floor(new_height)) / 2
            @setCanvas(dt, ITEM_IMG_SIZE, new_height, 0, offset)
        else
            @setCanvas(dt, ITEM_IMG_SIZE, ITEM_IMG_SIZE)
            # dt.setDragImage(@img, ITEM_IMG_SIZE/2 + 3, ITEM_IMG_SIZE/2)

        dt.setData("text/uri-list", "file://#{@path}")
        data = "{\"id\":\"#{@id}\", \"name\": \"#{@name}\", \"path\": \"#{@path}\", \"icon\":\"#{@icon}\"}"
        dt.setData("uninstall", data)
        item = target.parentNode
        item.classList.add("item_dragged")
        dt.setData("text/plain", @id)
        dt.effectAllowed = "copy"
        categoryBar.dark()
        switcher.bright()

    on_dragend: (e)=>
        target = e.target
        item = target.parentNode
        item.classList.remove("item_dragged")

        e = e.originalEvent || e
        e.preventDefault()

        categoryBar.normal()
        switcher.normal()

        if !switcher.isShowCategory
            return

        switcher.notify()

    createMenu:->
        @menu = null
        try
            s_dock = DCore.DBus.session("com.deepin.dde.dock")#get_dbus("session", "com.deepin.dde.dock", "Xid")
        catch e
            console.error("get dock dbus failed", e)
            s_dock = null
        @isOnDock = true
        try
            # if failed, this will stuck.
            dockedAppmanager = DCore.DBus.session_object(
                "com.deepin.daemon.Dock",
                "/dde/dock/DockedAppManager",
                "dde.dock.DockedAppManager"
            )
            @isOnDock = dockedAppmanager.IsDocked_sync(@id)
        catch
            console.error("get dock app manager failed", e)
            @isOnDock = true
        @isOnDesktop = daemon.IsItemOnDesktop_sync(@path)
        @menu = new Menu(
            DEEPIN_MENU_TYPE.NORMAL,
            new MenuItem(1, _("_Open")),
            new MenuSeparator(),
            new MenuItem(3, SEND_TO_DESKTOP_MESSAGE[@isOnDesktop]),
            new MenuItem(4, SEND_TO_DOCK_MESSAGE[@isOnDock]).setActive(s_dock != null),
            new MenuSeparator(),
            new MenuItem(5, AUTOSTART_MESSAGE[@isAutostart]),
            new MenuItem(6, _("_Uninstall"))
        )

        # if DCore.DEntry.internal()
        #     @menu.addSeparator().append(
        #         new MenuItem(100, "report this bad icon")
        #     )

    on_rightclick: (e)->
        clearTimeout(forceShowTimer)
        DCore.Launcher.force_show(true)
        e = e && e.originalEvent || e
        e.preventDefault()
        e.stopPropagation()

        console.log("create menu")
        @createMenu()

        # console.log @menu
        # return
        @menu.unregisterHook(->
            forceShowTimer = setTimeout(->
                console.log("force show menu unregister")
                if isNotForceShow
                    DCore.Launcher.force_show(false)
            , 100)
        )
        @menu.addListener(@on_itemselected).showMenu(e.screenX, e.screenY)

    on_itemselected: (id)=>
        id = parseInt(id)
        isNotForceShow = true
        switch id
            when 1
                startManager.Launch(@basename)
                # exit_launcher()
            when 3
                if @isOnDesktop
                    daemon.RequestRemoveFromDesktop(@path)
                else
                    daemon.RequestSendToDesktop(@path)
            when 4
                try
                    dock = get_dbus(
                        "session",
                        name:"com.deepin.daemon.Dock",
                        path:"/dde/dock/DockedAppManager",
                        interface:"dde.dock.DockedAppManager",
                        "DockedAppList"
                    )
                    console.log(@id)
                    if @isOnDock
                        dock.Undock(@id)
                    else
                        dock.Dock(@id, "", "", "")
                catch e
                    console.log(e)

            when 5 then @toggle_autostart()
            when 6
                dialog = get_dbus('session', "com.deepin.dialog", "ShowUninstall")
                dialog.connect("ActionInvoked", @uninstallHandler)
                clearTimeout(forceShowTimer)
                DCore.Launcher.force_show(true)
                dialog.ShowUninstall(@icon, _("Are you sure to remove") + " \"#{@name}\" ", _("All dependencies will be removed"), ["1", _("no"), "2", _("yes")])
                isNotForceShow = false
            # when 100 then DCore.DEntry.report_bad_icon(@path)  # internal
        if isNotForceShow
            console.log("force show rightclick")
            DCore.Launcher.force_show(false)

    uninstallHandler: (id, action)=>
        DCore.Launcher.force_show(true)
        console.log("action: #{action}")
        switch action
            when "1"
                console.log("click NO")
                console.log("NO")
            when "2"
                @status = SOFTWARE_STATE.UNINSTALLING
                @hide()
                categoryList.hideEmptyCategories()
                console.log 'start uninstall'
                if @icon.indexOf("data:image") != -1
                    icon = @icon
                else
                    icon = DCore.get_theme_icon(@icon, 48)
                icon = DCore.backup_app_icon(icon)
                console.warn("set icon: #{icon} to notify icon")
                uninstaller = new Uninstaller(@id, "Deepin Launcher", icon, uninstallFailedHandler, uninstallSuccessHandler)
                # make sure the icon is hidden immediately
                setTimeout(=>
                    uninstaller.uninstall()
                , 100)
        dialog.dis_connect("ActionInvoked", @uninstallHandler)
        dialog = null
        forceShowTimer = setTimeout(->
            console.log("force show false")
            DCore.Launcher.force_show(false)
        , 100)

    updateProperty: (fn)->
        for own k, v of @elements
            if v
                fn(k, v)

    showAutostartFlag:->
        icon = DCore.get_theme_icon(AUTOSTART_ICON.NAME, AUTOSTART_ICON.SIZE)
        autostartFlagPath = if icon then "file://#{icon}" else "img/emblem-autostart.png"
        Item.autostart_flag ?= autostartFlagPath

        @updateProperty((k, v)=>
            innerBox = @getInnerBoxDOM(v)
            last = innerBox.lastElementChild
            @getItemNameDOM(v)
            if last.tagName != 'IMG'
                create_img("autostart_flag", Item.autostart_flag, innerBox)
            last.style.visibility = 'visible'
        )

    hideAutostartFlag:->
        @updateProperty((k, v)=>
            innerBox = @getInnerBoxDOM(v)
            last = innerBox.lastElementChild
            if last.tagName == 'IMG'
                last.style.visibility = 'hidden'
        )

    add_to_autostart: ->
        # console.log @basename
        if startManager.AddAutostart_sync(@path)
            # console.log 'add success'
            @isAutostart = true
            @showAutostartFlag()

    remove_from_autostart: ->
        if startManager.RemoveAutostart_sync(@path)
            @isAutostart = false
            @hideAutostartFlag()

    toggle_autostart: ->
        if @isAutostart
            @remove_from_autostart()
        else
            @add_to_autostart()

    hide: ->
        @updateProperty((k, v)->
            v.style.display = "none"
        )

    show: =>
        if @status == SOFTWARE_STATE.IDLE
            @updateProperty((k, v)->
                v.style.display = "-webkit-box"
            )

    on_mouseover: (e)=>
        # this event is a wrap, use e.originalEvent to get the original event
        # the target is hoverBoxOutter
        target = e.target
        Item.hoverItem = target.parentNode
        if not Item.clean_hover_temp
            item = target.parentNode
            item.classList.add("item_hovered")

    on_mouseout: (e)=>
        target = e.target
        item = target.parentNode
        item.classList.remove("item_hovered")
