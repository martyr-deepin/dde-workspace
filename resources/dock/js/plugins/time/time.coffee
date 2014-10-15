class Time extends SystemItem
    @weekday: [_("Sun"), _("Mon"), _("Tue"), _("Wed"), _("Thu"), _("Fri"), _("Sat")]
    constructor:(@id, icon, @title)->
        super(@id, icon, @title)
        @time = create_element('div', 'DigitClockTime', @imgWrap)

        for name in ['hourHeight', 'hourLow', 'minHeight', 'minLow']
            @loadBit(name)

        timeWrap = create_element(tag:'div', id:'timeWrap')
        @timeContent = create_element(tag:'div', id:"timeContent", timeWrap)
        @element.insertBefore(timeWrap, @imgWrap)

        timeWrap.addEventListener("mouseover", @on_mouseover)
        timeWrap.addEventListener("mouseout", @on_mouseout)
        timeWrap.addEventListener("click", @on_mouseup)

        @updateTimeHandler = null
        @displayModeChangedHandler(settings.displayMode())
        settings.connectDisplayModeChanged("time", @displayModeChangedHandler)
        @updateTime()
        @update_id = setInterval(@updateTime, 1000)
        @type = DIGIT_CLOCK['type']
        @indicatorWrap.style.display = 'none'

    loadBit:(name)->
        this[name] = create_element(tag:'div', class:'timeNumber', @time)
        @loadNumber(this[name])
        this["#{name}Number"] = this[name].firstElementChild

    loadNumber:(p)->
        for i in [0..9]
            create_img(src:"js/plugins/time/img/#{i}.png", style:"display:none", p)

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

    on_mouseover:=>
        super
        @hide_open_indicator()
        # @set_tooltip((new Date()).toLocaleDateString())

    on_mouseout:=>
        super
        @hide_open_indicator()

    on_mouseup:(e)=>
        super
        if e.button != 0
            return
        try
            sysSettings = get_dbus('session', "com.deepin.dde.ControlCenter", "ShowModule")
        catch e
            console.log e
            sysSettings = null
        sysSettings?.ShowModule("date_time") if sysSettings

    displayModeChangedHandler:(mode)=>
        switch settings.displayMode()
            when DisplayMode.Efficient, DisplayMode.Classic
                @updateTimeHandler = @updateTimeForClassicMode
            when DisplayMode.Fashion
                @updateTimeHandler = @updateTimeForModernMode

        @updateTimeHandler()

    updateTime: =>
        @updateTimeHandler()

    updateTimeForClassicMode: =>
        d = new Date()
        @timeContent.textContent = ""

        # # TODO: week
        # if true
        #     @timeContent.textContent += "#{Time.weekday[d.getDay()]} "
        #
        # @timeContent.textContent += "#{d.toLocaleDateString()}"

        hour = @hour(24, true)
        @timeContent.textContent += " #{hour}"

        min = @min()
        @timeContent.textContent += ":#{min}"

    updateTimeForModernMode:=>
        hour = @hour(24, true)
        @hourHeightNumber.style.display = 'none'
        @hourHeightNumber = @hourHeight.children[parseInt(hour[0])]
        @hourHeightNumber.style.display = ''

        @hourLowNumber.style.display = 'none'
        @hourLowNumber = @hourLow.children[parseInt(hour[1])]
        @hourLowNumber.style.display = ''
        @hourLowNumber.style.marginLeft = '1px'
        @hourLowNumber.style.marginRight = '2px'

        min = @min()
        @minHeightNumber.style.display = 'none'
        @minHeightNumber = @minHeight.children[parseInt(min[0])]
        @minHeightNumber.style.display = ''
        @minHeightNumber.style.marginLeft = '2px'
        @minHeightNumber.style.marginRight = '1px'

        @minLowNumber.style.display = 'none'
        @minLowNumber = @minLow.children[parseInt(min[1])]
        @minLowNumber.style.display = ''

    force2bit: (n)->
        if n < 10 then "0#{n}" else "#{n}"

    hour: (max_hour=24, twobit=false)->
        hour = new Date().getHours()
        switch max_hour
            when 12
                if twobit then @force2bit(hour % 12) else "#{hour % 12}"
            when 24
                if twobit then @force2bit(hour) else "#{hour}"

    min: (twobit=true) ->
        min = new Date().getMinutes()
        if twobit then @force2bit(min) else "#{min}"

    year:->
        new Date().getFullYear()

    month:->
        new Date().getMonth() + 1

    weekday:->
        new Date().getDay()

    date:->
        new Date().getDate()
