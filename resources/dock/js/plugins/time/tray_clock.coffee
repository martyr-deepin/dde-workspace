class TrayClock extends ClockWith24Hour
    constructor:(setting, parent)->
        super(setting)
        @type = Clock.Type.Tray
        @time = create_element(tag:'div', id:'timeWrap')
        @timeContent = create_element(tag:'div', id:"timeContent", @time)
        parent.parentNode.insertBefore(@time, parent)
        @time.addEventListener("contextmenu", @on_rightclick)
        settings.connectDisplayDateChanged(=>
            @update()
            if systemTray?.isShowing
                systemTray.updateTrayIcon()
        )
        settings.connectDisplayWeekChanged(=>
            @update()
            if systemTray?.isShowing
                systemTray.updateTrayIcon()
        )

    hide:->

    show:->

    getTimeFormat:(displayDate, displayWeek, use24hour)->
        # those %* is from strftime which is a C function.
        # %b -- abbreviated month name
        # %d -- day of month
        # %H -- 2 digits 24 hour, [00,23]
        # %I -- 2 digits 12 hour, [01, 12]
        # %M -- 2 digits minute, [00, 59]
        # %p -- AM/PM (upper case), %P is lower case.
        # %a -- abbreviated weekday
        if displayDate and displayWeek and use24hour
            return _("%b %d %H:%M %a")
        else if displayDate and displayWeek and !use24hour
            return _("%b %d %I:%M %p %a")
        else if displayDate and !displayWeek and use24hour
            return _("%b %d %H:%M")
        else if displayDate and !displayWeek and !use24hour
            return _("%b %d %I:%M %p")
        else if !displayDate and displayWeek and use24hour
            return _("%H:%M %a")
        else if !displayDate and displayWeek and !use24hour
            return _("%I:%M %p %a")
        else if !displayDate and !displayWeek and use24hour
            return _("%H:%M")
        else if !displayDate and !displayWeek and !use24hour
            return _("%I:%M %p")

    update:=>
        timeFormat = @getTimeFormat(
                settings.displayDate(),
                settings.displayWeek(),
                @use24hour
        )
        @timeContent.textContent = DCore.Dock.get_time(timeFormat)

    listenMouseOver:(fn)->
        @time.addEventListener("mouseover", fn)

    listenMouseOut:(fn)->
        @time.addEventListener("mouseout", fn)

    listenMouseUp:(fn)->
        @time.addEventListener("click", fn)

    on_rightclick:(e)=>
        DCore.Dock.set_is_hovered(false)
        if debugRegion
            console.warn("[time.on_rightclick] update_dock_region")
        update_dock_region($("#container").clientWidth)
        e.preventDefault()
        e.stopPropagation()
        Preview_close_now()

        element = @time.parentNode
        xy = get_page_xy(element)
        deltaX = e.clientX - xy.x
        deltaY = e.clientY - xy.y
        new Menu(
            DEEPIN_MENU_TYPE.NORMAL,
            new CheckBoxMenuItem(1, _("Display date"), settings.displayDate()),
            new CheckBoxMenuItem(2, _("Display week"), settings.displayWeek()),
            new MenuItem(3, _("_Time settings"))
        ).addListener(@on_itemselected).showMenu(
            e.screenX - deltaX + element.clientWidth / 2,
            e.screenY - deltaY,
            DEEPIN_MENU_CORNER_DIRECTION.DOWN
        )

    on_itemselected:(id)=>
        id = +id
        switch id
            when 1
                settings.setDisplayDate(!settings.displayDate())
            when 2
                settings.setDisplayWeek(!settings.displayWeek())
            when 3
                Clock.openDateAndTimeSettingModle()
