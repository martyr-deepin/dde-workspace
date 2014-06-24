class SystemTray extends SystemItem
    constructor:(@id, icon, title)->
        super
        @imgContainer.removeEventListener("mouseout", @on_mouseout)
        @panel = create_element(tag:"div", class:"SystemTrayPanel", @imgWarp)
        @panel.style.display = 'none'
        @panel.addEventListener("mouseover", @on_mouseover)
        @panel.addEventListener("mouseout", @on_mouseout)
        @panel.addEventListener("click", (e)->e.preventDefault();e.stopPropagation())
        @openIndicator.style.display = 'none'
        @isUnfolded = false
        @button = create_element(tag:'div', class:'TrayFoldButton', @imgWarp)
        @button.addEventListener('mouseover', @on_mouseover)
        @button.addEventListener('click', @on_button_click)

        @core = get_dbus(
            'session',
            name:"com.deepin.dde.TrayManager",
            path:"/com/deepin/dde/TrayManager",
            interface: "com.deepin.dde.TrayManager",
            "TrayIcons"
        )

        @items = []
        if Array.isArray @core.TrayIcons
            @items = @core.TrayIcons.slice(0) || []
        # console.log("TrayIcons: #{@items}")
        for item, i in @items
            # console.log("#{item} add to SystemTray")
            $EW.create(item, false)
            # $EW.hide(item)
            $EW.undraw(item)

        @core.connect("Added", (xid)=>
            console.log("#{xid} is Added")
            @items.unshift(xid) if @items.indexOf(xid) == -1
            $EW.create(xid, true)
            if @isShowing
                if @items.length > 4
                    @unfold()
                    @showButton()
                console.log("added show")
                $EW.show(xid)
                # creat will take a while.
                @updateTrayIcon()
                setTimeout(=>
                    @updateTrayIcon()
                    calc_app_item_size()
                , ANIMATION_TIME)
            else
                $EW.undraw(xid)
                # $EW.hide(xid)
        )
        @core.connect("Changed", (xid)=>
            @isShowing = true
            @img.style.display = 'none'
            @panel.style.display = ''
            @imgContainer.style.webkitTransform = 'translateY(0)'
            @imgContainer.style.webkitTransition = ''
            if @items.length > 4
                @showButton()
            console.log("#{xid} is Changed")
            @items.remove(xid)
            @items.unshift(xid)
            @unfold()
            if @upperItemNumber <= 2
                @isUnfolded = false
        )
        @core.connect("Removed", (xid)=>
            # console.log("#{xid} is Removed")
            @items.remove(xid)

            if @isShowing
                if @items.length == 4
                    @hideButton()
                    if @isUnfolded
                        @fold()

                @on_mouseover()

            @updateTrayIcon()
            setTimeout(=>
                @updateTrayIcon()
                calc_app_item_size()
            , ANIMATION_TIME)
        )


        @updateTrayIcon()

    updateTrayIcon:=>
        #console.log("update the order: #{@items}")
        @upperItemNumber = Math.max(Math.ceil(@items.length / 2), 2)
        if @items.length > 4 && @items.length % 2 == 0
            @upperItemNumber += 1

        iconSize = 16
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
            $EW.move_resize(item, x, y, iconSize, iconSize)

    updatePanel:=>
        calc_app_item_size()
        @calcTimer = webkitRequestAnimationFrame(@updatePanel)


    showButton:->
        @button.style.visibility = 'visible'

    hideButton:->
        @button.style.visibility = 'hidden'

    on_mouseover: (e)=>
        Preview_close_now(_lastCliengGroup)
        if @isUnfolded
            console.log("is unfolded")
            return
        @isShowing = true
        @img.style.display = 'none'
        @panel.style.display = ''
        @updateTrayIcon()
        if @items.length > 4
            @showButton()
        DCore.Dock.require_all_region()
        @imgContainer.style.webkitTransform = 'translateY(0)'
        @imgContainer.style.webkitTransition = ''
        # for item,i in @items
        #     if i == 0 || i == 1
        #         continue
        #     $EW.move(item, 0, 0)
        $EW.show(@items[0]) if @items[0]
        $EW.show(@items[1]) if @items[1]
        if @items[2] and @items.length <= 4
            console.log("length: #{@items.length}")
            $EW.show(@items[2])
        i = if @upperItemNumber == 2 then @upperItemNumber + 1 else @upperItemNumber
        console.log("show #{i}")
        $EW.show(@items[i]) if @items[i]

    on_mouseout: (e)=>
        console.warn("system tray mouseout")
        # super
        DCore.Dock.set_is_hovered(false)
        clearTimeout(@showEmWindowTimer)
        update_dock_region()
        if @isUnfolded
            return

        @isShowing = false
        console.log("tray mouseout")
        @img.style.display = ''
        @panel.style.display = 'none'
        for item in @items
            $EW.undraw(item)
        @hideButton()

    unfold:=>
        console.log("unfold")
        @isUnfolded = true
        @button.style.backgroundPosition = '0 0'
        clearTimeout(@hideTimer)
        webkitCancelAnimationFrame(@calcTimer || null)
        @updatePanel()
        for item in @items
            $EW.undraw(item)
        @updateTrayIcon()
        if @upperItemNumber > 2
            clearTimeout(@showTimer)
            @showTimer = setTimeout(=>
                webkitCancelAnimationFrame(@calcTimer)
                @updateTrayIcon()
                for item in @items
                    $EW.show(item)
                update_dock_region()
                console.warn("update dock region")
            , ANIMATION_TIME)
        else
            webkitCancelAnimationFrame(@calcTimer)
            for item in @items
                $EW.show(item)
            update_dock_region()

    fold: (e)=>
        @isUnfolded = false
        @button.style.backgroundPosition = '100% 0'
        console.log("fold")
        if @items
            for item in @items
                $EW.undraw(item)
        clearTimeout(@showTimer)
        webkitCancelAnimationFrame(@calcTimer)
        @updatePanel()
        @updateTrayIcon()
        if @upperItemNumber > 2
            clearTimeout(@hideTimer)
            @hideTimer = setTimeout(=>
                @img.style.display = ''
                @panel.style.display = 'none'
                webkitCancelAnimationFrame(@calcTimer)
                update_dock_region()
            , ANIMATION_TIME)
        else
            @img.style.display = ''
            @panel.style.display = 'none'
            webkitCancelAnimationFrame(@calcTimer)
            update_dock_region()

        @hideButton()

    on_button_click:(e)=>
        e.stopPropagation()
        if @upperItemNumber <= 2
            return
        if @isUnfolded
            @fold()
        else
            @unfold()

    on_rightclick: (e)=>
        e.preventDefault()
        e.stopPropagation()
