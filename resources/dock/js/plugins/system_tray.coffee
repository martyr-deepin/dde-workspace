class SystemTray extends SystemItem
    constructor:(@id, icon, title)->
        super
        @img.src = icon
        @imgContainer.removeEventListener("mouseout", @on_mouseout)
        @panel = create_element(tag:"div", class:"SystemTrayPanel", @imgWrap)
        @panel.style.display = 'none'
        @panel.addEventListener("mouseover", @on_mouseover)
        @panel.addEventListener("mouseout", @on_mouseout)
        @panel.addEventListener("click", (e)->e.preventDefault();e.stopPropagation())
        @panel.addEventListener("contextmenu", @on_rightclick)
        @openIndicator.style.display = 'none'
        @isUnfolded = false
        @button = create_element(tag:'div', class:'TrayFoldButton', @imgWrap)
        @button.addEventListener('mouseover', @on_mouseover)
        @button.addEventListener('click', @on_button_click)
        @isTransitionDone = true

        @element.addEventListener("webkitTransitionEnd", (e)=>
            webkitCancelAnimationFrame(@calcTimer)
            if @isUnfolded
                @updateTrayIcon()
                @showAllIcons()
                if debugRegion
                    console.warn("[SystemTray.webkitTransitionEnd] unfolded")
                console.log("update dock region")
                @updateTrayIconPanel(@upperItemNumber)
            else
                @displayIcon()
                @img.style.display = ''
                @panel.style.display = 'none'
                if debugRegion
                    console.warn("[SystemTray.webkitTransitionEnd] folded")
            update_dock_region()
            @isTransitionDone = true
        )

        @isShowing = false
        if settings and settings.displayMode() != DisplayMode.Fashion
            # TODO: fold tray icons
            @isUnfolded = true # tmp

        try
            @core = get_dbus(
                'session',
                name:"com.deepin.dde.TrayManager",
                path:"/com/deepin/dde/TrayManager",
                interface: "com.deepin.dde.TrayManager",
                "TrayIcons"
            )
        catch e
            console.log(e)
            @core = null

        @items = []
        @clearItems()

        @core.connect("Added", (xid)=>
            console.log("tray icon: #{xid} is Added, #{@isShowing}")
            @items.unshift(xid) if @items.indexOf(xid) == -1
            $EW.create(xid, true, $EWType.TrayIcon)
            if @isShowing and hideStatusManager?.state == HideState.Shown
                if @items.length > 4
                    # @hideAllIcons()
                    @unfold()
                    @showButton()
                console.log("added show")
                $EW.show(xid)
                # creat will take a while.
                @updateTrayIcon()
                if @isUnfolded
                    @showAllIcons()
                else
                    @minShow()
                setTimeout(=>
                    @updateTrayIcon()
                    calc_app_item_size()
                , SHOW_HIDE_ANIMATION_TIME)
            else
                $EW.undraw(xid)
                # $EW.hide(xid)
        )
        @core.connect("Changed", (xid)=>
            if !READY_FOR_TRAY_ICONS
                @items.remove(xid)
                @items.unshift(xid)
                return

            if @items.length == 0
                @hideButton()
                if @isUnfolded
                    @fold()
                return

            # console.log("tray icon #{xid} is Changed")
            if hideStatusManager?.state != HideState.Shown
                console.log("the dock is not shown")
                return

            @isShowing = true
            @img.style.display = 'none'
            @panel.style.display = ''
            @imgContainer.style.webkitTransform = 'translateY(0)'
            @imgContainer.style.webkitTransition = ''
            if @items.length > 4
                @showButton()
            @items.remove(xid)
            @items.unshift(xid)
            @updateTrayIcon()
            @showAllIcons()
            if @upperItemNumber > 2
                @unfold()
        )
        @core.connect("Removed", (xid)=>
            console.log("tray icon #{xid} is Removed")
            @items.remove(xid)
            $EW.dismiss(xid)

            if @items.length == 0
                @hideButton()
                if @isUnfolded
                    @fold()
                return

            # TODO:
            # another way to fold for classic mode.
            if @isShowing and settings.displayMode() == DisplayMode.Fashion
                if @items.length == 4
                    @hideButton()
                    if @isUnfolded
                        @fold()

            @updateTrayIcon()
            setTimeout(=>
                @updateTrayIcon()
                calc_app_item_size()
            , SHOW_HIDE_ANIMATION_TIME)
        )


        @updateTrayIcon()

        @core.RetryManager_sync()

    clearItems:->
        for item in @items.slice(0)
            $EW.dismiss(item)
        if Array.isArray @core.TrayIcons
            @items = @core.TrayIcons.slice(0) || []

    updateTrayIcon:=>
        run_callback_after_prop_changed(
            =>
                @updateTrayIconForMode(settings.displayMode())
            $("#panel").offsetTop
            -> $("#panel").offsetTop
            50
            1000
        )

    updateTrayIconForMode: (mode)=>
        name = DisplayName[mode]
        if not name?
            return
        name = name[0].toUpperCase() + name.substr(1).toLowerCase()
        @["updateTrayIconFor#{name}"]?()

    updateTrayIconForClassic:=>
        # console.warn("updateTrayIconForClassic")
        trayarea = $("#system")
        trayarea.style.marginLeft = @items.length * (TRAY_ICON_MARGIN * 2 + TRAY_ICON_WIDTH)
        y = (DOCK_HEIGHT - TRAY_ICON_HEIGHT) / 2 + $("#panel").offsetTop
        for item, i in @items
            x = trayarea.offsetLeft + TRAY_ICON_MARGIN - (i + 1) * (TRAY_ICON_WIDTH + TRAY_ICON_MARGIN * 2)
            # console.warn("move #{item} to #{x}x#{y}")
            $EW.move_resize(item, x, y, TRAY_ICON_WIDTH, TRAY_ICON_HEIGHT)
            # @showAllIcons()

    updateTrayIconForEfficient:=>
        # console.warn("updateTrayIconForEfficient")
        # TODO: change margin-left
        trayarea = $("#system")
        trayarea.style.marginLeft = @items.length * (TRAY_ICON_MARGIN * 2 + TRAY_ICON_WIDTH)
        y = (DOCK_HEIGHT - TRAY_ICON_HEIGHT) / 2 + $("#panel").offsetTop
        for item, i in @items
            x = trayarea.offsetLeft + TRAY_ICON_MARGIN - (i + 1) * (TRAY_ICON_WIDTH + TRAY_ICON_MARGIN * 2)
            # console.warn("move #{item} to #{x}x#{y}")
            $EW.move_resize(item, x, y, TRAY_ICON_WIDTH, TRAY_ICON_HEIGHT)
            # @showAllIcons()

    updateTrayIconForFashion:=>
        if $("#system").style.marginLeft != ''
            $("#system").style.marginLeft = ''
        #console.log("update the order: #{@items}")
        @upperItemNumber = Math.max(Math.ceil(@items.length / 2), 2)
        if @items.length > 4 && @items.length % 2 == 0
            @upperItemNumber += 1

        SHADOW_WIDTH = 4
        itemSize = 20

        newWidth = 0
        if @isUnfolded && @upperItemNumber > 2
            newWidth = (@upperItemNumber) * itemSize
            # console.log("set width to #{newWidth}")
            # @panel.style.width = "#{newWidth}px"
            @element.style.width = "#{newWidth + SHADOW_WIDTH*2}px"
            # @panel.style.backgroundPosition = "0 -#{(@upperItemNumber - 2) * 48}"
        else if not @isUnfolded
            newWidth = 2 * itemSize
            # @panel.style.width = "#{newWidth}px"
            @element.style.width = "#{newWidth + SHADOW_WIDTH*2}px"
            # @panel.style.backgroundPosition = "0 0"

        xy = get_page_xy(@element)
        for item, i in @items
            x = xy.x + SHADOW_WIDTH + 2
            y = xy.y + SHADOW_WIDTH + 3
            if i < @upperItemNumber
                x += i * itemSize
            else
                x += (i - @upperItemNumber) * itemSize
                y += itemSize
            # console.log("move tray icon #{item} to #{x}, #{y}")
            $EW.move_resize(item, x, y, TRAY_ICON_WIDTH, TRAY_ICON_HEIGHT)

    updatePanel:=>
        calc_app_item_size()
        # panel.set_width($("#container").clientWidth)
        if debugRegion
            console.warn("[SystemTray.updatePanel] update_dock_region")
        update_dock_region($("#container").clientWidth)
        if $("#container").clientWidth != panel.width()
            @calcTimer = webkitRequestAnimationFrame(@updatePanel)

    hideAllIcons:=>
        # console.error("hideAllIcons")
        for item in @items
            $EW.undraw(item)

    showAllIcons:=>
        # console.error("showAllIcons")
        if hideStatusManager and hideStatusManager.state != HideState.Shown
            console.log("[showAllIcons] #{HideStateMap[hideStatusManager.state]}")
            return
        for item in @items
            $EW.show(item)
        @isShowing = true

    showButton:->
        @button.style.visibility = 'visible'

    hideButton:->
        @button.style.visibility = 'hidden'

    on_mouseover: (e)=>
        if !@isTransitionDone
            return

        Preview_close_now(_lastCliengGroup)
        if @isUnfolded
            #console.log("is unfolded")
            return
        DCore.Dock.require_all_region()
        # console.log("system tray mouseover")
        @minShow()

    minShow:=>
        if hideStatusManager and hideStatusManager.state != HideState.Shown
            console.log("[minShow] #{HideStateMap[hideStatusManager.state]}")
            return
        # console.error("minShow")
        @isShowing = true
        @img.style.display = 'none'
        @panel.style.display = ''
        @updateTrayIcon()
        if @items.length > 4
            @showButton()
        @imgContainer.style.webkitTransform = 'translateY(0)'
        @imgContainer.style.webkitTransition = ''
        $EW.show(@items[0]) if @items[0]
        $EW.show(@items[1]) if @items[1]
        if @items[2] and @items.length <= 4
            console.log("tray icons length: #{@items.length}")
            $EW.show(@items[2])
        i = if @upperItemNumber == 2 then @upperItemNumber + 1 else @upperItemNumber
        # console.log("the last tray icon to be shown #{i}")
        $EW.show(@items[i]) if @items[i]

    on_mouseout: (e)=>
        # console.log("system tray mouseout")
        # super
        DCore.Dock.set_is_hovered(false)
        clearTimeout(@showEmWindowTimer)
        if debugRegion
            console.warn("[SystemTray.on_mouseout] update_dock_region")
        update_dock_region()
        hideStatusManager?.updateState()

        if @isUnfolded
            return

        @isShowing = false
        # console.log("tray mouseout")
        @img.style.display = ''
        @panel.style.display = 'none'
        @hideAllIcons()
        @hideButton()

    updateTrayIconPanel:(n)->
        @panel.style.backgroundPosition = "0 -#{(n - 2)*48}"

    unfold:=>
        console.log("unfold")
        @isUnfolded = true
        @button.style.backgroundPosition = '0 0'
        webkitCancelAnimationFrame(@calcTimer || null)
        @updatePanel()
        # @hideAllIcons()
        @updateTrayIcon()
        if @upperItemNumber <= 2
            webkitCancelAnimationFrame(@calcTimer)
            @showAllIcons()
            if debugRegion
                console.warn("[SystemTray.unfold] update_dock_region")
            @updateTrayIconPanel(@upperItemNumber)
            update_dock_region()

    fold: (e)=>
        @updateTrayIconPanel(2)
        @isUnfolded = false
        @button.style.backgroundPosition = '100% 0'
        console.log("fold")
        @hideAllIcons()
        webkitCancelAnimationFrame(@calcTimer)
        @updatePanel()
        @updateTrayIcon()
        if @upperItemNumber <= 2
            @displayIcon()
            @img.style.display = ''
            @panel.style.display = 'none'
            webkitCancelAnimationFrame(@calcTimer)
            if debugRegion
                console.warn("[SystemTray.fold] update_dock_region")
            update_dock_region()

        @hideButton()

    on_button_click:(e)=>
        e.stopPropagation()
        if @upperItemNumber <= 2
            return

        @isTransitionDone = false
        if @isUnfolded
            @fold()
        else
            @hideAllIcons()
            @unfold()

    on_rightclick: (e)=>
        e.preventDefault()
        e.stopPropagation()
        DCore.Dock.set_is_hovered(false)
        if debugRegion
            console.warn("[SystemTray.on_rightclick] update_dock_region")
        update_dock_region($("#container").clientWidth)
        Preview_close_now()

    on_mousedown: (e)=>

    on_mouseup: (e)=>
