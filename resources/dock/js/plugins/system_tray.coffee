
class SystemTray extends SystemItem
    constructor:(@id, icon, title)->
        super
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
            $EW.create(xid, true)
            if @isShowing
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
                    updateMaxClientListWidth()
                , SHOW_HIDE_ANIMATION_TIME)
            else
                updateMaxClientListWidth()
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

            console.log("tray icon #{xid} is Changed")
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

            if @items.length == 0
                @hideButton()
                if @isUnfolded
                    @fold()
                updateMaxClientListWidth()
                return

            # TODO:
            # another way to fold for classic mode.
            if @isShowing and settings.displayMode() == DisplayMode.Fashion
                if @items.length == 4
                    @hideButton()
                    if @isUnfolded
                        @fold()

            updateMaxClientListWidth()
                # @isShowing = true
                # @img.style.display = 'none'
                # @panel.style.display = ''
                # @imgContainer.style.webkitTransform = 'translateY(0)'
                # @imgContainer.style.webkitTransition = ''
                # if @items.length > 4
                #     @showButton()

            @updateTrayIcon()
            setTimeout(=>
                @updateTrayIcon()
                calc_app_item_size()
            , SHOW_HIDE_ANIMATION_TIME)
        )


        @updateTrayIcon()

        @core.RetryManager_sync()

    clearItems:->
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
        trayarea = $("#trayarea")
        y = (DOCK_HEIGHT - TRAY_ICON_HEIGHT) / 2 + trayarea.offsetTop
        for item, i in @items
            x = trayarea.offsetLeft + TRAY_ICON_MARGIN - (i + 1) * (TRAY_ICON_WIDTH + TRAY_ICON_MARGIN * 2)
            # console.warn("move #{item} to #{x}x#{y}")
            $EW.move_resize(item, x, y, TRAY_ICON_WIDTH, TRAY_ICON_HEIGHT)
            # @showAllIcons()

    updateTrayIconForEfficient:=>
        # console.warn("updateTrayIconForEfficient")
        trayarea = $("#trayarea")
        y = (44 - TRAY_ICON_HEIGHT) / 2 + trayarea.offsetTop
        for item, i in @items
            x = trayarea.offsetLeft + TRAY_ICON_MARGIN - (i + 1) * (TRAY_ICON_WIDTH + TRAY_ICON_MARGIN * 2)
            # console.warn("move #{item} to #{x}x#{y}")
            $EW.move_resize(item, x, y, TRAY_ICON_WIDTH, TRAY_ICON_HEIGHT)
            # @showAllIcons()

    updateTrayIconForFashion:=>
        #console.log("update the order: #{@items}")
        @upperItemNumber = Math.max(Math.ceil(@items.length / 2), 2)
        if @items.length > 4 && @items.length % 2 == 0
            @upperItemNumber += 1

        itemSize = 18

        if @isUnfolded && @upperItemNumber > 2
            newWidth = (@upperItemNumber) * itemSize
            # console.log("set width to #{newWidth}")
            @panel.style.width = "#{newWidth}px"
            @element.style.width = "#{newWidth + 12}px"
        else if not @isUnfolded
            newWidth = 2 * itemSize
            @panel.style.width = "#{newWidth}px"
            @element.style.width = "#{newWidth + 12}px"

        xy = get_page_xy(@element)
        for item, i in @items
            x = xy.x + 7
            y = xy.y + 7
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
        @calcTimer = webkitRequestAnimationFrame(@updatePanel)

    hideAllIcons:=>
        for item in @items
            $EW.undraw(item)

    showAllIcons:=>
        for item in @items
            $EW.show(item)

    showButton:->
        @button.style.visibility = 'visible'

    hideButton:->
        @button.style.visibility = 'hidden'

    on_mouseover: (e)=>
        Preview_close_now(_lastCliengGroup)
        if @isUnfolded
            console.log("is unfolded")
            return
        DCore.Dock.require_all_region()
        console.log("system tray mouseover")
        @minShow()

    minShow:=>
        @isShowing = true
        @img.style.display = 'none'
        @panel.style.display = ''
        @updateTrayIcon()
        if @items.length > 4
            @showButton()
        @imgContainer.style.webkitTransform = 'translateY(0)'
        @imgContainer.style.webkitTransition = ''
        # for item,i in @items
        #     if i == 0 || i == 1
        #         continue
        #     $EW.move(item, 0, 0)
        $EW.show(@items[0]) if @items[0]
        $EW.show(@items[1]) if @items[1]
        if @items[2] and @items.length <= 4
            console.log("tray icons length: #{@items.length}")
            $EW.show(@items[2])
        i = if @upperItemNumber == 2 then @upperItemNumber + 1 else @upperItemNumber
        console.log("the last tray icon to be shown #{i}")
        $EW.show(@items[i]) if @items[i]

    on_mouseout: (e)=>
        console.log("system tray mouseout")
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
        console.log("tray mouseout")
        @img.style.display = ''
        @panel.style.display = 'none'
        @hideAllIcons()
        @hideButton()

    unfold:=>
        console.log("unfold")
        @isUnfolded = true
        @button.style.backgroundPosition = '0 0'
        clearTimeout(@hideTimer)
        webkitCancelAnimationFrame(@calcTimer || null)
        @updatePanel()
        # @hideAllIcons()
        @updateTrayIcon()
        if @upperItemNumber > 2
            clearTimeout(@showTimer)
            @showTimer = setTimeout(=>
                webkitCancelAnimationFrame(@calcTimer)
                @updateTrayIcon()
                @showAllIcons()
                if debugRegion
                    console.warn("[SystemTray.unfold] update_dock_region")
                update_dock_region()
                console.log("update dock region")
            , SHOW_HIDE_ANIMATION_TIME)
        else
            webkitCancelAnimationFrame(@calcTimer)
            @showAllIcons()
            if debugRegion
                console.warn("[SystemTray.unfold] update_dock_region")
            update_dock_region()

    fold: (e)=>
        @isUnfolded = false
        @button.style.backgroundPosition = '100% 0'
        console.log("fold")
        @hideAllIcons()
        clearTimeout(@showTimer)
        webkitCancelAnimationFrame(@calcTimer)
        @updatePanel()
        @updateTrayIcon()
        if @upperItemNumber > 2
            clearTimeout(@hideTimer)
            @hideTimer = setTimeout(=>
                @displayIcon()
                @img.style.display = ''
                @panel.style.display = 'none'
                webkitCancelAnimationFrame(@calcTimer)
                if debugRegion
                    console.warn("[SystemTray.fold] update_dock_region")
                update_dock_region()
            , SHOW_HIDE_ANIMATION_TIME)
        else
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
