class SystemTray extends SystemItem
    constructor:(@id, @icon, title)->
        super
        @openIndicator.style.display = 'none'
        @core = get_dbus(
            'session',
            name:"com.deepin.dde.TrayManager",
            path:"/com/deepin/dde/TrayManager",
            interface: "com.deepin.dde.TrayManager"
        )

        @core.connect("Added", (xid)=>
            # console.log("#{xid} is Added")
            @items.unshift(xid)
            $EW.create(xid, true)
            if @isShowing
                # console.log("added show")
                $EW.show(xid)
            else
                $EW.hide(xid)
            # creat will take a while.
            setTimeout(=>
                @updateTrayIcon()
                calc_app_item_size()
            , 400)
        )
        @core.connect("Changed", (xid)=>
            # console.log("#{xid} is Changed")
            @items.remove(xid)
            @items.unshift(xid)
            @updateTrayIcon()
        )
        @core.connect("Removed", (xid)=>
            # console.log("#{xid} is Removed")
            @items.remove(xid)
            setTimeout(=>
                @updateTrayIcon()
                calc_app_item_size()
            , 400)
        )

        @items = @core.TrayIcons.slice(0)
        # @ews = new EmbedWindow(@items, false)
        # @ews.show()
        # console.log("TrayIcons: #{@items}")
        for item, i in @items
            # console.log("#{item} add to SystemTray")
            $EW.create(item, false)
            $EW.hide(item)

        @updateTrayIcon()

    updateTrayIcon:=>
        #console.log("update the order: #{@items}")
        @upperItemNumber = Math.max(Math.ceil(@items.length / 2), 2)
        # if @items.length % 2 == 0
        #     @upperItemNumber += 1

        iconSize = 16
        itemSize = 18

        if @isShowing && @upperItemNumber >= 2
            newWidth = @upperItemNumber * itemSize
            # console.log("set width to #{newWidth}")
            @img.style.width = "#{newWidth}px"
            # @imgWarp.style.width = "#{newWidth + 16}px"
            @element.style.width = "#{newWidth + 18}px"
        else if not @isShowing && @upperItemNumber > 2
            newWidth = 2 * itemSize
            @img.style.width = "#{newWidth}px"
            # @imgWarp.style.width = "#{newWidth + 16}px"
            @element.style.width = "#{newWidth + 18}px"
        xy = get_page_xy(@element)
        for item, i in @items
            x = xy.x + 10
            y = xy.y + 6
            if i < @upperItemNumber
                x += i * itemSize
            else
                x += (i - @upperItemNumber) * itemSize
                y += itemSize
            # console.log("move tray icon #{item} to #{x}, #{y}")
            $EW.move_resize(item, x, y, iconSize, iconSize)

    updatePanel:=>
        calc_app_item_size()
        DCore.Dock.require_all_region()
        @calcTimer = webkitRequestAnimationFrame(@updatePanel)

    on_mouseover: (e)=>
        clearTimeout(@hideTimer)
        webkitCancelAnimationFrame(@calcTimer || null)
        @updatePanel()
        # console.log("mouseover")
        @isShowing = true
        @updateTrayIcon()
        Preview_close_now(_lastCliengGroup)
        if @upperItemNumber > 2
            @showTimer = setTimeout(=>
                webkitCancelAnimationFrame(@calcTimer)
                @updateTrayIcon()
                for item in @items
                    $EW.show(item)
            , 400)
        else
            webkitCancelAnimationFrame(@calcTimer)
            for item in @items
                $EW.show(item)
        super

    on_mouseout: (e)=>
        # console.log("mouseout")
        clearTimeout(@showTimer)
        webkitCancelAnimationFrame(@calcTimer)
        @updatePanel()
        @isShowing = false
        for item in @items
            $EW.hide(item)
        @updateTrayIcon()
        @hideTimer = setTimeout(=>
            webkitCancelAnimationFrame(@calcTimer)
            super
        , 400)

    on_rightclick: (e)=>
        e.preventDefault()
        e.stopPropagation()
