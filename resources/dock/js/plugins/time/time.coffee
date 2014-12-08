class Time extends SystemItem
    constructor:(@id, icon, @title)->
        super(@id, icon, @title)
        @img.src = icon
        @imgWrap.style.position = 'relative'

        try
            @setting = DCore.DBus.session_object(
                "com.deepin.daemon.DateAndTime",
                "/com/deepin/daemon/DateAndTime",
                "com.deepin.daemon.DateAndTime"
            )
        catch e
            console.error(e)
            DCore.Dock.quit()

        @digitClock = new DigitClock(@setting, @imgWrap)
        @digitClock.hide()

        @analogClock = new AnalogClock(@setting, @imgWrap)
        @analogClock.hide()

        @trayClock = new TrayClock(@setting, @imgWrap)
        @trayClock.listenMouseOver(@on_mouseover)
        @trayClock.listenMouseOut(@on_mouseout)
        @trayClock.listenMouseUp(@on_mouseup)

        @clock = null

        @changeClock(settings.clockType(), settings.displayMode())
        settings.connectDisplayModeChanged("time", @displayModeChangedHandler)
        settings.connectClockTypeChanged(@clockTypeChangedHandler)

        @updateTime()
        setInterval(@updateTime, 1000)
        @indicatorWrap.style.display = 'none'

    isNormal:->
        # TODO
        false

    isNormalApplet: ->
        # TODO
        false

    isRuntimeApplet: ->
        true

    on_rightclick:(e)->
        DCore.Dock.set_is_hovered(false)
        if debugRegion
            console.warn("[time.on_rightclick] update_dock_region")
        update_dock_region($("#container").clientWidth)
        e.preventDefault()
        e.stopPropagation()
        Preview_close_now()

        xy = get_page_xy(@element)
        new Menu(
            DEEPIN_MENU_TYPE.NORMAL,
            new MenuItem(1, _("Switch display mode")),
            new MenuItem(2, _("_Time settings"))
        ).addListener(@on_itemselected).showMenu(
            xy.x + @element.clientWidth / 2,
            xy.y,
            DEEPIN_MENU_CORNER_DIRECTION.DOWN
        )


    on_itemselected:(id)=>
        id = +id
        switch id
            when 1
                switch @clock.type
                    when Clock.Type.Digit
                        settings.setClockType(Clock.Type.Analog)
                    when Clock.Type.Analog
                        settings.setClockType(Clock.Type.Digit)
            when 2
                Clock.openDateAndTimeSettingModle()

    on_mouseover:=>
        super
        @hide_open_indicator()

    on_mouseout:=>
        super
        @hide_open_indicator()

    on_mouseup:(e)=>
        super
        if e.button != 0
            return
        @openDateAndTimeSettingModle()

    displayModeChangedHandler:(mode)=>
        @changeClock(settings.clockType(), mode)

    clockTypeChangedHandler:(type)=>
        @changeClock(type, settings.displayMode())

    changeClock:(type, mode)=>
        switch mode
            when DisplayMode.Efficient, DisplayMode.Classic
                @clock?.hide()
                @clock = @trayClock
                @clock.show()
            when DisplayMode.Fashion
                @clock?.hide()
                switch type
                    when Clock.Type.Digit
                        @clock = @digitClock
                    when Clock.Type.Analog
                        @clock = @analogClock
                @clock.show()

        @clock.setUse24Hour?(@setting.Use24HourDisplay)
        @updateTime()

    updateTime: =>
        @clock.update()

    setUse24Hour:(use)->
        @clock.setUse24Hour?(use)
