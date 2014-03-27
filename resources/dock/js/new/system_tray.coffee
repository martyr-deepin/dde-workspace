class SystemTray extends SystemItem
    constructor:(@id, @icon, title)->
        super
        @imgWarp.firstElementChild.style.display = 'none'
        @openIndicator.style.display = 'none'
        @button = create_element(tag:"div", class:"trayButton", @imgWarp)
        @button.textContent = "X"
        @button.style.pointerEvents = "auto"
        @button.addEventListener("click", (e)=>
            console.log("click")
            e.preventDefault()
            e.stopPropagation()
        )
        # FIXME:
        # why
        @button.addEventListener("mouseover", @on_mouseover)
        @button.addEventListener("mouseout", @on_mouseout)
        @core = get_dbus(
            'session',
            name:"com.deepin.dde.TrayManager",
            path:"/com/deepin/dde/TrayManager",
            interface: "com.deepin.dde.TrayManager"
        )

        @core.connect("Added", (xid)=>
            console.log("#{xid} is Added")
            @items.unshift(xid)
            $EW.create(xid, true)
            # creat will take a while.
            setTimeout(=>
                @updateTrayIcon()
            , 100)
        )
        @core.connect("Changed", (xid)=>
            console.log("#{xid} is Changed")
            @items.remove(xid)
            @items.unshift(xid)
            setTimeout(=>
                @updateTrayIcon()
            , 100)
        )
        @core.connect("Removed", (xid)=>
            console.log("#{xid} is Removed")
            @items.remove(xid)
            setTimeout(=>
                @updateTrayIcon()
            , 100)
        )

        @items = @core.TrayIcons.slice(0)
        # @ews = new EmbedWindow(@items, false)
        # @ews.show()
        console.log("TrayIcons: #{@items}")
        for item, i in @items
            console.log("#{item} add to SystemTray")
            $EW.create(item, false)
            $EW.show(item)

        @updateTrayIcon()

    updateTrayIcon:=>
        console.log("update the order: #{@items}")
        @upperItemNumber = Math.ceil(@items.length / 2)
        if @items.length % 2 == 0
            @upperItemNumber += 1
        xy = get_page_xy(@element)
        iconSize = 16
        itemSize = 19
        for item, i in @items
            x = xy.x + 9
            y = xy.y + 6
            if i < @upperItemNumber
                x += i * itemSize
            else
                x += (i - @upperItemNumber) * itemSize
                y += itemSize
            console.log("move tray icon #{item} to #{x}, #{y}")
            $EW.move_resize(item, x, y, iconSize, iconSize)

    unfold:->
        console.log("unfold")

    fold:->
        console.log("fold")

    on_mouseover: (e)=>
        super
        @button.style.visibility = 'visible'

    on_mouseout: (e)=>
        super
        @button.style.visibility = 'hidden'

    on_rightclick: (e)=>
        e.preventDefault()
        e.stopPropagation()
